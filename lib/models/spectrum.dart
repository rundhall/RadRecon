import 'dart:convert';

/// A spektrum fajtája. A tárolt érték (`dbValue`) stabil azonosító.
enum SpectrumKind {
  alpha('alpha'),
  beta('beta'),
  gamma('gamma'),
  neutron('neutron');

  const SpectrumKind(this.dbValue);

  final String dbValue;

  static SpectrumKind fromDbValue(String? value) => values.firstWhere(
        (k) => k.dbValue == value,
        orElse: () => SpectrumKind.gamma,
      );
}

/// Az elemzési eredmény egy azonosított nuklidja: a fájl szerinti értékekkel
/// (az egység nincs megadva a fájlban, ezért a betöltő alkalmazza a
/// Beállításokban beállított aktivitás-egységet).
typedef NuclideResult = ({String nuclide, double? value, double? uncertainty});

/// Egy beolvasott spektrum: csatornánkénti beütésszámok és a mérési idők.
class Spectrum {
  Spectrum({
    required this.counts,
    this.liveTimeSeconds,
    this.realTimeSeconds,
    this.energyCoefficients,
    this.energyUnit,
    this.detectorCategory,
    this.nuclideResults = const [],
  });

  /// Csatornánkénti beütésszám (0. csatornától).
  final List<int> counts;
  final double? liveTimeSeconds;
  final double? realTimeSeconds;

  /// Energiakalibráció: E = c0 + c1·csatorna + c2·csatorna² … Null, ha a
  /// spektrumhoz nincs kalibráció (csatornatengely).
  final List<double>? energyCoefficients;

  /// Az energia egysége a fájlban (pl. "keV"). Null, ha a fájl nem adja meg.
  final String? energyUnit;

  /// A detektor kategóriája a fájlban ("Gamma", "Neutron"), ha van.
  final String? detectorCategory;

  /// Az azonosított nuklidok az elemzési eredményből, a fájl szerinti értékekkel.
  final List<NuclideResult> nuclideResults;

  /// Azonosított nuklidok nevei (pl. Cs-137).
  List<String> get identifiedNuclides => [for (final r in nuclideResults) r.nuclide];

  int get channelCount => counts.length;

  int? _totalCache;

  /// Összes beütés (egyszer számolva).
  int get totalCounts => _totalCache ??= counts.fold<int>(0, (a, b) => a + b);

  /// A csatorna energiája kalibráció esetén, különben null.
  double? energyOfChannel(double channel) {
    final c = energyCoefficients;
    if (c == null || c.isEmpty) return null;
    var energy = 0.0;
    var power = 1.0;
    for (final coefficient in c) {
      energy += coefficient * power;
      power *= channel;
    }
    return energy;
  }

  /// Egyetlen spektrumot tartalmazó, tömörítetlen N42 XML. A kiválasztott
  /// spektrum ebben a formában kerül a mérési pontba.
  String toN42Xml() {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<RadInstrumentData>');
    final c = energyCoefficients;
    if (c != null && c.isNotEmpty) {
      final unitAttr = energyUnit == null ? '' : ' EnergyUnits="$energyUnit"';
      b.writeln(
          '  <Calibration$unitAttr><Coefficients>${c.join(' ')}</Coefficients></Calibration>');
    }
    b.writeln('  <RadMeasurement><Spectrum>');
    if (liveTimeSeconds != null) {
      b.writeln(
          '    <LiveTimeDuration>PT${liveTimeSeconds!.toStringAsFixed(3)}S</LiveTimeDuration>');
    }
    if (realTimeSeconds != null) {
      b.writeln(
          '    <RealTimeDuration>PT${realTimeSeconds!.toStringAsFixed(3)}S</RealTimeDuration>');
    }
    b.writeln('    <ChannelData Compression="None">${counts.join(' ')}</ChannelData>');
    b.writeln('  </Spectrum></RadMeasurement>');
    b.writeln('</RadInstrumentData>');
    return b.toString();
  }
}

/// Nuklid aktivitása MBq-ban (a tárolt alapegység), bizonytalansággal.
class NuclideActivity {
  const NuclideActivity({required this.nuclide, required this.mbq, this.uncertaintyMbq});

  final String nuclide;
  final double mbq;
  final double? uncertaintyMbq;

  Map<String, Object?> toJson() => {
        'nuclide': nuclide,
        'mbq': mbq,
        'uncertainty_mbq': uncertaintyMbq,
      };

  static NuclideActivity? _fromJson(Object? raw) {
    if (raw is! Map) return null;
    final nuclide = raw['nuclide'];
    final mbq = raw['mbq'];
    if (nuclide is! String || mbq is! num) return null;
    final u = raw['uncertainty_mbq'];
    return NuclideActivity(
      nuclide: nuclide,
      mbq: mbq.toDouble(),
      uncertaintyMbq: u is num ? u.toDouble() : null,
    );
  }

  static String listToJson(List<NuclideActivity> list) =>
      jsonEncode([for (final a in list) a.toJson()]);

  static List<NuclideActivity> listFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <NuclideActivity>[];
      for (final e in decoded) {
        final a = _fromJson(e);
        if (a != null) out.add(a);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}

class SpectrumFormatException implements Exception {
  const SpectrumFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'SpectrumFormatException: $reason';
}

/// N42 (ANSI N42.42) XML olvasója. Támogatott tömörítés:
/// - None (vagy hiányzik): a csatornák száma tömörítetlenül.
/// - CountedZeroes: a "0 n" pár n darab nulla csatornát jelent, minden más szám
///   egy csatorna beütésszáma. Ezt valódi fájlokon ellenőriztük: a dekódolt
///   csatornaszám egyezik a fájl SpectrumLength értékével, a beütések összege
///   pedig a GrossCounts értékkel.
/// Kalibrációt a spektrum energyCalibrationReference hivatkozása alapján
/// vesz; a csupa nulla kalibráció (No-calibration-used) csatornatengely.
class N42Parser {
  N42Parser._();

  static const _prefix = r'(?:[A-Za-z_][\w.\-]*:)?';

  /// Elem keresése: 1. csoport = névtér-előtag, 2. = attribútumok, 3. = tartalom.
  static final Map<String, RegExp> _elementCache = {};

  static RegExp _element(String name) => _elementCache.putIfAbsent(
        name,
        () => RegExp(
          r'<(' + _prefix + r')' + name + r'\b([^>]*)>([\s\S]*?)</\1' + name + r'\s*>',
        ),
      );

  /// Az összes spektrum a fájlban. Hibás blokkokat kihagyja (pl. más elemekhez
  /// tartozó Spectrum-szerű blokk), ha van olvasható.
  static List<Spectrum> parseAll(String xml) {
    final calibrations = <String, List<double>?>{};
    for (final m in _element('EnergyCalibration').allMatches(xml)) {
      final id = _attribute(m.group(2) ?? '', 'id');
      if (id != null) calibrations[id] = _coefficients(m.group(3) ?? '');
    }
    final fallbackCalibration = _coefficients(xml);
    final categories = <String, String>{};
    for (final m in _element('RadDetectorInformation').allMatches(xml)) {
      final id = _attribute(m.group(2) ?? '', 'id');
      final cat = _element('RadDetectorCategoryCode')
          .firstMatch(m.group(3) ?? '')
          ?.group(3)
          ?.trim();
      if (id != null && cat != null) categories[id] = cat;
    }
    final unit = _energyUnit(xml);
    final identified = _identifiedNuclides(xml);
    final blocks = _element('Spectrum').allMatches(xml).toList();
    if (blocks.isEmpty) {
      return [_build(xml, '', calibrations, fallbackCalibration, categories, unit, identified)];
    }
    final result = <Spectrum>[];
    SpectrumFormatException? firstError;
    for (final b in blocks) {
      try {
        result.add(_build(
          b.group(3) ?? '',
          b.group(2) ?? '',
          calibrations,
          fallbackCalibration,
          categories,
          unit,
          identified,
        ));
      } on SpectrumFormatException catch (e) {
        firstError ??= e;
      }
    }
    if (result.isEmpty) {
      throw firstError ?? const SpectrumFormatException('no spectrum');
    }
    return result;
  }

  static Spectrum parse(String xml) => parseAll(xml).first;

  static Spectrum _build(
    String body,
    String attrs,
    Map<String, List<double>?> calibrations,
    List<double>? fallbackCalibration,
    Map<String, String> categories,
    String? unit,
    List<NuclideResult> nuclides,
  ) {
    final channel = _element('ChannelData').firstMatch(body);
    if (channel == null) {
      throw const SpectrumFormatException('no ChannelData');
    }
    final chAttrs = channel.group(2) ?? '';
    final compression = _attribute(chAttrs, 'compressionCode') ??
        _attribute(chAttrs, 'Compression') ??
        'None';
    final tokens = (channel.group(3) ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final counts = switch (compression.toLowerCase()) {
      'none' => [for (final t in tokens) _count(t)],
      'countedzeroes' => _countedZeroes(tokens),
      _ => throw SpectrumFormatException('unsupported compression: $compression'),
    };
    if (counts.isEmpty) {
      throw const SpectrumFormatException('empty ChannelData');
    }
    final calRef = _attribute(attrs, 'energyCalibrationReference');
    final energy = (calRef != null && calibrations.containsKey(calRef))
        ? calibrations[calRef]
        : fallbackCalibration;
    final live = _element('LiveTimeDuration').firstMatch(body);
    final real = _element('RealTimeDuration').firstMatch(body);
    final detRef = _attribute(attrs, 'radDetectorInformationReference');
    final category = detRef == null ? null : categories[detRef];
    final meaningfulEnergy = _meaningful(energy);
    return Spectrum(
      counts: counts,
      liveTimeSeconds: _seconds(live?.group(3)),
      realTimeSeconds: _seconds(real?.group(3)),
      energyCoefficients: meaningfulEnergy,
      energyUnit: unit ?? _defaultEnergyUnit(category, meaningfulEnergy),
      detectorCategory: category,
      nuclideResults: nuclides,
    );
  }

  /// Ha a fájl nem ad meg energia-egységet: gamma detektornál a nem
  /// azonosság-kalibráció (E = csatorna) keV-ban értendő.
  static String? _defaultEnergyUnit(String? category, List<double>? c) {
    if (category == null || category.toLowerCase() != 'gamma') return null;
    if (c == null) return null;
    final identity =
        c.length >= 2 && c[0] == 0 && c[1] == 1 && (c.length < 3 || c[2] == 0);
    return identity ? null : 'keV';
  }

  /// Az elemzési eredmény nuklidjai: a NuclideIdentifiedIndicator = true elemek
  /// nevükkel és a fájlban megadott aktivitásukkal.
  static List<NuclideResult> _identifiedNuclides(String xml) {
    final out = <NuclideResult>[];
    for (final m in _element('Nuclide').allMatches(xml)) {
      final body = m.group(3) ?? '';
      final name = _element('NuclideName').firstMatch(body)?.group(3)?.trim();
      final identified = _element('NuclideIdentifiedIndicator')
              .firstMatch(body)
              ?.group(3)
              ?.trim()
              .toLowerCase() ==
          'true';
      if (name == null || name.isEmpty || !identified) continue;
      if (out.any((r) => r.nuclide == name)) continue;
      out.add((
        nuclide: name,
        value: _number(_element('NuclideActivityValue').firstMatch(body)?.group(3)),
        uncertainty:
            _number(_element('NuclideActivityUncertaintyValue').firstMatch(body)?.group(3)),
      ));
    }
    return out;
  }

  static double? _number(String? raw) => double.tryParse(raw?.trim() ?? '');

  static int _count(String token) {
    final v = double.tryParse(token);
    if (v == null) throw const SpectrumFormatException('bad channel count');
    return v.round();
  }

  static List<int> _countedZeroes(List<String> tokens) {
    final out = <int>[];
    var i = 0;
    while (i < tokens.length) {
      final value = _count(tokens[i]);
      if (value == 0 && i + 1 < tokens.length) {
        out.addAll(List<int>.filled(_count(tokens[i + 1]), 0));
        i += 2;
      } else {
        out.add(value);
        i += 1;
      }
    }
    return out;
  }

  /// Csupa nulla kalibráció = nincs energiaskála.
  static List<double>? _meaningful(List<double>? c) {
    if (c == null || c.isEmpty) return null;
    return c.every((v) => v == 0) ? null : c;
  }

  static String? _attribute(String attrs, String name) {
    final m = RegExp(r'(?<![\w:\-])' + name + r'\s*=\s*"([^"]*)"').firstMatch(attrs);
    return m?.group(1);
  }

  /// Kalibrációs együtthatók egy blokkból: N42 2011 (CoefficientValues) vagy
  /// N42 2006 (Coefficients).
  static List<double>? _coefficients(String body) {
    final m = _element('CoefficientValues').firstMatch(body) ??
        _element('Coefficients').firstMatch(body);
    if (m == null) return null;
    final values = <double>[];
    for (final token in (m.group(3) ?? '').trim().split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final value = double.tryParse(token);
      if (value == null) return null;
      values.add(value);
    }
    return values.isEmpty ? null : values;
  }

  /// Az energia-egység a Calibration elem EnergyUnits attribútumából.
  static String? _energyUnit(String xml) {
    final m = RegExp(r'<(?:[A-Za-z_][\w.\-]*:)?Calibration\b([^>]*)>').firstMatch(xml);
    return m == null ? null : _attribute(m.group(1) ?? '', 'EnergyUnits');
  }

  /// ISO 8601 időtartam (pl. "PT600.0S", "PT1M30S") vagy sima szám másodpercben.
  static double? _seconds(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final plain = double.tryParse(text);
    if (plain != null) return plain;
    final m = RegExp(
      r'^P(?:T)?(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?$',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return null;
    double part(int i) => double.tryParse(m.group(i) ?? '') ?? 0;
    return part(1) * 3600 + part(2) * 60 + part(3);
  }
}
