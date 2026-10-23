import 'dart:convert';

/// Gázmérésnél választható vegyület: név és kémiai képlet.
class GasSpecies {
  const GasSpecies(this.name, this.formula, [this.molarMass]);

  final String name;
  final String formula;

  /// Moláris tömeg (g/mol). Null, ha nincs egyetlen értéke (VOC, NOx).
  final double? molarMass;
}

/// Az előre megadott vegyületek. Az "Egyéb" menüponttal ezen kívül bármely
/// gáz felvehető, saját névvel és képlettel.
const gasSpecies = <GasSpecies>[
  GasSpecies('Ammónia', 'NH₃', 17.031),
  GasSpecies('Benzol', 'C₆H₆', 78.114),
  GasSpecies('Foszfin', 'PH₃', 33.998),
  GasSpecies('Foszgén', 'COCl₂', 98.916),
  GasSpecies('Hidrogén', 'H₂', 2.016),
  GasSpecies('Hidrogén-cianid', 'HCN', 27.026),
  GasSpecies('Illékony szerves vegyületek', 'VOC'),
  GasSpecies('Kén-dioxid', 'SO₂', 64.066),
  GasSpecies('Kén-hexafluorid', 'SF₆', 146.06),
  GasSpecies('Kén-hidrogén', 'H₂S', 34.081),
  GasSpecies('Klór', 'Cl₂', 70.906),
  GasSpecies('Metán', 'CH₄', 16.043),
  GasSpecies('Metanol', 'CH₃OH', 32.042),
  GasSpecies('Metil-szalicilát', 'C₈H₈O₃', 152.149),
  GasSpecies('Nitrogén-monoxid', 'NO', 30.006),
  GasSpecies('Nitrogén-dioxid', 'NO₂', 46.006),
  GasSpecies('Nitrogén-oxidok', 'NOₓ'),
  GasSpecies('Oxigén', 'O₂', 31.998),
  GasSpecies('Ózon', 'O₃', 47.998),
  GasSpecies('Propán', 'C₃H₈', 44.097),
  GasSpecies('Szén-dioxid', 'CO₂', 44.009),
  GasSpecies('Szén-monoxid', 'CO', 28.01),
  GasSpecies('Toluol', 'C₇H₈', 92.141),
  GasSpecies('Tributil-foszfát', 'C₁₂H₂₇O₄P', 266.32),
];

/// Az "Egyéb" vegyület neve a választólistában.
const otherGasName = 'Egyéb';

/// A katalógusbeli vegyület moláris tömege (g/mol), ha van.
double? molarMassOf(String name) {
  for (final s in gasSpecies) {
    if (s.name == name) return s.molarMass;
  }
  return null;
}

/// A katalógusbeli vegyület képlete (ismeretlen névnél üres).
String gasFormulaOf(String name) {
  for (final s in gasSpecies) {
    if (s.name == name) return s.formula;
  }
  return '';
}

/// A koncentráció mértékegysége.
enum GasUnit {
  ppm('ppm'),
  ppb('ppb'),
  ugPerM3('µg/m³'),
  mgPerM3('mg/m³'),
  volPercent('vol%'),
  lelPercent('%LEL');

  const GasUnit(this.symbol);

  final String symbol;

  static GasUnit? fromSymbol(String? value) {
    for (final u in GasUnit.values) {
      if (u.symbol == value) return u;
    }
    return null;
  }
}

/// Egy mért gáz egy mérési ponton.
class GasReading {
  final String name;
  final String formula;
  final double concentration;
  final GasUnit unit;

  const GasReading({
    required this.name,
    required this.formula,
    required this.concentration,
    required this.unit,
  });

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'formula': formula,
      'concentration': concentration,
      'unit': unit.symbol,
    };
  }

  factory GasReading.fromJson(Map<String, Object?> m) {
    return GasReading(
      name: m['name'] as String,
      formula: (m['formula'] as String?) ?? '',
      concentration: (m['concentration'] as num).toDouble(),
      unit: GasUnit.fromSymbol(m['unit'] as String?) ?? GasUnit.ppm,
    );
  }

  static List<GasReading> listFromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list) GasReading.fromJson(e as Map<String, Object?>),
    ];
  }

  static String listToJsonString(List<GasReading> gases) =>
      jsonEncode([for (final g in gases) g.toJson()]);
}
