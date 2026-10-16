import 'dart:math' as math;

/// Árnyékoló anyagok a forrás-aktivitás becsléséhez.
enum ShieldingMaterial {
  lead,
  steel,
  concrete,
  tungsten,
  aluminium,
  water;

  String get dbValue => name;

  static ShieldingMaterial? fromDb(Object? v) {
    if (v is! String) return null;
    for (final m in values) {
      if (m.name == v) return m;
    }
    return null;
  }
}

/// Tájékoztató félértékréteg-vastagságok (HVL, cm): ennyi anyag felezi a
/// gamma-dózisteljesítményt. Sugárvédelmi kézikönyvekben szokásos, kerekített
/// tájékozódó értékek (a szórt sugárzást részben tartalmazó, "gyakorlati"
/// értékek) — NEM hiteles adatbázisból származnak. Hatósági jegyzőkönyvhöz
/// ellenőrizd őket (pl. NIST XCOM, NCRP 151, IAEA).
const Map<String, Map<ShieldingMaterial, double>> kHalfValueLayersCm = {
  'Co-60': {
    ShieldingMaterial.lead: 1.2,
    ShieldingMaterial.steel: 2.1,
    ShieldingMaterial.concrete: 6.2,
    ShieldingMaterial.tungsten: 0.8,
    ShieldingMaterial.aluminium: 6.6,
    ShieldingMaterial.water: 15.0,
  },
  'Cs-137': {
    ShieldingMaterial.lead: 0.65,
    ShieldingMaterial.steel: 1.6,
    ShieldingMaterial.concrete: 4.8,
    ShieldingMaterial.tungsten: 0.45,
    ShieldingMaterial.aluminium: 3.7,
    ShieldingMaterial.water: 8.4,
  },
  'Ir-192': {
    ShieldingMaterial.lead: 0.5,
    ShieldingMaterial.steel: 1.3,
    ShieldingMaterial.concrete: 4.3,
    ShieldingMaterial.tungsten: 0.33,
    ShieldingMaterial.aluminium: 3.0,
    ShieldingMaterial.water: 6.3,
  },
  'Ra-226': {
    ShieldingMaterial.lead: 1.6,
    ShieldingMaterial.steel: 2.6,
    ShieldingMaterial.concrete: 6.9,
    ShieldingMaterial.tungsten: 1.0,
    ShieldingMaterial.aluminium: 6.0,
    ShieldingMaterial.water: 17.0,
  },
  'I-131': {
    ShieldingMaterial.lead: 0.3,
    ShieldingMaterial.steel: 1.2,
    ShieldingMaterial.concrete: 3.8,
    ShieldingMaterial.tungsten: 0.25,
    ShieldingMaterial.aluminium: 2.9,
    ShieldingMaterial.water: 6.0,
  },
  'Na-22': {
    ShieldingMaterial.lead: 0.9,
    ShieldingMaterial.steel: 1.9,
    ShieldingMaterial.concrete: 5.5,
    ShieldingMaterial.tungsten: 0.55,
    ShieldingMaterial.aluminium: 4.5,
    ShieldingMaterial.water: 10.0,
  },
  'Am-241': {
    ShieldingMaterial.lead: 0.012,
    ShieldingMaterial.steel: 0.073,
    ShieldingMaterial.concrete: 1.0,
    ShieldingMaterial.tungsten: 0.008,
    ShieldingMaterial.aluminium: 0.86,
    ShieldingMaterial.water: 3.4,
  },
};

double? halfValueLayerCm(String nuclide, ShieldingMaterial material) =>
    kHalfValueLayersCm[nuclide]?[material];

/// Egy árnyékoló réteg: anyag + vastagság (cm).
class ShieldingLayer {
  final ShieldingMaterial material;
  final double thicknessCm;

  const ShieldingLayer(this.material, this.thicknessCm);

  Map<String, dynamic> toJson() =>
      {'material': material.dbValue, 'thickness_cm': thicknessCm};

  static ShieldingLayer? fromJson(Object? v) {
    if (v is! Map) return null;
    final m = ShieldingMaterial.fromDb(v['material']);
    final t = (v['thickness_cm'] as num?)?.toDouble();
    if (m == null || t == null || t <= 0) return null;
    return ShieldingLayer(m, t);
  }

  static List<ShieldingLayer> listFromJson(Object? v) =>
      v is List
          ? v.map(fromJson).whereType<ShieldingLayer>().toList()
          : const <ShieldingLayer>[];
}

/// Az árnyékolás áteresztése (0..1): 0.5^(vastagság / HVL).
double shieldingTransmission({
  required double hvlCm,
  required double thicknessCm,
}) =>
    math.pow(0.5, thicknessCm / hvlCm).toDouble();

/// Több réteg együttes áteresztése (a rétegek áteresztéseinek szorzata).
/// Null, ha valamelyik réteghez nincs HVL-adat a nuklidra.
double? layersTransmission(String nuclide, List<ShieldingLayer> layers) {
  var t = 1.0;
  for (final l in layers) {
    final hvl = halfValueLayerCm(nuclide, l.material);
    if (hvl == null) return null;
    t *= shieldingTransmission(hvlCm: hvl, thicknessCm: l.thicknessCm);
  }
  return t;
}
