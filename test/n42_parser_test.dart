import 'package:flutter_test/flutter_test.dart';
import 'package:rad_recon/models/spectrum.dart';

// Két spektrum, mindegyik a saját kalibrációjával és detektor-kategóriájával,
// a valódi fájlok szerkezete szerint.
const _fixture = '''<RadInstrumentData xmlns="http://physics.nist.gov/N42/2011/N42">
  <RadDetectorInformation id="Sd-G"><RadDetectorCategoryCode>Gamma</RadDetectorCategoryCode></RadDetectorInformation>
  <RadDetectorInformation id="Sd-N"><RadDetectorCategoryCode>Neutron</RadDetectorCategoryCode></RadDetectorInformation>
  <EnergyCalibration id="No-calibration-used"><CoefficientValues>0.0 0.0 0.0</CoefficientValues></EnergyCalibration>
  <EnergyCalibration id="ENCAL-01"><CoefficientValues>0.000002 0.375941 0.0</CoefficientValues></EnergyCalibration>
  <RadMeasurement>
    <Spectrum id="g" radDetectorInformationReference="Sd-G" energyCalibrationReference="ENCAL-01">
      <LiveTimeDuration>PT9M33.267407S</LiveTimeDuration>
      <ChannelData compressionCode="None">1 2 3 4</ChannelData>
    </Spectrum>
    <Spectrum id="n" radDetectorInformationReference="Sd-N" energyCalibrationReference="No-calibration-used">
      <LiveTimeDuration>PT9M33.267407S</LiveTimeDuration>
      <ChannelData compressionCode="CountedZeroes">0 2 1 0 1 1</ChannelData>
    </Spectrum>
  </RadMeasurement>
</RadInstrumentData>''';

void main() {
  test('két spektrum, mindegyik a saját kalibrációjával és kategóriájával', () {
    final all = N42Parser.parseAll(_fixture);
    expect(all.length, 2);
    expect(all[0].counts, [1, 2, 3, 4]);
    expect(all[0].liveTimeSeconds, closeTo(573.267407, 1e-6));
    expect(all[0].energyOfChannel(10), closeTo(3.759412, 1e-6));
    expect(all[0].detectorCategory, 'Gamma');
    expect(all[0].energyUnit, 'keV');
    expect(all[1].energyCoefficients, isNull);
    expect(all[1].energyUnit, isNull);
    expect(all[1].detectorCategory, 'Neutron');
  });

  test('CountedZeroes: a "0 n" pár n darab nulla csatorna', () {
    expect(N42Parser.parseAll(_fixture)[1].counts, [0, 0, 1, 0, 1]);
  });

  test('ismeretlen tömörítés hibát ad', () {
    const xml = '<RadInstrumentData><Spectrum><ChannelData compressionCode="ZeroSuppression">1 2</ChannelData></Spectrum></RadInstrumentData>';
    expect(() => N42Parser.parse(xml), throwsA(isA<SpectrumFormatException>()));
  });

  test('toN42Xml visszaolvasható, a kalibráció és az idő megmarad', () {
    final s = N42Parser.parseAll(_fixture)[0];
    final back = N42Parser.parse(s.toN42Xml());
    expect(back.counts, [1, 2, 3, 4]);
    expect(back.liveTimeSeconds, closeTo(573.267407, 1e-3));
    expect(back.energyCoefficients, s.energyCoefficients);
  });

  test('azonosított nuklid, gamma-kalibráció keV-ban; azonosság-kalibráció egység nélkül', () {
    const xml = '''<RadInstrumentData>
  <RadDetectorInformation id="Gamma-0"><RadDetectorCategoryCode>Gamma</RadDetectorCategoryCode></RadDetectorInformation>
  <EnergyCalibration id="E"><CoefficientValues>0.5 0.4 0</CoefficientValues></EnergyCalibration>
  <RadMeasurement><Spectrum radDetectorInformationReference="Gamma-0" energyCalibrationReference="E"><ChannelData>1 2</ChannelData></Spectrum></RadMeasurement>
  <AnalysisResults><NuclideAnalysisResults>
    <Nuclide><NuclideName>Cs-137</NuclideName><NuclideIdentifiedIndicator>true</NuclideIdentifiedIndicator></Nuclide>
    <Nuclide><NuclideName>Co-60</NuclideName><NuclideIdentifiedIndicator>false</NuclideIdentifiedIndicator></Nuclide>
  </NuclideAnalysisResults></AnalysisResults>
</RadInstrumentData>''';
    final s = N42Parser.parse(xml);
    expect(s.energyUnit, 'keV');
    expect(s.identifiedNuclides, ['Cs-137']);

    const identity = '''<RadInstrumentData>
  <RadDetectorInformation id="G"><RadDetectorCategoryCode>Gamma</RadDetectorCategoryCode></RadDetectorInformation>
  <EnergyCalibration id="E"><CoefficientValues>0 1.000000 0</CoefficientValues></EnergyCalibration>
  <RadMeasurement><Spectrum radDetectorInformationReference="G" energyCalibrationReference="E"><ChannelData>1 2</ChannelData></Spectrum></RadMeasurement>
</RadInstrumentData>''';
    expect(N42Parser.parse(identity).energyUnit, isNull);
  });

  test('nuklid-aktivitás és bizonytalanság a fájlból, JSON-ban visszaolvasható', () {
    const xml = '''<RadInstrumentData>
  <RadDetectorInformation id="G"><RadDetectorCategoryCode>Gamma</RadDetectorCategoryCode></RadDetectorInformation>
  <RadMeasurement><Spectrum radDetectorInformationReference="G"><ChannelData>1 2</ChannelData></Spectrum></RadMeasurement>
  <AnalysisResults><NuclideAnalysisResults><Nuclide><NuclideName>Cs-137</NuclideName><NuclideIdentifiedIndicator>true</NuclideIdentifiedIndicator><NuclideActivityValue>169.106659</NuclideActivityValue><NuclideActivityUncertaintyValue>14.713530</NuclideActivityUncertaintyValue></Nuclide></NuclideAnalysisResults></AnalysisResults>
</RadInstrumentData>''';
    final s = N42Parser.parse(xml);
    expect(s.nuclideResults.single.nuclide, 'Cs-137');
    expect(s.nuclideResults.single.value, closeTo(169.106659, 1e-6));
    expect(s.nuclideResults.single.uncertainty, closeTo(14.71353, 1e-6));
    final json = NuclideActivity.listToJson(
        [const NuclideActivity(nuclide: 'Cs-137', mbq: 169.1, uncertaintyMbq: 14.7)]);
    final back = NuclideActivity.listFromJson(json);
    expect(back.single.nuclide, 'Cs-137');
    expect(back.single.uncertaintyMbq, closeTo(14.7, 1e-9));
    expect(NuclideActivity.listFromJson(null), isEmpty);
  });
}
