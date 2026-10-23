import 'dart:convert';

/// A megfigyelt csapadék típusa.
enum PrecipitationState {
  none('none', 'Nincs csapadék'),
  drizzle('drizzle', 'Szitálás'),
  rain('rain', 'Eső'),
  snow('snow', 'Hó'),
  sleet('sleet', 'Ónos eső'),
  hail('hail', 'Jégeső');

  const PrecipitationState(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static PrecipitationState? fromDbValue(String? value) {
    for (final s in PrecipitationState.values) {
      if (s.dbValue == value) return s;
    }
    return null;
  }
}

/// Meteorológiai megfigyelés egy mérési ponthoz. Minden mező opcionális;
/// a mértékegység a mező nevében és a megjegyzésben szerepel.
class Meteorology {
  final double? airTemperatureC; // °C
  final double? relativeHumidityPct; // %
  final double? pressureHpa; // hPa
  final double? windSpeedMs; // m/s
  final double? windDirectionDeg; // ° (0–360)
  final PrecipitationState? precipitation;
  final double? gustMs; // széllökés, m/s
  final double? precipitationMmH; // csapadékintenzitás, mm/h
  final double? solarWm2; // napsugárzás, W/m²
  final double? cloudOkta; // felhőzet, okta (0–8)
  final double? visibilityM; // látástávolság, m
  final double? soilMoisturePct; // talajnedvesség, %
  final double? aerosolUgM3; // aeroszolkoncentráció, µg/m³
  final String? other; // szabad szöveges egyéb megfigyelés

  const Meteorology({
    this.airTemperatureC,
    this.relativeHumidityPct,
    this.pressureHpa,
    this.windSpeedMs,
    this.windDirectionDeg,
    this.precipitation,
    this.gustMs,
    this.precipitationMmH,
    this.solarWm2,
    this.cloudOkta,
    this.visibilityM,
    this.soilMoisturePct,
    this.aerosolUgM3,
    this.other,
  });

  bool get isEmpty =>
      airTemperatureC == null &&
      relativeHumidityPct == null &&
      pressureHpa == null &&
      windSpeedMs == null &&
      windDirectionDeg == null &&
      precipitation == null &&
      gustMs == null &&
      precipitationMmH == null &&
      solarWm2 == null &&
      cloudOkta == null &&
      visibilityM == null &&
      soilMoisturePct == null &&
      aerosolUgM3 == null &&
      other == null;

  Map<String, Object?> toJson() {
    return {
      'air_temperature_c': airTemperatureC,
      'relative_humidity_pct': relativeHumidityPct,
      'pressure_hpa': pressureHpa,
      'wind_speed_ms': windSpeedMs,
      'wind_direction_deg': windDirectionDeg,
      'precipitation': precipitation?.dbValue,
      'gust_ms': gustMs,
      'precipitation_mm_h': precipitationMmH,
      'solar_wm2': solarWm2,
      'cloud_okta': cloudOkta,
      'visibility_m': visibilityM,
      'soil_moisture_pct': soilMoisturePct,
      'aerosol_ug_m3': aerosolUgM3,
      'other': other,
    };
  }

  factory Meteorology.fromJson(Map<String, Object?> m) {
    double? d(String key) => (m[key] as num?)?.toDouble();
    return Meteorology(
      airTemperatureC: d('air_temperature_c'),
      relativeHumidityPct: d('relative_humidity_pct'),
      pressureHpa: d('pressure_hpa'),
      windSpeedMs: d('wind_speed_ms'),
      windDirectionDeg: d('wind_direction_deg'),
      precipitation:
          PrecipitationState.fromDbValue(m['precipitation'] as String?),
      gustMs: d('gust_ms'),
      precipitationMmH: d('precipitation_mm_h'),
      solarWm2: d('solar_wm2'),
      cloudOkta: d('cloud_okta'),
      visibilityM: d('visibility_m'),
      soilMoisturePct: d('soil_moisture_pct'),
      aerosolUgM3: d('aerosol_ug_m3'),
      other: m['other'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  /// Üres (vagy hiányzó) JSON esetén `null`, egyébként a megfigyelés.
  static Meteorology? fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final m = Meteorology.fromJson(decoded);
    return m.isEmpty ? null : m;
  }
}
