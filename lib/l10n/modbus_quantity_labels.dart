import '../models/measurement_type.dart';
import '../models/modbus_reading.dart';
import 'app_localizations.dart';
import 'domain_labels.dart';

/// Meteorológiai mennyiség neve (mértékegység nélkül; az egység külön áll).
String modbusMeteoLabel(AppLocalizations loc, String key) {
  final base = switch (key) {
    'air_temperature_c' => loc.rrMetTemp,
    'relative_humidity_pct' => loc.rrMetHumidity,
    'pressure_hpa' => loc.rrMetPressure,
    'wind_speed_ms' => loc.rrMetWind,
    'wind_direction_deg' => loc.rrMetWindDir,
    'gust_ms' => loc.rrMetGust,
    'precipitation_mm_h' => loc.rrMetPrecipIntensity,
    'solar_wm2' => loc.rrMetSolar,
    'cloud_okta' => loc.rrMetCloud,
    'visibility_m' => loc.rrMetVisibility,
    'soil_moisture_pct' => loc.rrMetSoil,
    _ => loc.rrMetAerosol,
  };
  return base.replaceFirst(RegExp(r'\s*\([^)]*\)$'), '');
}

/// Csatorna megjelenítendő neve: típus, és meteorológiánál vagy gázmérésnél
/// a mennyiség is.
String modbusChannelLabel(
  AppLocalizations loc,
  ModbusChannel channel,
  String typeLabel,
) {
  final q = channel.quantity;
  if (q == null) return typeLabel;
  return switch (channel.type) {
    MeasurementType.meteorology => '$typeLabel: ${modbusMeteoLabel(loc, q)}',
    MeasurementType.gasMeasurement => '$typeLabel: ${localizedGasName(loc, q)}',
    _ => typeLabel,
  };
}
