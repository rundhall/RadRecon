import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/instrument.dart';
import '../models/map_area.dart';
import '../models/map_measure_line.dart';
import '../models/company_document.dart';
import '../models/instrument_calibration.dart';
import '../models/person_certificate.dart';
import '../models/measurement_audit_entry.dart';
import '../models/measurement_point.dart';
import '../models/person.dart';
import '../models/person_condition.dart';
import '../models/person_dose.dart';
import '../models/session_dosimeter.dart';
import '../models/point_source_link.dart';
import '../models/radiation_source.dart';
import '../models/session_person_link.dart';
import '../models/survey_session.dart';

/// Egyetlen belépési pont a lokális SQLite adatbázishoz.
///
/// Minta a RadRecon app `DatabaseHelper`-jéből: singleton, lusta
/// inicializálású `Database`, séma-verziózás `onUpgrade`-del.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  /// A lejárati dátumokat tartalmazó táblák (személyek, források)
  /// változásakor hívódik — a lejárati értesítések újraütemezéséhez.
  static void Function()? onExpiryDataChanged;

  static const _dbName = 'rad_recon.db';
  // v8: a `next_inspection_date` oszlop hozzáadva a `radiation_sources`
  // táblához az `_onUpgrade`-ben — a verziószámot emelni kellett, különben
  // azoknál, akik már version 7-en álltak (az oszlop előtti kódból),
  // `onUpgrade` soha nem futott volna le újra, és az INSERT hibára futott.
  // v9: Modbus GPS oszlopok az `instruments` táblában.
  // v10: `next_calibration_date` oszlop az `instruments` táblához.
  // v11: `person_doses` tábla (személyek dózisai: online/manuális/passzív).
  // v12: `modbus_measurement_type` és `modbus_unit` az `instruments` táblában
  // (mit mér és milyen egységben ad vissza a műszer a Modbus regiszterben).
  // v13: nuklid-azonosítás oszlopok a `measurement_points` táblában
  // (`nuclide_status`, `nuclides`).
  // v20: `value_error`, `averaging_samples`, `averaging_seconds` a
  // `measurement_points` táblában (mérési hiba, átlagolt mérés).
  // v14: árnyékolási rétegek (`shielding_layers`, JSON) a
  // `measurement_points` táblában.
  // v15: `instrument_calibrations` tábla (hitelesítési / kalibrálási előzmény).
  // v16: `phone` és `emails` a `persons` táblában.
  // v17: `person_certificates` tábla (személyek tetszőleges bizonyítványai).
  // v18: `certificate_files` (műbizonylat-csatolmányok) a `radiation_sources`
  // táblában.
  // v19: `company_documents` tábla (cég dokumentumai és engedélyei).
  // v21: `sample_unit` a `measurement_points` táblában (mintavétel egysége).
  // v22: doziméterek (session_dosimeters), felmérési dózis (online+manuális
  // összevonva), és `include_annual` jelölő a dózis-bejegyzéseken.
  // v26: térképi mérővonalak (`survey_map_lines`).
  static const _dbVersion = 26;

  /// A jelenlegi séma-verzió (a mentésfájlok kompatibilitás-ellenőrzéséhez).
  static const schemaVersion = _dbVersion;

  Database? _db;
  Completer<Database>? _dbOpening;

  /// Lusta, de konkurencia-biztos DB-elérés.
  ///
  /// Korábban `_db ??= await _initDatabase();` volt itt, ami versenyhelyzetet
  /// okozott: ha két hívás (pl. a lista képernyő `_reload()` és
  /// `_loadSession()` metódusa) egyszerre fut le, mielőtt `_db` beállna,
  /// mindkettő látja, hogy `_db == null`, és mindkettő elindítja az
  /// `openDatabase`-t ugyanarra a fájlra — ez okozta a lefagyást. A
  /// `Completer` biztosítja, hogy egyszerre csak egy megnyitás fusson, a
  /// többi hívás pedig ugyanarra az eredményre vár.
  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_dbOpening != null) return _dbOpening!.future;

    final completer = Completer<Database>();
    _dbOpening = completer;
    try {
      final db = await _initDatabase();
      _db = db;
      completer.complete(db);
    } catch (e, st) {
      completer.completeError(e, st);
      _dbOpening = null;
      rethrow;
    }
    return completer.future;
  }

  /// Az adatbázis-fájl teljes útvonala (mentéshez / visszatöltéshez).
  Future<String> databaseFilePath() async =>
      join(await _resolveDatabaseDirectory(), _dbName);

  Future<Database> _initDatabase() async {
    final path = await databaseFilePath();
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Az adatbázis-fájl célmappája.
  ///
  /// A `sqflite`/`sqflite_common_ffi` `getDatabasesPath()` Windows/Linux
  /// alatt az app futtatási könyvtárához (jellemzően a telepítés helyéhez,
  /// pl. `C:\Program Files\RadRecon`) közeli útvonalat ad vissza. Ha az app
  /// admin jog nélkül installált helyre kerül, oda a normál felhasználó
  /// nem tud írni — az adatbázis megnyitása/írása ilyenkor úgy viselkedik,
  /// mintha írásvédett lenne (pontosan ez volt a "csak rendszergazdaként
  /// működik" tünet oka). Windows és Linux desktop alatt ezért a
  /// felhasználó saját, mindig írható "application support" mappáját
  /// használjuk (Windows: `%LOCALAPPDATA%\rad_recon`), admin jog nélkül is.
  Future<String> _resolveDatabaseDirectory() async {
    if (Platform.isWindows || Platform.isLinux) {
      final dir = await getApplicationSupportDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
    return getDatabasesPath();
  }

  /// Az `instruments` tábla tényleges oszlopait nézi meg (PRAGMA
  /// table_info), és csak azokat pótolja, amelyek ténylegesen hiányoznak.
  ///
  /// Korábban ez `if (oldVersion < 2)` alapján döntötte el, mit kell
  /// hozzáadni — de ha valakinek a telepített appja már version 2-n állt,
  /// amikor a `modbus_unit_id`/`modbus_register_address` oszlopok bekerültek
  /// a kódba, a feltétel nem futott le nála, és a régi adatbázisában
  /// örökre hiányzott ez a két oszlop. Az oszlop-létezés tényleges
  /// ellenőrzése ettől függetlenül mindig helyesen pótolja a hiányzókat.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final columns = await db.rawQuery('PRAGMA table_info(instruments)');
    final existingNames = columns.map((c) => c['name'] as String).toSet();

    if (!existingNames.contains('modbus_unit_id')) {
      await db.execute(
        'ALTER TABLE instruments ADD COLUMN modbus_unit_id INTEGER',
      );
    }
    if (!existingNames.contains('modbus_register_address')) {
      await db.execute(
        'ALTER TABLE instruments ADD COLUMN modbus_register_address INTEGER',
      );
    }
    if (!existingNames.contains('is_modbus_gps_enabled')) {
      await db.execute(
        'ALTER TABLE instruments ADD COLUMN is_modbus_gps_enabled INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!existingNames.contains('modbus_gps_lat_address')) {
      await db.execute(
        'ALTER TABLE instruments ADD COLUMN modbus_gps_lat_address INTEGER NOT NULL DEFAULT 426',
      );
    }
    if (!existingNames.contains('modbus_gps_lon_address')) {
      await db.execute(
        'ALTER TABLE instruments ADD COLUMN modbus_gps_lon_address INTEGER NOT NULL DEFAULT 428',
      );
    }
    if (!existingNames.contains('modbus_measurement_type')) {
      await db.execute(
        "ALTER TABLE instruments ADD COLUMN modbus_measurement_type TEXT NOT NULL DEFAULT 'dose_rate'",
      );
    }
    if (!existingNames.contains('modbus_unit')) {
      await db.execute(
        "ALTER TABLE instruments ADD COLUMN modbus_unit TEXT NOT NULL DEFAULT 'nSv/h'",
      );
    }
    if (!existingNames.contains('next_calibration_date')) {
      await db.execute(
        'ALTER TABLE instruments ADD COLUMN next_calibration_date TEXT',
      );
    }

    final pointColumns = await db.rawQuery(
      'PRAGMA table_info(measurement_points)',
    );
    final pointColumnNames = pointColumns
        .map((c) => c['name'] as String)
        .toSet();
    if (!pointColumnNames.contains('sample_unit')) {
      await db.execute('ALTER TABLE measurement_points ADD COLUMN sample_unit TEXT');
    }

    // v22: felmérési dózis és doziméterek.
    final doseTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'person_doses'",
    );
    if (doseTables.isEmpty) {
      await _createPersonDosesTable(db);
    } else {
      final doseColumns = (await db.rawQuery('PRAGMA table_info(person_doses)'))
          .map((c) => c['name'] as String)
          .toSet();
      if (!doseColumns.contains('include_annual')) {
        await db.execute(
          'ALTER TABLE person_doses ADD COLUMN include_annual INTEGER NOT NULL DEFAULT 1',
        );
      }
      // Az online és manuális felmérési dózis egy `session` sorba olvad
      // (személyenként, felmérésenként), összege a korábbi érték.
      await db.execute('''
        INSERT INTO person_doses (person_id, survey_session_id, source, dose_usv,
          dose_date, notes, created_at, updated_at, include_annual)
        SELECT person_id, survey_session_id, 'session', SUM(dose_usv),
          MIN(dose_date), NULL, MIN(created_at), MAX(updated_at), 1
        FROM person_doses
        WHERE survey_session_id IS NOT NULL AND source IN ('online', 'manual')
        GROUP BY person_id, survey_session_id
      ''');
      await db.execute(
        "DELETE FROM person_doses WHERE survey_session_id IS NOT NULL AND source IN ('online', 'manual')",
      );
    }
    await _createSessionDosimetersTable(db);
    if (!pointColumnNames.contains('activity_calc_nuclide')) {
      await db.execute(
        'ALTER TABLE measurement_points ADD COLUMN activity_calc_nuclide TEXT',
      );
    }

    if (!pointColumnNames.contains('nuclide_status')) {
      await db.execute(
        "ALTER TABLE measurement_points ADD COLUMN nuclide_status TEXT NOT NULL DEFAULT 'none'",
      );
    }
    if (!pointColumnNames.contains('nuclides')) {
      await db.execute('ALTER TABLE measurement_points ADD COLUMN nuclides TEXT');
    }
    if (!pointColumnNames.contains('value_error')) {
      await db.execute(
        'ALTER TABLE measurement_points ADD COLUMN value_error REAL',
      );
    }
    if (!pointColumnNames.contains('averaging_samples')) {
      await db.execute(
        'ALTER TABLE measurement_points ADD COLUMN averaging_samples INTEGER',
      );
    }
    if (!pointColumnNames.contains('averaging_seconds')) {
      await db.execute(
        'ALTER TABLE measurement_points ADD COLUMN averaging_seconds INTEGER',
      );
    }
    if (!pointColumnNames.contains('shielding_layers')) {
      await db.execute(
        'ALTER TABLE measurement_points ADD COLUMN shielding_layers TEXT',
      );
    }

    await _createCalibrationTable(db);

    final sourceTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'radiation_sources'",
    );
    if (sourceTables.isEmpty) {
      await _createGlobalSourceTables(db);
    } else {
      final sourceColumns = await db.rawQuery(
        'PRAGMA table_info(radiation_sources)',
      );
      final sourceColumnNames = sourceColumns
          .map((c) => c['name'] as String)
          .toSet();

      if (sourceColumnNames.contains('measurement_point_id')) {
        // Régi séma (v4): a forrás még egyetlen ponthoz volt kötve, saját
        // "distance_meters" mezővel. Most a forrás globális nyilvántatássá
        // válik, a pont-kötés (és a rá jellemző távolság) pedig külön
        // hozzárendelés-táblába kerül át — a korábban felvitt adat nem
        // veszik el.
        await db.execute(
          'ALTER TABLE radiation_sources RENAME TO radiation_sources_v4',
        );
        await _createGlobalSourceTables(db);
        await db.execute('''
          INSERT INTO radiation_sources (
            id, identifier, nuclide_name, activity_at_manufacture_mbq,
            activity_error_percent, manufacture_date,
            service_life_expiry_date, notes, created_at, updated_at
          )
          SELECT
            id, identifier, nuclide_name, activity_at_manufacture_mbq,
            activity_error_percent, manufacture_date,
            service_life_expiry_date, notes, created_at, updated_at
          FROM radiation_sources_v4
        ''');
        await db.execute('''
          INSERT INTO measurement_point_sources (
            measurement_point_id, radiation_source_id, distance_meters, created_at
          )
          SELECT measurement_point_id, id, distance_meters, created_at
          FROM radiation_sources_v4
        ''');
        await db.execute('DROP TABLE radiation_sources_v4');
      } else {
        if (!sourceColumnNames.contains('certificate_files')) {
          await db.execute(
            'ALTER TABLE radiation_sources ADD COLUMN certificate_files TEXT',
          );
        }
        if (!sourceColumnNames.contains('next_inspection_date')) {
          await db.execute(
            'ALTER TABLE radiation_sources ADD COLUMN next_inspection_date TEXT',
          );
        }
        final linkTables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'measurement_point_sources'",
        );
        if (linkTables.isEmpty) {
          await _createPointSourcesTable(db);
        }
      }
    }

    final personTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'persons'",
    );
    if (personTables.isEmpty) {
      await _createPersonTables(db);
    } else {
      final personColumns = await db.rawQuery('PRAGMA table_info(persons)');
      final personColumnNames =
          personColumns.map((c) => c['name'] as String).toSet();
      if (!personColumnNames.contains('phone')) {
        await db.execute('ALTER TABLE persons ADD COLUMN phone TEXT');
      }
      if (!personColumnNames.contains('emails')) {
        await db.execute('ALTER TABLE persons ADD COLUMN emails TEXT');
      }
    }

    await _createPersonCertificatesTable(db);
    await _createCompanyDocumentsTable(db);

    // v23: az összerendelt személy szerepe (felmérő / érintett), triázs-
    // besorolása, és az érintett sérülései/betegségei.
    final sessionPersonTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'survey_session_persons'",
    );
    if (sessionPersonTables.isEmpty) {
      await _createSessionPersonsTable(db);
    } else {
      final linkColumns =
          (await db.rawQuery('PRAGMA table_info(survey_session_persons)'))
              .map((c) => c['name'] as String)
              .toSet();
      if (!linkColumns.contains('role')) {
        await db.execute(
          "ALTER TABLE survey_session_persons ADD COLUMN role TEXT NOT NULL DEFAULT 'surveyor'",
        );
      }
      if (!linkColumns.contains('triage')) {
        await db.execute(
          'ALTER TABLE survey_session_persons ADD COLUMN triage TEXT',
        );
      }
      await _createSessionPersonConditionsTable(db);
    }

    // v24: meteorológia és gázmérés a mérési pontokhoz (JSON-oszlopok).
    final measurementColumns =
        (await db.rawQuery('PRAGMA table_info(measurement_points)'))
            .map((c) => c['name'] as String)
            .toSet();
    if (!measurementColumns.contains('meteo_json')) {
      await db.execute(
        'ALTER TABLE measurement_points ADD COLUMN meteo_json TEXT',
      );
    }
    if (!measurementColumns.contains('gas_json')) {
      await db.execute(
        'ALTER TABLE measurement_points ADD COLUMN gas_json TEXT',
      );
    }

    // v25: térképi területjelölések.
    await _createSurveyMapAreasTable(db);

    // v26: térképi mérővonalak.
    await _createSurveyMapLinesTable(db);
  }

  Future<void> _createPersonDosesTable(Database db) async {
    await db.execute('''
      CREATE TABLE person_doses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER NOT NULL,
        survey_session_id INTEGER,
        source TEXT NOT NULL,
        dose_usv REAL NOT NULL,
        dose_date TEXT NOT NULL,
        period_start TEXT,
        period_end TEXT,
        include_annual INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (person_id) REFERENCES persons (id)
          ON DELETE CASCADE,
        FOREIGN KEY (survey_session_id) REFERENCES survey_sessions (id)
          ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_doses_person_date ON person_doses (person_id, dose_date)',
    );
    // Felmérésenként és személyenként legfeljebb egy online és egy manuális
    // bejegyzés; a passzív dozimetriából több is lehet.
    await db.execute('''
      CREATE UNIQUE INDEX idx_doses_session_unique
      ON person_doses (person_id, survey_session_id, source)
      WHERE survey_session_id IS NOT NULL
    ''');
  }

  Future<void> _createSessionDosimetersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_dosimeters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        survey_session_id INTEGER NOT NULL,
        kind TEXT NOT NULL,
        identifier TEXT NOT NULL,
        person_id INTEGER,
        start_usv REAL,
        end_usv REAL,
        dose_usv REAL,
        include_annual INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (survey_session_id) REFERENCES survey_sessions (id)
          ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES persons (id)
          ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_dosimeters_session ON session_dosimeters (survey_session_id)',
    );
  }

  Future<void> _createCompanyDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        identifier TEXT,
        issuer TEXT,
        issued_on TEXT,
        valid_until TEXT,
        notes TEXT,
        files TEXT
      )
    ''');
  }

  Future<void> _createPersonCertificatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS person_certificates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        number TEXT,
        issuer TEXT,
        issued_on TEXT,
        valid_until TEXT,
        file_path TEXT,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPersonTables(Database db) async {
    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        medical_exam_expiry_date TEXT,
        training_expiry_date TEXT,
        notes TEXT,
        phone TEXT,
        emails TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await _createSessionPersonsTable(db);
  }

  Future<void> _createSessionPersonsTable(Database db) async {
    await db.execute('''
      CREATE TABLE survey_session_persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        survey_session_id INTEGER NOT NULL,
        person_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'surveyor',
        triage TEXT,
        FOREIGN KEY (survey_session_id) REFERENCES survey_sessions (id)
          ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES persons (id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_session_persons_session ON survey_session_persons (survey_session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_session_persons_person ON survey_session_persons (person_id)',
    );
    await _createSessionPersonConditionsTable(db);
  }

  /// Az érintettek sérülései és betegségei (a hozzárendelés azonosítójához kötve).
  Future<void> _createSessionPersonConditionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_person_conditions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        link_id INTEGER NOT NULL,
        kind TEXT NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (link_id) REFERENCES survey_session_persons (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createGlobalSourceTables(Database db) async {
    await db.execute('''
      CREATE TABLE radiation_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identifier TEXT NOT NULL,
        nuclide_name TEXT NOT NULL,
        activity_at_manufacture_mbq REAL NOT NULL,
        activity_error_percent REAL,
        manufacture_date TEXT NOT NULL,
        service_life_expiry_date TEXT,
        next_inspection_date TEXT,
        notes TEXT,
        certificate_files TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await _createPointSourcesTable(db);
    await _createSurveyMapAreasTable(db);
    await _createSurveyMapLinesTable(db);
  }

  Future<void> _createPointSourcesTable(Database db) async {
    await db.execute('''
      CREATE TABLE measurement_point_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        measurement_point_id INTEGER NOT NULL,
        radiation_source_id INTEGER NOT NULL,
        distance_meters REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (measurement_point_id) REFERENCES measurement_points (id)
          ON DELETE CASCADE,
        FOREIGN KEY (radiation_source_id) REFERENCES radiation_sources (id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_point_sources_point ON measurement_point_sources (measurement_point_id)',
    );
    await db.execute(
      'CREATE INDEX idx_point_sources_source ON measurement_point_sources (radiation_source_id)',
    );
  }

  Future<void> _createCalibrationTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS instrument_calibrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        instrument_id INTEGER NOT NULL,
        kind TEXT NOT NULL,
        performed_on TEXT NOT NULL,
        valid_until TEXT,
        certificate_number TEXT,
        performed_by TEXT,
        file_path TEXT,
        FOREIGN KEY (instrument_id) REFERENCES instruments (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE survey_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        started_at TEXT NOT NULL,
        closed_at TEXT
      )
    ''');

    await _createCalibrationTable(db);

    await db.execute('''
      CREATE TABLE instruments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        serial_number TEXT,
        calibration_date TEXT,
        calibration_factor REAL,
        next_calibration_date TEXT,
        is_modbus_connected INTEGER NOT NULL DEFAULT 0,
        modbus_host TEXT,
        modbus_port INTEGER,
        modbus_unit_id INTEGER,
        modbus_register_address INTEGER,
        is_modbus_gps_enabled INTEGER NOT NULL DEFAULT 0,
        modbus_gps_lat_address INTEGER NOT NULL DEFAULT 426,
        modbus_gps_lon_address INTEGER NOT NULL DEFAULT 428,
        modbus_measurement_type TEXT NOT NULL DEFAULT 'dose_rate',
        modbus_unit TEXT NOT NULL DEFAULT 'nSv/h'
      )
    ''');

    await db.execute('''
      CREATE TABLE measurement_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        survey_session_id INTEGER NOT NULL,
        location_label TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        gps_accuracy_meters REAL,
        measurement_type TEXT NOT NULL,
        value REAL,
        value_error REAL,
        averaging_samples INTEGER,
        averaging_seconds INTEGER,
        unit TEXT NOT NULL,
        distance_from_source_meters REAL,
        activity_calc_nuclide TEXT,
        instrument_id INTEGER,
        nuclide_status TEXT NOT NULL DEFAULT 'none',
        nuclides TEXT,
        shielding_layers TEXT,
        is_source_position INTEGER NOT NULL DEFAULT 0,
        is_sample INTEGER NOT NULL DEFAULT 0,
        sample_container_id TEXT,
        sample_amount REAL,
        sample_method TEXT,
        sample_unit TEXT,
        meteo_json TEXT,
        gas_json TEXT,
        photo_path TEXT,
        notes TEXT,
        timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (survey_session_id) REFERENCES survey_sessions (id)
          ON DELETE CASCADE,
        FOREIGN KEY (instrument_id) REFERENCES instruments (id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE measurement_audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        measurement_point_id INTEGER NOT NULL,
        field_name TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        changed_at TEXT NOT NULL,
        FOREIGN KEY (measurement_point_id) REFERENCES measurement_points (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_points_session ON measurement_points (survey_session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_audit_point ON measurement_audit (measurement_point_id)',
    );

    await _createGlobalSourceTables(db);
    await _createPersonTables(db);
    await _createPersonCertificatesTable(db);
    await _createCompanyDocumentsTable(db);
    await _createPersonDosesTable(db);
    await _createSessionDosimetersTable(db);
  }

  // ---------------------------------------------------------------------
  // Survey sessions
  // ---------------------------------------------------------------------

  Future<int> insertSurveySession(SurveySession session) async {
    final db = await database;
    return db.insert('survey_sessions', session.toMap()..remove('id'));
  }

  Future<List<SurveySession>> getSurveySessions() async {
    final db = await database;
    final rows = await db.query('survey_sessions', orderBy: 'started_at DESC');
    return rows.map(SurveySession.fromMap).toList();
  }

  Future<SurveySession?> getSurveySession(int id) async {
    final db = await database;
    final rows = await db.query(
      'survey_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SurveySession.fromMap(rows.first);
  }

  Future<void> closeSurveySession(int id, DateTime closedAt) async {
    final db = await database;
    await db.update(
      'survey_sessions',
      {'closed_at': closedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// A felmérés nevét és helyszínét frissíti (pl. utólagos szerkesztéskor).
  Future<void> updateSurveySessionTitleAndLocation(
    int id,
    String title,
    String? location,
  ) async {
    final db = await database;
    await db.update(
      'survey_sessions',
      {'title': title, 'location': location},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------
  // Persons (globális nyilvántartás — a műszerekhez/forrásokhoz hasonlóan
  // egyszer felvéve, utána bármelyik felméréshez hozzárendelhető)
  // ---------------------------------------------------------------------

  Future<int> insertPerson(Person person) async {
    final db = await database;
    final id = await db.insert('persons', person.toMap()..remove('id'));
    onExpiryDataChanged?.call();
    return id;
  }

  Future<List<Person>> getPersons() async {
    final db = await database;
    final rows = await db.query('persons', orderBy: 'name ASC');
    final certs = await _certificatesByPerson(db);
    return rows
        .map((r) => Person.fromMap(r)
            .copyWith(certificates: certs[r['id'] as int] ?? const []))
        .toList();
  }

  Future<Map<int, List<PersonCertificate>>> _certificatesByPerson(
      Database db) async {
    final rows = await db.query('person_certificates',
        orderBy: 'valid_until IS NULL, valid_until ASC');
    final map = <int, List<PersonCertificate>>{};
    for (final r in rows) {
      final c = PersonCertificate.fromMap(r);
      if (c.personId != null) (map[c.personId!] ??= []).add(c);
    }
    return map;
  }

  /// Egy személy összes bizonyítványának cseréje.
  Future<void> replacePersonCertificates(
    int personId,
    List<PersonCertificate> certificates,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('person_certificates',
          where: 'person_id = ?', whereArgs: [personId]);
      for (final c in certificates) {
        await txn.insert('person_certificates',
            c.withPersonId(personId).toMap()..remove('id'));
      }
    });
    onExpiryDataChanged?.call();
  }

  Future<void> updatePerson(Person person) async {
    final db = await database;
    await db.update(
      'persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
    onExpiryDataChanged?.call();
  }

  /// Töröl egy személyt a nyilvántartásból. Minden felméréshez rendelt
  /// hozzárendelése is törlődik vele (ON DELETE CASCADE) — a felmérések
  /// maguk nem sérülnek.
  Future<void> deletePerson(int id) async {
    final db = await database;
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);
    onExpiryDataChanged?.call();
  }

  // ---------------------------------------------------------------------
  // Cég dokumentumai és engedélyei
  // ---------------------------------------------------------------------

  Future<List<CompanyDocument>> getCompanyDocuments() async {
    final db = await database;
    final rows = await db.query(
      'company_documents',
      orderBy: 'valid_until IS NULL, valid_until ASC, title ASC',
    );
    return rows.map(CompanyDocument.fromMap).toList();
  }

  Future<int> insertCompanyDocument(CompanyDocument d) async {
    final db = await database;
    final id = await db.insert('company_documents', d.toMap()..remove('id'));
    onExpiryDataChanged?.call();
    return id;
  }

  Future<void> updateCompanyDocument(CompanyDocument d) async {
    final db = await database;
    await db.update('company_documents', d.toMap(),
        where: 'id = ?', whereArgs: [d.id]);
    onExpiryDataChanged?.call();
  }

  Future<void> deleteCompanyDocument(int id) async {
    final db = await database;
    await db.delete('company_documents', where: 'id = ?', whereArgs: [id]);
    onExpiryDataChanged?.call();
  }

  // ---------------------------------------------------------------------
  // Személyek dózisai
  // ---------------------------------------------------------------------

  static String _yearStart(int year) => DateTime(year).toIso8601String();

  /// Az adott év dózisai személyenként (µSv). Csak a beszámító tételek
  /// számítanak: a felmérési és passzív dózisok, valamint a doziméterek.
  Future<Map<int, DoseTotals>> getAnnualDoseTotals(int year) async {
    final db = await database;
    final doseRows = await db.rawQuery(
      '''
      SELECT person_id, source, SUM(dose_usv) AS total
      FROM person_doses
      WHERE dose_date >= ? AND dose_date < ? AND include_annual = 1
      GROUP BY person_id, source
    ''',
      [_yearStart(year), _yearStart(year + 1)],
    );
    final result = <int, DoseTotals>{};
    for (final row in doseRows) {
      final id = row['person_id'] as int;
      result[id] = (result[id] ?? DoseTotals.zero).add(
        DoseSourceX.fromDbValue(row['source'] as String),
        (row['total'] as num).toDouble(),
      );
    }

    final dosimeterRows = await db.rawQuery(
      '''
      SELECT d.*
      FROM session_dosimeters d
      INNER JOIN survey_sessions s ON s.id = d.survey_session_id
      WHERE d.include_annual = 1 AND d.person_id IS NOT NULL
        AND s.started_at >= ? AND s.started_at < ?
    ''',
      [_yearStart(year), _yearStart(year + 1)],
    );
    for (final row in dosimeterRows) {
      final dosimeter = SessionDosimeter.fromMap(row);
      final dose = dosimeter.resolvedDoseUsv;
      if (dose == null) continue;
      final id = dosimeter.personId!;
      result[id] = (result[id] ?? DoseTotals.zero).addDosimeter(dose);
    }
    return result;
  }

  /// Választható évek csökkenő sorrendben: a legkorábbi dózis-bejegyzés (vagy
  /// az utolsó 5 év) és az aktuális év között minden év.
  Future<List<int>> getDoseYears() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT MIN(substr(dose_date, 1, 4)) AS y FROM person_doses",
    );
    final current = DateTime.now().year;
    final earliest = int.tryParse('${rows.first['y']}') ?? current;
    final first = earliest < current - 5 ? earliest : current - 5;
    return [for (var y = current; y >= first; y--) y];
  }

  /// Egy személy dózis-bejegyzései az adott évre, legfrissebb elöl.
  Future<List<PersonDose>> getPersonDoses(int personId, int year) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT d.*, s.title AS survey_title
      FROM person_doses d
      LEFT JOIN survey_sessions s ON s.id = d.survey_session_id
      WHERE d.person_id = ? AND d.dose_date >= ? AND d.dose_date < ?
      ORDER BY d.dose_date DESC
    ''',
      [personId, _yearStart(year), _yearStart(year + 1)],
    );
    return rows.map(PersonDose.fromMap).toList();
  }

  /// Egy felmérés dózisai: személyenként a felmérési dózis-bejegyzés, és a
  /// felmérés doziméterei.
  Future<SessionDoseSnapshot> getSessionDoseSnapshot(int surveySessionId) async {
    final db = await database;
    final doseRows = await db.query(
      'person_doses',
      where: "survey_session_id = ? AND source = 'session'",
      whereArgs: [surveySessionId],
    );
    final sessionDoses = <int, PersonDose>{};
    for (final row in doseRows) {
      final dose = PersonDose.fromMap(row);
      sessionDoses[dose.personId] = dose;
    }
    final dosimeterRows = await db.rawQuery(
      '''
      SELECT d.*, p.name AS person_name
      FROM session_dosimeters d
      LEFT JOIN persons p ON p.id = d.person_id
      WHERE d.survey_session_id = ?
      ORDER BY d.id
    ''',
      [surveySessionId],
    );
    return SessionDoseSnapshot(
      sessionDoses: sessionDoses,
      dosimeters: dosimeterRows.map(SessionDosimeter.fromMap).toList(),
    );
  }

  /// Felmérési dózis beállítása (pontokból számolt vagy kézzel megadott).
  /// [accumulate] igaz esetén a meglévő értékhez adja (az auto-log leállításakor).
  /// [includeAnnual] `null` esetén a meglévő jelölő marad; új sornál igaz.
  /// Nullára állításkor a bejegyzés törlődik.
  Future<void> setSessionDose({
    required int personId,
    required int surveySessionId,
    required double doseMicroSv,
    bool accumulate = false,
    bool? includeAnnual,
    DateTime? doseDate,
  }) async {
    final db = await database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'person_doses',
        where: "person_id = ? AND survey_session_id = ? AND source = 'session'",
        whereArgs: [personId, surveySessionId],
        limit: 1,
      );
      final previous = existing.isEmpty
          ? 0.0
          : (existing.first['dose_usv'] as num).toDouble();
      final value = accumulate ? previous + doseMicroSv : doseMicroSv;

      if (existing.isNotEmpty) {
        final id = existing.first['id'];
        if (value <= 0) {
          await txn.delete('person_doses', where: 'id = ?', whereArgs: [id]);
        } else {
          await txn.update(
            'person_doses',
            {
              'dose_usv': value,
              'updated_at': now.toIso8601String(),
              if (includeAnnual != null)
                'include_annual': includeAnnual ? 1 : 0,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      } else if (value > 0) {
        await txn.insert(
          'person_doses',
          PersonDose(
            personId: personId,
            surveySessionId: surveySessionId,
            source: DoseSource.session,
            doseMicroSv: value,
            doseDate: doseDate ?? now,
            includeAnnual: includeAnnual ?? true,
            createdAt: now,
            updatedAt: now,
          ).toMap()
            ..remove('id'),
        );
      }
    });
  }

  Future<int> insertSessionDosimeter(SessionDosimeter dosimeter) async {
    final db = await database;
    return db.insert(
      'session_dosimeters',
      dosimeter.toMap()..remove('id'),
    );
  }

  Future<void> updateSessionDosimeter(SessionDosimeter dosimeter) async {
    final db = await database;
    await db.update(
      'session_dosimeters',
      dosimeter.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [dosimeter.id],
    );
  }

  Future<void> deleteSessionDosimeter(int id) async {
    final db = await database;
    await db.delete('session_dosimeters', where: 'id = ?', whereArgs: [id]);
  }

  /// Az összes dózis-bejegyzés a személy nevével és a felmérés címével
  /// (CSV-exporthoz és duplikátum-ellenőrzéshez).
  Future<List<Map<String, Object?>>> getDoseExportRows() async {
    final db = await database;
    return db.rawQuery('''
      SELECT d.*, p.name AS person_name, s.title AS survey_title
      FROM person_doses d
      INNER JOIN persons p ON p.id = d.person_id
      LEFT JOIN survey_sessions s ON s.id = d.survey_session_id
      ORDER BY p.name COLLATE NOCASE, d.dose_date
    ''');
  }

  /// Felmérésektől független (passzív dozimetriás) bejegyzés felvétele.
  Future<int> insertPassiveDose(PersonDose dose) async {
    final db = await database;
    return db.insert('person_doses', dose.toMap()..remove('id'));
  }

  Future<void> updatePassiveDose(PersonDose dose) async {
    final db = await database;
    await db.update(
      'person_doses',
      dose.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [dose.id],
    );
  }

  Future<void> deleteDose(int id) async {
    final db = await database;
    await db.delete('person_doses', where: 'id = ?', whereArgs: [id]);
  }

  /// Mérési pont törlése. Csak nyitott (még nem lezárt) felmérésben engedélyezett.
  /// A forrás-hozzárendelések és az auditsorok a cascade miatt vele együtt törlődnek.
  Future<void> deleteMeasurementPoint(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT s.closed_at AS closed_at FROM measurement_points p '
        'JOIN survey_sessions s ON s.id = p.survey_session_id WHERE p.id = ?',
        [id],
      );
      if (rows.isEmpty) return;
      if (rows.first['closed_at'] != null) {
        throw StateError('Lezárt felmérés mérési pontja nem törölhető.');
      }
      await txn.delete('measurement_points', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ---------------------------------------------------------------------
  // Felmérés ↔ személy hozzárendelések
  // ---------------------------------------------------------------------

  Future<int> insertSessionPerson({
    required int surveySessionId,
    required int personId,
  }) async {
    final db = await database;
    return db.insert('survey_session_persons', {
      'survey_session_id': surveySessionId,
      'person_id': personId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// A felméréshez rendelt személyeket adja vissza, a globális
  /// személy-adatokkal összefésülve.
  Future<List<AttachedPerson>> getAttachedPersons(int surveySessionId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        sp.id AS link_id,
        sp.survey_session_id AS link_survey_session_id,
        sp.person_id AS link_person_id,
        sp.created_at AS link_created_at,
        sp.role AS link_role,
        sp.triage AS link_triage,
        p.id AS id,
        p.name AS name,
        p.medical_exam_expiry_date AS medical_exam_expiry_date,
        p.training_expiry_date AS training_expiry_date,
        p.notes AS notes,
        p.phone AS phone,
        p.emails AS emails,
        p.created_at AS created_at,
        p.updated_at AS updated_at
      FROM survey_session_persons sp
      INNER JOIN persons p ON p.id = sp.person_id
      WHERE sp.survey_session_id = ?
      ORDER BY sp.created_at ASC
    ''',
      [surveySessionId],
    );

    final certs = await _certificatesByPerson(db);
    return rows.map((row) {
      final link = SessionPersonLink(
        id: row['link_id'] as int,
        surveySessionId: row['link_survey_session_id'] as int,
        personId: row['link_person_id'] as int,
        createdAt: DateTime.parse(row['link_created_at'] as String),
        role: SessionPersonRole.fromDbValue(row['link_role'] as String?),
        triage: TriageCategory.fromDbValue(row['link_triage'] as String?),
      );
      return AttachedPerson(
        link: link,
        person: Person.fromMap(row)
            .copyWith(certificates: certs[row['id'] as int] ?? const []),
      );
    }).toList();
  }

  /// A felméréshez rendelt személy szerepét és triázs-besorolását menti.
  /// Felmérő szerephez a triázs nem tartozik.
  Future<void> updateSessionPersonStatus({
    required int linkId,
    required SessionPersonRole role,
    required TriageCategory? triage,
  }) async {
    final db = await database;
    await db.update(
      'survey_session_persons',
      {
        'role': role.dbValue,
        'triage': role == SessionPersonRole.victim ? triage?.dbValue : null,
      },
      where: 'id = ?',
      whereArgs: [linkId],
    );
  }

  /// A felmérés érintettjeinek sérülései és betegségei, hozzárendelés
  /// (link) azonosító szerint csoportosítva.
  Future<Map<int, List<PersonCondition>>> getPersonConditions(
    int surveySessionId,
  ) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.link_id, c.kind, c.description
      FROM session_person_conditions c
      INNER JOIN survey_session_persons sp ON sp.id = c.link_id
      WHERE sp.survey_session_id = ?
      ORDER BY c.id ASC
    ''', [surveySessionId]);
    final result = <int, List<PersonCondition>>{};
    for (final row in rows) {
      final c = PersonCondition.fromMap(row);
      result.putIfAbsent(c.linkId, () => []).add(c);
    }
    return result;
  }

  /// Egy hozzárendelés összes sérülését/betegségét a megadott listára cseréli.
  Future<void> replacePersonConditions(
    int linkId,
    List<PersonCondition> conditions,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'session_person_conditions',
        where: 'link_id = ?',
        whereArgs: [linkId],
      );
      for (final c in conditions) {
        await txn.insert('session_person_conditions', {
          'link_id': linkId,
          'kind': c.kind.dbValue,
          'description': c.description,
        });
      }
    });
  }

  // ---------------------------------------------------------------------
  // Térképi területjelölések
  // ---------------------------------------------------------------------

  Future<void> _createSurveyMapAreasTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS survey_map_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        survey_session_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        shape TEXT NOT NULL,
        geometry TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (survey_session_id) REFERENCES survey_sessions (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<List<MapArea>> getMapAreas(int surveySessionId) async {
    final db = await database;
    final rows = await db.query(
      'survey_map_areas',
      where: 'survey_session_id = ?',
      whereArgs: [surveySessionId],
      orderBy: 'id ASC',
    );
    return rows.map(MapArea.fromMap).toList();
  }

  Future<int> insertMapArea(MapArea area) async {
    final db = await database;
    return db.insert('survey_map_areas', area.toMap());
  }

  Future<void> deleteMapArea(int id) async {
    final db = await database;
    await db.delete('survey_map_areas', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Térképi mérővonalak
  // ---------------------------------------------------------------------

  Future<void> _createSurveyMapLinesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS survey_map_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        survey_session_id INTEGER NOT NULL,
        color INTEGER NOT NULL,
        geometry TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (survey_session_id) REFERENCES survey_sessions (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<List<MapMeasureLine>> getMapMeasureLines(int surveySessionId) async {
    final db = await database;
    final rows = await db.query(
      'survey_map_lines',
      where: 'survey_session_id = ?',
      whereArgs: [surveySessionId],
      orderBy: 'id ASC',
    );
    return rows.map(MapMeasureLine.fromMap).toList();
  }

  Future<int> insertMapMeasureLine(MapMeasureLine line) async {
    final db = await database;
    return db.insert('survey_map_lines', line.toMap());
  }

  Future<void> updateMapMeasureLineColor(int id, int colorArgb) async {
    final db = await database;
    await db.update(
      'survey_map_lines',
      {'color': colorArgb},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMapMeasureLine(int id) async {
    final db = await database;
    await db.delete('survey_map_lines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllMapMeasureLines(int surveySessionId) async {
    final db = await database;
    await db.delete(
      'survey_map_lines',
      where: 'survey_session_id = ?',
      whereArgs: [surveySessionId],
    );
  }

  Future<void> deleteSessionPerson(int linkId) async {
    final db = await database;
    await db.delete(
      'session_person_conditions',
      where: 'link_id = ?',
      whereArgs: [linkId],
    );
    await db.delete(
      'survey_session_persons',
      where: 'id = ?',
      whereArgs: [linkId],
    );
  }

  // ---------------------------------------------------------------------
  // Instruments
  // ---------------------------------------------------------------------

  Future<int> insertInstrument(Instrument instrument) async {
    final db = await database;
    final id = await db.insert('instruments', instrument.toMap()..remove('id'));
    onExpiryDataChanged?.call();
    return id;
  }

  Future<List<Instrument>> getInstruments() async {
    final db = await database;
    final rows = await db.query('instruments', orderBy: 'name ASC');
    return rows.map(Instrument.fromMap).toList();
  }

  Future<void> updateInstrument(Instrument instrument) async {
    final db = await database;
    await db.update(
      'instruments',
      instrument.toMap(),
      where: 'id = ?',
      whereArgs: [instrument.id],
    );
    onExpiryDataChanged?.call();
  }

  Future<List<InstrumentCalibration>> getCalibrations(int instrumentId) async {
    final db = await database;
    final rows = await db.query(
      'instrument_calibrations',
      where: 'instrument_id = ?',
      whereArgs: [instrumentId],
      orderBy: 'performed_on DESC',
    );
    return rows.map(InstrumentCalibration.fromMap).toList();
  }

  /// Egy műszer összes hitelesítési/kalibrálási bejegyzésének cseréje.
  Future<void> replaceCalibrations(
    int instrumentId,
    List<InstrumentCalibration> records,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'instrument_calibrations',
        where: 'instrument_id = ?',
        whereArgs: [instrumentId],
      );
      for (final r in records) {
        await txn.insert(
          'instrument_calibrations',
          r.copyWith(instrumentId: instrumentId).toMap()..remove('id'),
        );
      }
    });
    onExpiryDataChanged?.call();
  }

  /// Töröl egy műszert. A rá hivatkozó mérési pontok `instrument_id`-ja
  /// NULL-ra vált (lásd a séma ON DELETE SET NULL szabályát), a mérés maga
  /// megmarad.
  Future<void> deleteInstrument(int id) async {
    final db = await database;
    await db.delete('instruments', where: 'id = ?', whereArgs: [id]);
    onExpiryDataChanged?.call();
  }

  // ---------------------------------------------------------------------
  // Measurement points
  // ---------------------------------------------------------------------

  Future<int> insertMeasurementPoint(MeasurementPoint point) async {
    final db = await database;
    return db.insert('measurement_points', point.toMap()..remove('id'));
  }

  Future<List<MeasurementPoint>> getMeasurementPoints(
    int surveySessionId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'measurement_points',
      where: 'survey_session_id = ?',
      whereArgs: [surveySessionId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(MeasurementPoint.fromMap).toList();
  }

  /// Módosít egy mérési pontot, és minden ténylegesen változó mezőről
  /// audit-sort ír be — a régi érték soha nem vész el nyomtalanul.
  Future<void> updateMeasurementPoint(
    MeasurementPoint oldPoint,
    MeasurementPoint newPoint,
  ) async {
    final db = await database;
    final oldMap = oldPoint.toMap();
    final newMap = newPoint.toMap()
      ..['updated_at'] = DateTime.now().toIso8601String();

    final auditEntries = <MeasurementAuditEntry>[];
    final changedAt = DateTime.now();
    for (final key in newMap.keys) {
      if (key == 'id' || key == 'updated_at') continue;
      if (oldMap[key]?.toString() != newMap[key]?.toString()) {
        auditEntries.add(
          MeasurementAuditEntry(
            measurementPointId: oldPoint.id!,
            fieldName: key,
            oldValue: oldMap[key]?.toString(),
            newValue: newMap[key]?.toString(),
            changedAt: changedAt,
          ),
        );
      }
    }

    await db.transaction((txn) async {
      await txn.update(
        'measurement_points',
        newMap,
        where: 'id = ?',
        whereArgs: [oldPoint.id],
      );
      for (final entry in auditEntries) {
        await txn.insert('measurement_audit', entry.toMap()..remove('id'));
      }
    });
  }

  Future<List<MeasurementAuditEntry>> getAuditTrail(
    int measurementPointId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'measurement_audit',
      where: 'measurement_point_id = ?',
      whereArgs: [measurementPointId],
      orderBy: 'changed_at ASC',
    );
    return rows.map(MeasurementAuditEntry.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Radiation sources (globális nyilvántartás — a műszerekhez hasonlóan
  // egyszer felvéve, utána bármelyik ponthoz hozzárendelhető)
  // ---------------------------------------------------------------------

  Future<int> insertRadiationSource(RadiationSource source) async {
    final db = await database;
    final id = await db.insert(
      'radiation_sources',
      source.toMap()..remove('id'),
    );
    onExpiryDataChanged?.call();
    return id;
  }

  Future<List<RadiationSource>> getRadiationSources() async {
    final db = await database;
    final rows = await db.query('radiation_sources', orderBy: 'identifier ASC');
    return rows.map(RadiationSource.fromMap).toList();
  }

  Future<void> updateRadiationSource(RadiationSource source) async {
    final db = await database;
    await db.update(
      'radiation_sources',
      source.toMap(),
      where: 'id = ?',
      whereArgs: [source.id],
    );
    onExpiryDataChanged?.call();
  }

  /// Töröl egy forrást a nyilvántartásból. Minden ponthoz rendelt
  /// hozzárendelése is törlődik vele (ON DELETE CASCADE) — a mérési pontok
  /// maguk nem sérülnek.
  Future<void> deleteRadiationSource(int id) async {
    final db = await database;
    await db.delete('radiation_sources', where: 'id = ?', whereArgs: [id]);
    onExpiryDataChanged?.call();
  }

  // ---------------------------------------------------------------------
  // Mérési pont ↔ forrás hozzárendelések
  // ---------------------------------------------------------------------

  Future<int> insertPointSource({
    required int measurementPointId,
    required int radiationSourceId,
    required double distanceMeters,
  }) async {
    final db = await database;
    return db.insert('measurement_point_sources', {
      'measurement_point_id': measurementPointId,
      'radiation_source_id': radiationSourceId,
      'distance_meters': distanceMeters,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// A ponthoz rendelt forrásokat adja vissza, a globális forrás-adatokkal
  /// összefésülve.
  Future<List<AttachedSource>> getAttachedSources(
    int measurementPointId,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        mps.id AS link_id,
        mps.measurement_point_id AS link_measurement_point_id,
        mps.radiation_source_id AS link_radiation_source_id,
        mps.distance_meters AS link_distance_meters,
        mps.created_at AS link_created_at,
        rs.id AS id,
        rs.identifier AS identifier,
        rs.nuclide_name AS nuclide_name,
        rs.activity_at_manufacture_mbq AS activity_at_manufacture_mbq,
        rs.activity_error_percent AS activity_error_percent,
        rs.manufacture_date AS manufacture_date,
        rs.service_life_expiry_date AS service_life_expiry_date,
        rs.notes AS notes,
        rs.created_at AS created_at,
        rs.updated_at AS updated_at
      FROM measurement_point_sources mps
      INNER JOIN radiation_sources rs ON rs.id = mps.radiation_source_id
      WHERE mps.measurement_point_id = ?
      ORDER BY mps.created_at ASC
    ''',
      [measurementPointId],
    );

    return rows.map((row) {
      final link = PointSourceLink(
        id: row['link_id'] as int,
        measurementPointId: row['link_measurement_point_id'] as int,
        radiationSourceId: row['link_radiation_source_id'] as int,
        distanceMeters: (row['link_distance_meters'] as num).toDouble(),
        createdAt: DateTime.parse(row['link_created_at'] as String),
      );
      return AttachedSource(link: link, source: RadiationSource.fromMap(row));
    }).toList();
  }

  Future<void> updatePointSourceDistance(
    int linkId,
    double distanceMeters,
  ) async {
    final db = await database;
    await db.update(
      'measurement_point_sources',
      {'distance_meters': distanceMeters},
      where: 'id = ?',
      whereArgs: [linkId],
    );
  }

  Future<void> deletePointSource(int linkId) async {
    final db = await database;
    await db.delete(
      'measurement_point_sources',
      where: 'id = ?',
      whereArgs: [linkId],
    );
  }

  Future<void> close() async {
    // Ha épp nyitás folyik, megvárjuk, különben a lezárás után egy lezárt
    // példány maradna a `_dbOpening`-ben.
    if (_dbOpening != null) {
      try {
        await _dbOpening!.future;
      } catch (_) {}
    }
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
    // Enélkül az `database` getter a korábban befejezett (most már lezárt)
    // Future-t adná vissza az újranyitás helyett.
    _dbOpening = null;
  }
}
