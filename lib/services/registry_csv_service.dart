import '../models/victim_details.dart';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import 'exchange_format.dart';
import '../models/instrument.dart';
import '../models/person.dart';
import '../models/person_dose.dart';
import '../models/activity_origin.dart';
import '../models/radiation_source.dart';
import '../models/source_nuclide.dart';

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
      ['name', 'medical_exam_expiry_date', 'training_expiry_date', 'notes', 'created_at', 'updated_at', 'phone', 'emails', 'sex', 'age_years', 'weight_kg', 'height_cm', 'identifier', 'address'],
      ...persons.map((person) => [
            person.name,
            person.medicalExamExpiryDate?.toIso8601String(),
            person.trainingExpiryDate?.toIso8601String(),
            person.notes,
            person.createdAt.toIso8601String(),
            person.updatedAt.toIso8601String(),
            person.phone,
            person.emails.join('|'),
            person.sex?.dbValue,
            person.ageYears,
            person.weightKg,
            person.heightCm,
            person.identifier,
            person.address,
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
        'period_end', 'survey_title', 'notes', 'include_annual',
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
            r['include_annual'],
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
        includeAnnual: _optional(row, 'include_annual') != '0',
        createdAt: now,
        updatedAt: now,
      ));
      existingKeys.add(key);
      imported++;
    }
    return RegistryImportResult(imported: imported, replaced: 0, skipped: skipped);
  }

  Future<File> exportRadiationSources() async {
    final db = DatabaseHelper.instance;
    final sources = await db.getRadiationSources();
    final rows = <List<Object?>>[
      [
        ExchangeFormat.csvVersionColumn, 'identifier', 'nuclide',
        'activity_mbq', 'reference_date', 'origin',
        'activity_error_percent', 'manufacture_date',
        'service_life_expiry_date', 'next_inspection_date', 'notes',
        'created_at', 'updated_at', 'source_origin',
      ],
    ];
    for (final source in sources) {
      final nuclides = await db.getSourceNuclides(source.id!);
      // Nuklid-sor nélküli forrás is egy sorral szerepel, üres nuklidnévvel.
      final List<SourceNuclide?> lines = nuclides.isEmpty ? [null] : nuclides;
      for (final n in lines) {
        rows.add([
          ExchangeFormat.csvCurrentVersion,
          source.identifier,
          n?.nuclide,
          n?.activityMBq,
          n?.referenceDate.toIso8601String(),
          n?.origin.name,
          source.activityErrorPercent,
          source.manufactureDate?.toIso8601String(),
          source.serviceLifeExpiryDate?.toIso8601String(),
          source.nextInspectionDate?.toIso8601String(),
          source.notes,
          source.createdAt.toIso8601String(),
          source.updatedAt.toIso8601String(),
          source.origin,
        ]);
      }
    }
    return _writeCsv('radiation_sources.csv', rows);
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
        phone: _optional(row, 'phone'),
        emails: (_optional(row, 'emails') ?? '')
            .split('|')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        sex: VictimSex.fromDbValue(_optional(row, 'sex')),
        ageYears: int.tryParse(_optional(row, 'age_years') ?? ''),
        weightKg: double.tryParse(_optional(row, 'weight_kg') ?? ''),
        heightCm: double.tryParse(_optional(row, 'height_cm') ?? ''),
        identifier: _optional(row, 'identifier'),
        address: _optional(row, 'address'),
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
          phone: person.phone,
          emails: person.emails,
          sex: person.sex,
          ageYears: person.ageYears,
          weightKg: person.weightKg,
          heightCm: person.heightCm,
          identifier: person.identifier,
          address: person.address,
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

  static const _csvV1Required = [
    'identifier', 'nuclide_name', 'activity_at_manufacture_mbq',
    'activity_error_percent', 'manufacture_date',
    'service_life_expiry_date', 'next_inspection_date', 'notes',
    'created_at', 'updated_at',
  ];

  static const _csvV2Required = [
    'identifier', 'nuclide', 'activity_mbq', 'reference_date', 'origin',
    'manufacture_date',
  ];

  Future<RegistryImportResult> importRadiationSources(
    String csv,
    DuplicateImportPolicy policy,
  ) async {
    final records = _parseCsv(csv.replaceFirst('﻿', ''));
    if (records.isEmpty) throw const FormatException('CSV is empty.');
    final headers = records.first.map((value) => value.trim()).toList();
    final isV2 = headers.contains(ExchangeFormat.csvVersionColumn);
    if (isV2 && records.length > 1) {
      final versionIndex = headers.indexOf(ExchangeFormat.csvVersionColumn);
      ExchangeFormat.checkCsvVersion(
        records[1].length > versionIndex ? records[1][versionIndex] : null,
      );
    }
    final rows = _readRows(csv, isV2 ? _csvV2Required : _csvV1Required);
    // v2: a forrás nuklid-sorai azonos azonosítójú sorok. v1: egy sor = egy forrás.
    final groups = isV2
        ? ExchangeFormat.groupRowsByIdentifier(rows).values.toList()
        : [for (final row in rows) [row]];

    final db = DatabaseHelper.instance;
    final existing = await db.getRadiationSources();
    var imported = 0;
    var replaced = 0;
    var skipped = 0;
    for (final group in groups) {
      final head = group.first;
      final now = DateTime.now();
      final identifier = _required(head, 'identifier');
      final manufactureDate = _date(head, 'manufacture_date');
      final nuclides = <SourceNuclide>[];
      for (final row in group) {
        final name =
            isV2 ? _optional(row, 'nuclide') : _required(row, 'nuclide_name');
        if (name == null) continue;
        final activity = isV2
            ? _number(row, 'activity_mbq')
            : _number(row, 'activity_at_manufacture_mbq');
        final referenceDate = isV2
            ? (_date(row, 'reference_date') ?? manufactureDate)
            : manufactureDate;
        if (referenceDate == null) {
          throw FormatException('Missing reference date for "$identifier".');
        }
        nuclides.add(SourceNuclide(
          radiationSourceId: 0,
          nuclide: name,
          activityMBq: activity,
          referenceDate: referenceDate,
          origin: isV2 ? _origin(row) : ActivityOrigin.manual,
          createdAt: now,
        ));
      }
      final primary = nuclides.isEmpty ? null : nuclides.first;
      final source = RadiationSource(
        identifier: identifier,
        nuclideName: primary?.nuclide ?? '',
        activityAtManufactureMBq: primary?.activityMBq,
        activityErrorPercent: _number(head, 'activity_error_percent'),
        manufactureDate: manufactureDate,
        serviceLifeExpiryDate: _date(head, 'service_life_expiry_date'),
        nextInspectionDate: _date(head, 'next_inspection_date'),
        notes: _optional(head, 'notes'),
        origin: _optional(head, 'source_origin') ?? 'own',
        createdAt: _date(head, 'created_at') ?? now,
        updatedAt: _date(head, 'updated_at') ?? now,
      );

      final match = _findMatch(existing, identifier, (item) => item.identifier);
      if (match != null && policy == DuplicateImportPolicy.skip) {
        skipped++;
      } else if (match != null && policy == DuplicateImportPolicy.replace) {
        await db.updateRadiationSource(RadiationSource(
          id: match.id,
          identifier: source.identifier,
          nuclideName: source.nuclideName,
          activityAtManufactureMBq: source.activityAtManufactureMBq,
          activityErrorPercent: source.activityErrorPercent,
          manufactureDate: source.manufactureDate,
          serviceLifeExpiryDate: source.serviceLifeExpiryDate,
          nextInspectionDate: source.nextInspectionDate,
          notes: source.notes,
          certificateFiles: match.certificateFiles,
          notifyEnabled: match.notifyEnabled,
          createdAt: match.createdAt,
          updatedAt: now,
        ));
        await db.replaceSourceNuclides(match.id!, nuclides);
        replaced++;
      } else {
        await db.insertRadiationSourceWithNuclides(source, nuclides);
        imported++;
        existing.add(source);
      }
    }
    return RegistryImportResult(imported: imported, replaced: replaced, skipped: skipped);
  }

  ActivityOrigin _origin(Map<String, String> row) {
    final raw = _optional(row, 'origin') ?? ActivityOrigin.manual.name;
    try {
      return ActivityOrigin.values.byName(raw);
    } catch (_) {
      throw FormatException('Invalid origin in "origin": $raw');
    }
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