import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// Indításkor egyszer hívandó.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_onCall);
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
