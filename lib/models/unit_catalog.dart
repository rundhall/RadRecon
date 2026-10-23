import 'activity_unit.dart';
import 'dose_rate_unit.dart';

/// A mértékegység-váltóban szereplő mennyiségek.
enum UnitCategory {
  dose,
  doseRate,
  activity,
  activityConcentration,
  surfaceContamination,
  countRate,
  length,
  area,
  volume,
  mass,
  temperature,
  pressure,
  speed,
  time,
  irradiance,
  rainRate,
  massConcentration,
  gasConcentration,
}

/// Egy mértékegység. Az alapegységhez képest: `alap = érték * factor + offset`.
/// Az `offset` csak a hőmérsékletnél kell (°F, K).
class UnitDef {
  const UnitDef(
    this.symbol,
    this.factor, {
    this.offset = 0,
    this.needsMolarMass = false,
  });

  final String symbol;
  final double factor;
  final double offset;

  /// Gáz tömeg-alapú egysége (mg/m³, µg/m³). Térfogat-alapú egységgé
  /// (ppm, ppb, vol%) csak a gáz moláris tömegével váltható.
  final bool needsMolarMass;
}

/// Ideális gáz moláris térfogata 25 °C-on, 1 atm-en (liter/mol).
/// Ezzel: 1 ppm = (M / 24,465) mg/m³, ahol M a moláris tömeg (g/mol).
const double kMolarVolumeLitresPerMole = 24.465;

/// Az app mértékegységei mennyiségenként. Az alapegységek: dózis µSv,
/// dózisteljesítmény µSv/h, aktivitás MBq, aktivitáskoncentráció Bq/m³,
/// felületi szennyezettség Bq/cm², beütés cps, hossz m, terület m²,
/// térfogat l, tömeg g, hőmérséklet °C, nyomás hPa, sebesség m/s,
/// idő s, sugárzási teljesítmény W/m², csapadék mm/h, aeroszol µg/m³,
/// gáz ppm.
class UnitCatalog {
  UnitCatalog._();

  static List<UnitDef> unitsOf(UnitCategory c) => switch (c) {
        UnitCategory.dose => const [
            UnitDef('nSv', 0.001),
            UnitDef('µSv', 1),
            UnitDef('mSv', 1000),
            UnitDef('Sv', 1000000),
            UnitDef('µrem', 0.01),
            UnitDef('mrem', 10),
            UnitDef('rem', 10000),
          ],
        UnitCategory.doseRate => [
            for (final u in DoseRateUnit.values)
              UnitDef(u.symbol, u.microSvPerHourFactor),
          ],
        UnitCategory.activity => [
            for (final u in ActivityUnit.values) UnitDef(u.symbol, u.mbqFactor),
          ],
        UnitCategory.activityConcentration => const [
            UnitDef('Bq/m³', 1),
            UnitDef('kBq/m³', 1000),
            UnitDef('MBq/m³', 1000000),
            UnitDef('Bq/l', 1000),
            UnitDef('kBq/l', 1000000),
            UnitDef('pCi/l', 37),
          ],
        UnitCategory.surfaceContamination => const [
            UnitDef('Bq/cm²', 1),
            UnitDef('Bq/100cm²', 0.01),
            UnitDef('kBq/m²', 0.1),
            UnitDef('Bq/m²', 0.0001),
            UnitDef('MBq/m²', 100),
            UnitDef('dpm/cm²', 1 / 60),
            UnitDef('dpm/100cm²', 1 / 6000),
          ],
        UnitCategory.countRate => const [
            UnitDef('cps', 1),
            UnitDef('cpm', 1 / 60),
          ],
        UnitCategory.length => const [
            UnitDef('mm', 0.001),
            UnitDef('cm', 0.01),
            UnitDef('m', 1),
            UnitDef('km', 1000),
            UnitDef('in', 0.0254),
            UnitDef('ft', 0.3048),
            UnitDef('yd', 0.9144),
            UnitDef('mi', 1609.344),
          ],
        UnitCategory.area => const [
            UnitDef('mm²', 0.000001),
            UnitDef('cm²', 0.0001),
            UnitDef('m²', 1),
            UnitDef('ha', 10000),
            UnitDef('km²', 1000000),
            UnitDef('in²', 0.00064516),
            UnitDef('ft²', 0.09290304),
          ],
        UnitCategory.volume => const [
            UnitDef('ml', 0.001),
            UnitDef('cm³', 0.001),
            UnitDef('dl', 0.1),
            UnitDef('l', 1),
            UnitDef('m³', 1000),
            UnitDef('US gal', 3.785411784),
          ],
        UnitCategory.mass => const [
            UnitDef('µg', 0.000001),
            UnitDef('mg', 0.001),
            UnitDef('g', 1),
            UnitDef('kg', 1000),
            UnitDef('t', 1000000),
            UnitDef('oz', 28.349523125),
            UnitDef('lb', 453.59237),
          ],
        UnitCategory.temperature => const [
            UnitDef('°C', 1),
            UnitDef('°F', 5 / 9, offset: -160 / 9),
            UnitDef('K', 1, offset: -273.15),
          ],
        UnitCategory.pressure => const [
            UnitDef('Pa', 0.01),
            UnitDef('hPa', 1),
            UnitDef('kPa', 10),
            UnitDef('mbar', 1),
            UnitDef('bar', 1000),
            UnitDef('atm', 1013.25),
            UnitDef('mmHg', 1.33322387415),
            UnitDef('inHg', 33.86388640341),
            UnitDef('psi', 68.94757293168),
          ],
        UnitCategory.speed => const [
            UnitDef('m/s', 1),
            UnitDef('km/h', 1 / 3.6),
            UnitDef('mph', 0.44704),
            UnitDef('kn', 0.514444),
            UnitDef('ft/s', 0.3048),
          ],
        UnitCategory.time => const [
            UnitDef('s', 1),
            UnitDef('min', 60),
            UnitDef('h', 3600),
            UnitDef('d', 86400),
            UnitDef('év', 31557600),
          ],
        UnitCategory.irradiance => const [
            UnitDef('W/m²', 1),
            UnitDef('kW/m²', 1000),
            UnitDef('mW/cm²', 10),
          ],
        UnitCategory.rainRate => const [
            UnitDef('mm/h', 1),
            UnitDef('mm/min', 60),
            UnitDef('in/h', 25.4),
          ],
        UnitCategory.massConcentration => const [
            UnitDef('ng/m³', 0.001),
            UnitDef('µg/m³', 1),
            UnitDef('mg/m³', 1000),
          ],
        UnitCategory.gasConcentration => const [
            UnitDef('ppm', 1),
            UnitDef('ppb', 0.001),
            UnitDef('vol%', 10000),
            UnitDef('mg/m³', 1, needsMolarMass: true),
            UnitDef('µg/m³', 0.001, needsMolarMass: true),
          ],
      };

  /// Átváltás egy mennyiségen belül. `null`, ha nem végezhető el (gáznál
  /// a tömeg- és térfogat-alapú egység között hiányzik a moláris tömeg).
  static double? convert({
    required UnitDef from,
    required UnitDef to,
    required double value,
    double? molarMass,
  }) {
    if (from.needsMolarMass == to.needsMolarMass) {
      final base = value * from.factor + from.offset;
      return (base - to.offset) / to.factor;
    }
    if (molarMass == null || molarMass <= 0) return null;
    // ppm / (mg/m³) = Vm / M
    final ratio = kMolarVolumeLitresPerMole / molarMass;
    final ppm = value * from.factor * (from.needsMolarMass ? ratio : 1);
    return ppm / (to.factor * (to.needsMolarMass ? ratio : 1));
  }
}
