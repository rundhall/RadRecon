import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/instrument.dart';
import '../models/person.dart';
import '../models/person_dose.dart';
import '../models/radiation_source.dart';

enum DuplicateImportPolicy { replace, skip, keepDuplicate }

class RegistryImportResult {
  final int imported;
  final int replaced;
  final int skipped;

  const RegistryImportResult({
    required this.imported,
    required this.replaced,
    required this.skipped,
  });
}

/// CSV exchange for the three global registries. Column names are stable and
/// independent of the app language so exports can be re-imported anywhere.
class RegistryCsvService {
  Future<File> exportPersons() async {
    final persons = await DatabaseHelper.instance.getPersons();
    return _writeCsv('persons.csv', [
      ['name', 'medical_exam_expiry_date', 'training_expiry_date', 'notes', 'created_at', 'updated_at'],
      ...persons.map((person) => [
            person.name,
            person.medicalExamExpiryDate?.toIso8601String(),
            person.trainingExpiryDate?.toIso8601String(),
            person.notes,
            person.createdAt.toIso8601String(),
            person.updatedAt.toIso8601String(),
          ]),
    ]);
  }

  /// Személyek dózisai (online / manuális / passzív). A személyt név
  /// azonosítja, ezért importáláskor előbb a persons.csv-t kell betölteni.
  Future<File> exportPersonDoses() async {
    final rows = await DatabaseHelper.instance.getDoseExportRows();
    return _writeCsv('person_doses.csv', [
      [
        'person_name', 'source', 'dose_usv', 'dose_date', 'period_start',
        'period_end', 'survey_title', 'notes',
      ],
      ...rows.map((r) => [
            r['person_name'],
            r['source'],
            r['dose_usv'],
            r['dose_date'],
            r['period_start'],
            r['period_end'],
            r['survey_title'],
            r['notes'],
          ]),
    ]);
  }

  /// A CSV fejléce alapján dönti el, hogy dózis-export-e.
  static bool isDoseCsv(String csv) {
    final firstLine = csv.replaceFirst('\uFEFF', '').split(RegExp(r'[\r\n]')).first;
    return firstLine.contains('dose_usv');
  }

  /// Dózisok importja. A személyt névvel keresi a nyilvántartásban; ha nincs
  /// ilyen, a sor kimarad. Az azonos (személy, forrás, érték, dátum, időszak)
  /// bejegyzés duplikátumnak számít, és kimarad — kivéve, ha a policy
  /// [DuplicateImportPolicy.keepDuplicate]. A felmérés-kötés nem importálódik
  /// (a felmérések nincsenek a CSV-ben): a felmérés címe a megjegyzésbe kerül.
  Future<RegistryImportResult> importPersonDoses(
    String csv,
    DuplicateImportPolicy policy,
  ) async {
    final rows = _readRows(csv, const [
      'person_name', 'source', 'dose_usv', 'dose_date',
    ]);
    final db = DatabaseHelper.instance;
    final persons = await db.getPersons();
    String keyOf(String name, String source, double usv, DateTime date,
            DateTime? start, DateTime? end) =>
        '${name.trim().toLowerCase()}|$source|${usv.toStringAsFixed(6)}|'
        '${date.toIso8601String()}|${start?.toIso8601String()}|'
        '${end?.toIso8601String()}';
    final existingKeys = <String>{
      for (final r in await db.getDoseExportRows())
        keyOf(
          r['person_name'] as String,
          r['source'] as String,
          (r['dose_usv'] as num).toDouble(),
          DateTime.parse(r['dose_date'] as String),
          r['period_start'] == null
              ? null
              : DateTime.parse(r['period_start'] as String),
          r['period_end'] == null
              ? null
              : DateTime.parse(r['period_end'] as String),
        ),
    };

    var imported = 0;
    var skipped = 0;
    for (final row in rows) {
      final name = _required(row, 'person_name');
      final source = DoseSourceX.fromDbValue(_required(row, 'source'));
      final usv = _number(row, 'dose_usv');
      final date = _date(row, 'dose_date');
      if (usv == null || usv < 0 || date == null) {
        throw const FormatException('Invalid dose row.');
      }
      final start = _date(row, 'period_start');
      final end = _date(row, 'period_end');
      final person = _findMatch(persons, name, (item) => item.name);
      final key = keyOf(name, source.dbValue, usv, date, start, end);
      if (person == null ||
          (policy != DuplicateImportPolicy.keepDuplicate &&
              existingKeys.contains(key))) {
        skipped++;
        continue;
      }
      final survey = _optional(row, 'survey_title');
      final now = DateTime.now();
      await db.insertPassiveDose(PersonDose(
        personId: person.id!,
        source: source,
        doseMicroSv: usv,
        doseDate: date,
        periodStart: start,
        periodEnd: end,
        notes: _optional(row, 'notes') ??
            (survey == null ? null : 'Felmérés: $survey'),
        createdAt: now,
        updatedAt: now,
      ));
      existingKeys.add(key);
      imported++;
    }
    return RegistryImportResult(imported: imported, replaced: 0, skipped: skipped);
  }

  Future<File> exportRadiationSources() async {
    final sources = await DatabaseHelper.instance.getRadiationSources();
    return _writeCsv('radiation_sources.csv', [
      [
        'identifier', 'nuclide_name', 'activity_at_manufacture_mbq',
        'activity_error_percent', 'manufacture_date',
        'service_life_expiry_date', 'next_inspection_date', 'notes',
        'created_at', 'updated_at',
      ],
      ...sources.map((source) => [
            source.identifier,
            source.nuclideName,
            source.activityAtManufactureMBq,
            source.activityErrorPercent,
            source.manufactureDate.toIso8601String(),
            source.serviceLifeExpiryDate?.toIso8601String(),
            source.nextInspectionDate?.toIso8601String(),
            source.notes,
            source.createdAt.toIso8601String(),
            source.updatedAt.toIso8601String(),
          ]),
    ]);
  }

  Future<File> exportInstruments() async {
    final instruments = await DatabaseHelper.instance.getInstruments();
    return _writeCsv('instruments.csv', [
      [
        'name', 'serial_number', 'calibration_date', 'calibration_factor',
        'is_modbus_connected', 'modbus_host', 'modbus_port', 'modbus_unit_id',
        'modbus_register_address',
      ],
      ...instruments.map((instrument) => [
            instrument.name,
            instrument.serialNumber,
            instrument.calibrationDate?.toIso8601String(),
            instrument.calibrationFactor,
            instrument.isModbusConnected,
            instrument.modbusHost,
            instrument.modbusPort,
            instrument.modbusUnitId,
            instrument.modbusRegisterAddress,
          ]),
    ]);
  }

  Future<RegistryImportResult> importPersons(
    String csv,
    DuplicateImportPolicy policy,
  ) async {
    final rows = _readRows(csv, const [
      'name', 'medical_exam_expiry_date', 'training_expiry_date', 'notes',
      'created_at', 'updated_at',
    ]);
    final persons = rows.map((row) {
      final now = DateTime.now();
      return Person(
        name: _required(row, 'name'),
        medicalExamExpiryDate: _date(row, 'medical_exam_expiry_date'),
        trainingExpiryDate: _date(row, 'training_expiry_date'),
        notes: _optional(row, 'notes'),
        createdAt: _date(row, 'created_at') ?? now,
        updatedAt: _date(row, 'updated_at') ?? now,
      );
    }).toList();
    final existing = await DatabaseHelper.instance.getPersons();
    var imported = 0;
    var replaced = 0;
    var skipped = 0;
    for (final person in persons) {
      final match = _findMatch(existing, person.name, (item) => item.name);
      if (match != null && policy == DuplicateImportPolicy.skip) {
        skipped++;
      } else if (match != null && policy == DuplicateImportPolicy.replace) {
        await DatabaseHelper.instance.updatePerson(Person(
          id: match.id,
          name: person.name,
          medicalExamExpiryDate: person.medicalExamExpiryDate,
          trainingExpiryDate: person.trainingExpiryDate,
          notes: person.notes,
          createdAt: match.createdAt,
          updatedAt: DateTime.now(),
        ));
        replaced++;
      } else {
        await DatabaseHelper.instance.insertPerson(person);
        imported++;
        existing.add(person);
      }
    }
    return RegistryImportResult(imported: imported, replaced: replaced, skipped: skipped);
  }

  Future<RegistryImportResult> importRadiationSources(
    String csv,
    DuplicateImportPolicy policy,
  ) async {
    final rows = _readRows(csv, const [
      'identifier', 'nuclide_name', 'activity_at_manufacture_mbq',
      'activity_error_percent', 'manufacture_date',
      'service_life_expiry_date', 'next_inspection_date', 'notes',
      'created_at', 'updated_at',
    ]);
    final sources = rows.map((row) {
      final now = DateTime.now();
      return RadiationSource(
        identifier: _required(row, 'identifier'),
        nuclideName: _required(row, 'nuclide_name'),
        activityAtManufactureMBq: _number(row, 'activity_at_manufacture_mbq')!,
        activityErrorPercent: _number(row, 'activity_error_percent'),
        manufactureDate: _date(row, 'manufacture_date')!,
        serviceLifeExpiryDate: _date(row, 'service_life_expiry_date'),
        nextInspectionDate: _date(row, 'next_inspection_date'),
        notes: _optional(row, 'notes'),
        createdAt: _date(row, 'created_at') ?? now,
        updatedAt: _date(row, 'updated_at') ?? now,
      );
    }).toList();
    final existing = await DatabaseHelper.instance.getRadiationSources();
    var imported = 0;
    var replaced = 0;
    var skipped = 0;
    for (final source in sources) {
      final match = _findMatch(existing, source.identifier, (item) => item.identifier);
      if (match != null && policy == DuplicateImportPolicy.skip) {
        skipped++;
      } else if (match != null && policy == DuplicateImportPolicy.replace) {
        await DatabaseHelper.instance.updateRadiationSource(RadiationSource(
          id: match.id,
          identifier: source.identifier,
          nuclideName: source.nuclideName,
          activityAtManufactureMBq: source.activityAtManufactureMBq,
          activityErrorPercent: source.activityErrorPercent,
          manufactureDate: source.manufactureDate,
          serviceLifeExpiryDate: source.serviceLifeExpiryDate,
          nextInspectionDate: source.nextInspectionDate,
          notes: source.notes,
          createdAt: match.createdAt,
          updatedAt: DateTime.now(),
        ));
        replaced++;
      } else {
        await DatabaseHelper.instance.insertRadiationSource(source);
        imported++;
        existing.add(source);
      }
    }
    return RegistryImportResult(imported: imported, replaced: replaced, skipped: skipped);
  }

  Future<RegistryImportResult> importInstruments(
    String csv,
    DuplicateImportPolicy policy,
  ) async {
    final rows = _readRows(csv, const [
      'name', 'serial_number', 'calibration_date', 'calibration_factor',
      'is_modbus_connected', 'modbus_host', 'modbus_port', 'modbus_unit_id',
      'modbus_register_address',
    ]);
    final instruments = rows.map((row) => Instrument(
          name: _required(row, 'name'),
          serialNumber: _optional(row, 'serial_number'),
          calibrationDate: _date(row, 'calibration_date'),
          calibrationFactor: _number(row, 'calibration_factor'),
          isModbusConnected: _boolean(row, 'is_modbus_connected'),
          modbusHost: _optional(row, 'modbus_host'),
          modbusPort: _integer(row, 'modbus_port'),
          modbusUnitId: _integer(row, 'modbus_unit_id'),
          modbusRegisterAddress: _integer(row, 'modbus_register_address'),
        )).toList();
    final existing = await DatabaseHelper.instance.getInstruments();
    var imported = 0;
    var replaced = 0;
    var skipped = 0;
    for (final instrument in instruments) {
      final match = instrument.serialNumber?.trim().isNotEmpty == true
          ? _findMatch(existing, instrument.serialNumber!, (item) => item.serialNumber ?? '')
          : null;
      if (match != null && policy == DuplicateImportPolicy.skip) {
        skipped++;
      } else if (match != null && policy == DuplicateImportPolicy.replace) {
        await DatabaseHelper.instance.updateInstrument(instrument.copyWith(id: match.id));
        replaced++;
      } else {
        await DatabaseHelper.instance.insertInstrument(instrument);
        imported++;
        existing.add(instrument);
      }
    }
    return RegistryImportResult(imported: imported, replaced: replaced, skipped: skipped);
  }

  Future<File> _writeCsv(String filename, List<List<Object?>> rows) async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, filename));
    await file.writeAsString(rows.map(_encodeRow).join('\r\n'));
    return file;
  }

  String _encodeRow(List<Object?> fields) => fields.map((field) {
        final value = field?.toString() ?? '';
        return '"${value.replaceAll('"', '""')}"';
      }).join(',');

  List<Map<String, String>> _readRows(String csv, List<String> requiredHeaders) {
    final records = _parseCsv(csv.replaceFirst('\uFEFF', ''));
    if (records.isEmpty) throw const FormatException('CSV is empty.');
    final headers = records.first.map((value) => value.trim()).toList();
    for (final header in requiredHeaders) {
      if (!headers.contains(header)) {
        throw FormatException('Missing CSV column: $header');
      }
    }
    return records.skip(1).where((row) => row.any((value) => value.isNotEmpty)).map((row) {
      if (row.length != headers.length) {
        throw const FormatException('CSV row has a different number of columns.');
      }
      return Map.fromEntries(List.generate(headers.length, (index) => MapEntry(headers[index], row[index])));
    }).toList();
  }

  List<List<String>> _parseCsv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      if (quoted) {
        if (char == '"') {
          if (index + 1 < text.length && text[index + 1] == '"') {
            field.write('"');
            index++;
          } else {
            quoted = false;
          }
        } else {
          field.write(char);
        }
      } else if (char == '"' && field.isEmpty) {
        quoted = true;
      } else if (char == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (char == '\n' || char == '\r') {
        row.add(field.toString());
        field = StringBuffer();
        rows.add(row);
        row = <String>[];
        if (char == '\r' && index + 1 < text.length && text[index + 1] == '\n') index++;
      } else {
        field.write(char);
      }
    }
    if (quoted) throw const FormatException('CSV contains an unterminated quoted field.');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  T? _findMatch<T>(List<T> items, String key, String? Function(T) valueOf) {
    final normalized = key.trim().toLowerCase();
    for (final item in items) {
      if ((valueOf(item) ?? '').trim().toLowerCase() == normalized) return item;
    }
    return null;
  }

  String _required(Map<String, String> row, String key) {
    final value = _optional(row, key);
    if (value == null) throw FormatException('CSV value "$key" is required.');
    return value;
  }

  String? _optional(Map<String, String> row, String key) {
    final value = row[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  DateTime? _date(Map<String, String> row, String key) {
    final value = _optional(row, key);
    if (value == null) return null;
    final result = DateTime.tryParse(value);
    if (result == null) throw FormatException('Invalid date in "$key".');
    return result;
  }

  double? _number(Map<String, String> row, String key) {
    final value = _optional(row, key);
    if (value == null) return null;
    final result = double.tryParse(value);
    if (result == null || !result.isFinite) throw FormatException('Invalid number in "$key".');
    return result;
  }

  int? _integer(Map<String, String> row, String key) {
    final value = _optional(row, key);
    if (value == null) return null;
    final result = int.tryParse(value);
    if (result == null) throw FormatException('Invalid integer in "$key".');
    return result;
  }

  bool _boolean(Map<String, String> row, String key) {
    final value = _optional(row, key)?.toLowerCase();
    if (value == null || value == 'false' || value == '0') return false;
    if (value == 'true' || value == '1') return true;
    throw FormatException('Invalid boolean in "$key".');
  }
}