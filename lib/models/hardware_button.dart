/// A Bluetooth-os (média) gombok. Androidon a telefon hangerő gombjai és a
/// Bluetooth-távirányító gombjai ilyenek.
enum HardwareButton {
  volumeUp,
  volumeDown,
  play,
  next,
  previous;

  /// Alapértelmezett parancs: a lejátszó gombok a mérést szolgálják ki, a
  /// hangerő gombok rendszer-viselkedésűek maradnak.
  ButtonCommand get defaultCommand => switch (this) {
        HardwareButton.play => ButtonCommand.savePoint,
        HardwareButton.next => ButtonCommand.newPoint,
        HardwareButton.previous => ButtonCommand.takePhoto,
        HardwareButton.volumeUp || HardwareButton.volumeDown =>
          ButtonCommand.nothing,
      };
}

/// Egy gombhoz rendelhető parancs. A tárolt szöveg külön van tartva, hogy a
/// Dart-oldali nevek átírása ne törje el a mentett beállítást.
enum ButtonCommand {
  nothing('nothing'),
  newPoint('new_point'),
  takePhoto('take_photo'),
  modbusQuery('modbus_query'),
  savePoint('save_point'),
  saveAndNewPoint('save_and_new_point'),
  discardPoint('discard_point'),
  nextMeasurementType('next_measurement_type'),
  previousMeasurementType('previous_measurement_type'),
  modbusAveraging('modbus_averaging'),
  toggleSourcePosition('toggle_source_position'),
  toggleAutoLog('toggle_auto_log');

  const ButtonCommand(this.storageValue);
  final String storageValue;

  static ButtonCommand fromStorage(String value) =>
      ButtonCommand.values.firstWhere(
        (c) => c.storageValue == value,
        orElse: () => ButtonCommand.nothing,
      );
}
