import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/hardware_button.dart';
import 'settings_service.dart';

/// A képernyőn lévő kezelő. A legfelül lévő képernyő kapja meg a parancsot;
/// ha az nem kezeli (false), a mögötte lévő próbálja.
typedef ButtonCommandHandler = bool Function(ButtonCommand command);

/// A Bluetooth-gomb és a képernyő-ébrentartás beállításai. A mentés a
/// SettingsService-ben van, az értékek a ValueNotifier-ekben élnek.
class HardwareButtonController {
  HardwareButtonController._();

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> keepScreenOn = ValueNotifier<bool>(false);
  static final ValueNotifier<List<LearnedKey>> learnedKeys =
      ValueNotifier<List<LearnedKey>>([]);

  static final Map<HardwareButton, ValueNotifier<ButtonCommand>> _commands = {
    for (final b in HardwareButton.values)
      b: ValueNotifier<ButtonCommand>(b.defaultCommand),
  };

  static ValueNotifier<ButtonCommand> commandOf(HardwareButton button) =>
      _commands[button]!;

  static ButtonCommand commandFor(HardwareButton button) =>
      _commands[button]!.value;

  static Future<void> load() async {
    final settings = SettingsService();
    enabled.value = await settings.getBluetoothButtonsEnabled();
    keepScreenOn.value = await settings.getKeepScreenOn();
    learnedKeys.value = await settings.getLearnedKeys();
    for (final b in HardwareButton.values) {
      _commands[b]!.value = await settings.getButtonCommand(b);
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await SettingsService().setBluetoothButtonsEnabled(value);
    await HardwareButtons.publishHandled();
  }

  static Future<void> setKeepScreenOn(bool value) async {
    keepScreenOn.value = value;
    await SettingsService().setKeepScreenOn(value);
    await applyScreenWake();
  }

  static Future<void> setCommand(
    HardwareButton button,
    ButtonCommand command,
  ) async {
    _commands[button]!.value = command;
    await SettingsService().setButtonCommand(button, command);
    await HardwareButtons.publishHandled();
  }

  static Future<void> addLearnedKey(LearnedKey key) async {
    if (learnedKeys.value.any((k) => k.keyId == key.keyId)) return;
    learnedKeys.value = [...learnedKeys.value, key];
    await SettingsService().setLearnedKeys(learnedKeys.value);
  }

  static Future<void> removeLearnedKey(int keyId) async {
    learnedKeys.value = [
      for (final k in learnedKeys.value)
        if (k.keyId != keyId) k,
    ];
    await SettingsService().setLearnedKeys(learnedKeys.value);
  }

  static Future<void> setLearnedKeyCommand(
    int keyId,
    ButtonCommand command,
  ) async {
    learnedKeys.value = [
      for (final k in learnedKeys.value)
        if (k.keyId == keyId) k.withCommand(command) else k,
    ];
    await SettingsService().setLearnedKeys(learnedKeys.value);
  }

  /// A képernyő ébrentartása a beállítás szerint. Az automatikus rögzítés
  /// leállításakor is ezt hívjuk, hogy az ne kapcsolja ki a folyamatos módot.
  static Future<void> applyScreenWake() async {
    try {
      if (keepScreenOn.value) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // nincs képernyő-zárolás támogatás
    }
  }
}

/// A natív oldal (MainActivity) gombnyomásait fogadja, és a gombhoz rendelt
/// parancsot a legfelül lévő kezelőnek adja át.
class HardwareButtons {
  HardwareButtons._();

  static const _channel = MethodChannel('radrecon/keys');
  static bool _initialized = false;
  static final List<ButtonCommandHandler> _handlers = [];
  static bool _keyboardHooked = false;
  static void Function(LearnedKey key)? _learnCallback;

  /// Média billentyűk: ezeket a Bluetooth-médiagomb útja kezeli, nem a
  /// billentyűzetes út, ezért nem rögzíthetők így.
  static final Set<LogicalKeyboardKey> _mediaKeys = {
    LogicalKeyboardKey.audioVolumeUp,
    LogicalKeyboardKey.audioVolumeDown,
    LogicalKeyboardKey.mediaPlayPause,
    LogicalKeyboardKey.mediaTrackNext,
    LogicalKeyboardKey.mediaTrackPrevious,
  };

  /// Indításkor egyszer hívandó.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_onCall);
    if (!_keyboardHooked) {
      _keyboardHooked = true;
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  /// A következő lenyomott billentyűt a megadott függvénynek adja, nem a
  /// parancsnak. Egyszer hívódik meg, utána a rögzítés leáll.
  static void startLearning(void Function(LearnedKey key) onLearned) {
    _learnCallback = onLearned;
  }

  static void stopLearning() => _learnCallback = null;

  static bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.synthesized) return false;
    final key = event.logicalKey;
    if (_mediaKeys.contains(key)) return false;
    final learn = _learnCallback;
    if (learn != null) {
      _learnCallback = null;
      learn(LearnedKey(
        keyId: key.keyId,
        label: key.keyLabel.isNotEmpty
            ? key.keyLabel
            : (key.debugName ?? 'Key ${key.keyId}'),
        command: ButtonCommand.nothing,
      ));
      return true;
    }
    // Szövegmezőben a billentyű a gépelést szolgálja, nem parancs.
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    if (!HardwareButtonController.enabled.value) return false;
    for (final k in HardwareButtonController.learnedKeys.value) {
      if (k.keyId == key.keyId) {
        if (k.command != ButtonCommand.nothing) dispatch(k.command);
        return true;
      }
    }
    return false;
  }

  /// A képernyő a megnyitáskor regisztrálja a kezelőjét, bezáráskor törli.
  /// Ugyanazt a függvényobjektumot kell átadni a két hívásnál.
  static void register(ButtonCommandHandler handler) => _handlers.add(handler);

  static void unregister(ButtonCommandHandler handler) =>
      _handlers.remove(handler);

  /// Átadja a natív oldalnak, mely gombokat nyelje el az app. Csak akkor
  /// nyeli el, ha a gombvezérlés be van kapcsolva és a gombhoz parancs tartozik.
  static Future<void> publishHandled() async {
    final handled = HardwareButtonController.enabled.value
        ? [
            for (final b in HardwareButton.values)
              if (HardwareButtonController.commandFor(b) !=
                  ButtonCommand.nothing)
                b.name,
          ]
        : <String>[];
    try {
      await _channel.invokeMethod<void>('setHandled', handled);
    } catch (_) {
      // nem Android: nincs natív oldal
    }
  }

  /// A parancsot a legfelül lévő kezelő kapja meg; true, ha valaki kezelte.
  static bool dispatch(ButtonCommand command) {
    for (final handler in _handlers.reversed.toList()) {
      if (handler(command)) {
        HapticFeedback.lightImpact();
        return true;
      }
    }
    return false;
  }

  static Future<dynamic> _onCall(MethodCall call) async {
    if (call.method != 'key') return;
    final name = call.arguments as String?;
    for (final b in HardwareButton.values) {
      if (b.name == name) {
        final command = HardwareButtonController.commandFor(b);
        if (command != ButtonCommand.nothing) dispatch(command);
        return;
      }
    }
  }
}
