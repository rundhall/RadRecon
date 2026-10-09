import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'expiry_notification_service.dart';

/// Egy mentett adatbázis ("cég") a cégek mappájában.
///
/// A [location] helyi fájl útvonala, vagy Androidon SAF `content://` cím —
/// a tartalmát mindig a [DatabaseTransferService] olvassa/írja.
class CompanyBackup {
  CompanyBackup({
    required this.location,
    required this.companyName,
    required this.modified,
  });

  final String location;
  final String companyName;
  final DateTime modified;
}

/// A cégek mentéseinek tárolója: helyi mappa vagy Android SAF mappa.
abstract class _CompanyStore {
  /// A felhasználónak megjelenített mappa-név / útvonal.
  String get description;
  Future<List<CompanyBackup>> list();
  Future<Uint8List> read(String location);
  Future<void> write(String fileName, Uint8List bytes);
  Future<void> delete(String location);
}

bool _isZipName(String name) => name.toLowerCase().endsWith('.zip');
String _companyFromFileName(String name) =>
    name.substring(0, name.length - 4); // ".zip" levágása

class _LocalStore implements _CompanyStore {
  _LocalStore(this.dir);
  final Directory dir;

  @override
  String get description => dir.path;

  @override
  Future<List<CompanyBackup>> list() async {
    if (!await dir.exists()) await dir.create(recursive: true);
    final result = <CompanyBackup>[];
    await for (final e in dir.list()) {
      if (e is! File || !_isZipName(p.basename(e.path))) continue;
      result.add(CompanyBackup(
        location: e.path,
        companyName: _companyFromFileName(p.basename(e.path)),
        modified: await e.lastModified(),
      ));
    }
    return result;
  }

  @override
  Future<Uint8List> read(String location) => File(location).readAsBytes();

  @override
  Future<void> write(String fileName, Uint8List bytes) async {
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(p.join(dir.path, fileName)).writeAsBytes(bytes);
  }

  @override
  Future<void> delete(String location) async {
    final f = File(location);
    if (await f.exists()) await f.delete();
  }
}

class _SafStore implements _CompanyStore {
  _SafStore(this.treeUri, this.folderName);
  final String treeUri;
  final String folderName;
  final _util = SafUtil();
  final _stream = SafStream();

  @override
  String get description => folderName;

  @override
  Future<List<CompanyBackup>> list() async {
    final entries = await _util.list(treeUri);
    return [
      for (final e in entries)
        if (!e.isDir && _isZipName(e.name))
          CompanyBackup(
            location: e.uri,
            companyName: _companyFromFileName(e.name),
            modified: DateTime.fromMillisecondsSinceEpoch(e.lastModified),
          ),
    ];
  }

  @override
  Future<Uint8List> read(String location) => _stream.readFileBytes(location);

  @override
  Future<void> write(String fileName, Uint8List bytes) async {
    await _stream.writeFileBytes(
      treeUri,
      fileName,
      'application/zip',
      bytes,
      overwrite: true,
    );
  }

  @override
  Future<void> delete(String location) => _util.delete(location, false);
}

/// Az adatbázis teljes mentése fájlba, visszatöltése fájlból, törlése, és
/// a "cégek" (több különálló adatbázis) közötti váltás.
///
/// Egy mentésfájl egy zip: `manifest.json` + `rad_recon.db` + `photos/` +
/// `screenshots/`. A fotók és a képernyőképek azért kerülnek bele, mert az
/// adatbázis csak a fájl útvonalát tárolja — a puszta .db fájl új telefonra
/// átmásolva a képek nélkül maradna.
class DatabaseTransferService {
  DatabaseTransferService._();
  static final DatabaseTransferService instance = DatabaseTransferService._();

  static const _manifestName = 'manifest.json';
  static const _dbEntryName = 'rad_recon.db';
  static const _photosPrefix = 'photos/';
  static const _screenshotsPrefix = 'screenshots/';
  static const _screenshotsDirName = 'rad_recon_screenshots';
  static const _restoredPhotosDirName = 'rad_recon_photos';
  static const _photoPathMarker = 'photos/';

  static const _activeCompanyKey = 'active_company_name';
  static const _folderPathKey = 'companies_folder_path';
  static const _safUriKey = 'companies_folder_saf_uri';
  static const _safNameKey = 'companies_folder_saf_name';
  static const defaultCompanyName = 'Default';

  static bool get isAndroid => Platform.isAndroid;
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Androidon (SAF mappaválasztó) és desktopon a felhasználó maga
  /// választhatja ki a cégek mappáját. iOS-en az app Documents mappája a
  /// Fájlok appból közvetlenül elérhető, ezért ott nincs szükség választóra.
  static bool get supportsFolderPicking => isAndroid || isDesktop;

  // ---------------------------------------------------------------- cégek

  /// A cégnévből fájlnév-biztos név. A cég azonosítója ez a név: a mentés
  /// fájlneve `<név>.zip`, és a listában is ez jelenik meg.
  static String sanitizeName(String name) {
    final cleaned =
        name.replaceAll(RegExp(r'[^\w\-. ]', unicode: true), '_').trim();
    return cleaned.isEmpty ? 'company' : cleaned;
  }

  Future<String> getActiveCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeCompanyKey) ?? defaultCompanyName;
  }

  Future<void> _setActiveCompanyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeCompanyKey, sanitizeName(name));
  }

  Future<_CompanyStore> _store() async {
    final prefs = await SharedPreferences.getInstance();

    final safUri = prefs.getString(_safUriKey);
    if (safUri != null && safUri.isNotEmpty && isAndroid) {
      // A tartós jogosultság elveszhet (pl. a mappa törlése, jogosultság
      // visszavonása) — ilyenkor az alapértelmezett mappára esünk vissza.
      final ok = await SafUtil()
          .hasPersistedPermission(safUri, checkRead: true, checkWrite: true);
      if (ok) {
        return _SafStore(safUri, prefs.getString(_safNameKey) ?? safUri);
      }
      await prefs.remove(_safUriKey);
      await prefs.remove(_safNameKey);
    }

    final custom = prefs.getString(_folderPathKey);
    if (custom != null && custom.isNotEmpty && isDesktop) {
      return _LocalStore(Directory(custom));
    }

    final docs = await getApplicationDocumentsDirectory();
    return _LocalStore(Directory(p.join(docs.path, 'rad_recon_companies')));
  }

  /// A cégek mappájának megjelenítendő neve / útvonala.
  Future<String> getFolderDescription() async => (await _store()).description;

  Future<bool> isUsingCustomFolder() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_safUriKey) ?? '').isNotEmpty ||
        (prefs.getString(_folderPathKey) ?? '').isNotEmpty;
  }

  /// Mappaválasztó a platformnak megfelelően. `true`, ha a felhasználó
  /// kiválasztott egy mappát.
  Future<bool> pickCompaniesFolder() async {
    final prefs = await SharedPreferences.getInstance();
    if (isAndroid) {
      final dir = await SafUtil().pickDirectory(
        writePermission: true,
        persistablePermission: true,
      );
      if (dir == null) return false;
      await prefs.setString(_safUriKey, dir.uri);
      await prefs.setString(_safNameKey, dir.name);
      await prefs.remove(_folderPathKey);
      return true;
    }
    if (isDesktop) {
      final path = await fs.getDirectoryPath();
      if (path == null) return false;
      await prefs.setString(_folderPathKey, path);
      await prefs.remove(_safUriKey);
      await prefs.remove(_safNameKey);
      return true;
    }
    return false;
  }

  /// Vissza az alapértelmezett (app saját) mappához.
  Future<void> resetCompaniesFolder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_folderPathKey);
    await prefs.remove(_safUriKey);
    await prefs.remove(_safNameKey);
  }

  /// A mappában lévő összes mentés, cégnév szerint rendezve.
  Future<List<CompanyBackup>> listCompanies() async {
    final result = await (await _store()).list();
    result.sort((a, b) =>
        a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
    return result;
  }

  /// Az aktuális adatbázis elmentése a cégek mappájába az aktív cég nevén
  /// (felülírja az előző mentést).
  Future<void> saveActiveCompany() async {
    final name = await getActiveCompanyName();
    final store = await _store();
    final tmpFile = await exportToFile(companyName: name);
    try {
      await store.write(
        '${sanitizeName(name)}.zip',
        await tmpFile.readAsBytes(),
      );
    } finally {
      if (await tmpFile.exists()) await tmpFile.delete();
    }
  }

  /// Váltás másik cégre: az aktuális állapot automatikusan visszamentődik
  /// az aktív cég fájljába, aztán betöltődik a kiválasztott.
  Future<void> switchToCompany(CompanyBackup target) async {
    final store = await _store();
    // A célfájlt még a mentés előtt beolvassuk: ha ugyanabba a mappába
    // mentünk, ne írjuk felül azt, amit be akarunk tölteni.
    final bytes = await store.read(target.location);
    await saveActiveCompany();
    await _importBytesAs(bytes);
    await _setActiveCompanyName(target.companyName);
  }

  /// Új, üres cég létrehozása: az aktuális állapot mentése, majd üres
  /// adatbázis az új néven.
  Future<void> createCompany(String name) async {
    await saveActiveCompany();
    await clearDatabase();
    await _setActiveCompanyName(name);
    await saveActiveCompany();
  }

  /// A cég mentésfájljának törlése a mappából (az aktív adatbázist nem érinti).
  Future<void> deleteCompanyBackup(CompanyBackup backup) async =>
      (await _store()).delete(backup.location);

  /// Egy kívülről kapott mentésfájl bemásolása a cégek mappájába (az aktív
  /// adatbázis érintetlen marad). A cégnév a mentésfájl manifestjéből jön.
  Future<void> addToCompaniesFolder(Uint8List bytes) async {
    final info = _infoFromArchive(ZipDecoder().decodeBytes(bytes));
    await (await _store()).write('${sanitizeName(info.name)}.zip', bytes);
  }

  // --------------------------------------------------------------- export

  /// Az adatbázis (+ fotók) zipbe csomagolása az app dokumentum-mappájába
  /// (megosztáshoz / mentéshez).
  Future<File> exportToFile({required String companyName}) async {
    final helper = DatabaseHelper.instance;
    // A fájl-másolás előtt a DB-t le kell zárni, hogy a teljes, konzisztens
    // állapot kerüljön a fájlba. A következő `database` hívás újranyitja.
    final dbPath = await helper.databaseFilePath();
    // Ha a fájl még nem létezik (friss telepítés, vagy épp törölt adatbázis),
    // a megnyitás létrehozza az üres, de érvényes sémájú adatbázist.
    await helper.database;
    await helper.close();

    final tmp = await getTemporaryDirectory();
    final workCopy = File(p.join(tmp.path, 'rad_recon_export.db'));
    if (await workCopy.exists()) await workCopy.delete();
    await File(dbPath).copy(workCopy.path);

    // A munkapéldányban a fotó-útvonalakat zip-relatív jelölőre cseréljük.
    final photoEntries = <String, File>{};
    final copyDb = await openDatabase(workCopy.path);
    try {
      final rows = await copyDb.query(
        'measurement_points',
        columns: ['id', 'photo_path'],
        where: 'photo_path IS NOT NULL',
      );
      for (final row in rows) {
        final path = row['photo_path'] as String?;
        if (path == null || path.isEmpty) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final entryName = '${row['id']}_${p.basename(path)}';
        photoEntries[entryName] = file;
        await copyDb.update(
          'measurement_points',
          {'photo_path': '$_photoPathMarker$entryName'},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    } finally {
      await copyDb.close();
    }

    final archive = Archive();
    final dbBytes = await workCopy.readAsBytes();
    archive.addFile(ArchiveFile(_dbEntryName, dbBytes.length, dbBytes));
    for (final e in photoEntries.entries) {
      final bytes = await e.value.readAsBytes();
      archive.addFile(
        ArchiveFile('$_photosPrefix${e.key}', bytes.length, bytes),
      );
    }

    final docs = await getApplicationDocumentsDirectory();
    final screenshotsDir = Directory(p.join(docs.path, _screenshotsDirName));
    if (await screenshotsDir.exists()) {
      await for (final entity in screenshotsDir.list(recursive: true)) {
        if (entity is! File) continue;
        final rel = p
            .relative(entity.path, from: screenshotsDir.path)
            .replaceAll(r'\', '/');
        final bytes = await entity.readAsBytes();
        archive.addFile(
          ArchiveFile('$_screenshotsPrefix$rel', bytes.length, bytes),
        );
      }
    }

    final manifest = utf8.encode(jsonEncode({
      'format': 'radrecon-backup',
      'companyName': companyName,
      'createdAt': DateTime.now().toIso8601String(),
      'schemaVersion': await _readUserVersion(workCopy.path),
      'photoCount': photoEntries.length,
    }));
    archive.addFile(ArchiveFile(_manifestName, manifest.length, manifest));

    final encoded = ZipEncoder().encode(archive);
    await workCopy.delete();
    if (encoded == null) {
      throw StateError('Could not create the backup ZIP file.');
    }

    final out = File(p.join(
      docs.path,
      '${sanitizeName(companyName)}_${_dateStamp()}.zip',
    ));
    await out.writeAsBytes(encoded);
    return out;
  }

  // --------------------------------------------------------------- import

  ({String name, int schemaVersion}) _infoFromArchive(Archive archive) {
    final manifestFile = archive.findFile(_manifestName);
    if (manifestFile == null || archive.findFile(_dbEntryName) == null) {
      throw const FormatException('Not a RadRecon backup file');
    }
    final map = jsonDecode(utf8.decode(manifestFile.content as List<int>))
        as Map<String, dynamic>;
    if (map['format'] != 'radrecon-backup') {
      throw const FormatException('Not a RadRecon backup file');
    }
    return (
      name: (map['companyName'] as String?) ?? defaultCompanyName,
      schemaVersion: (map['schemaVersion'] as int?) ?? 0,
    );
  }

  /// Mentésfájl bájtjainak betöltése (a fájlválasztóból kapott adat); az
  /// aktív cég a mentésben szereplő név lesz. Visszaadja a cég nevét.
  Future<String> importFromBytes(Uint8List bytes) async {
    final name = await _importBytesAs(bytes);
    await _setActiveCompanyName(name);
    return sanitizeName(name);
  }

  /// A jelenlegi adatbázis FELÜLÍRÁSA a mentés tartalmával. Visszaadja a
  /// mentésben tárolt cégnevet.
  Future<String> _importBytesAs(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final info = _infoFromArchive(archive);
    if (info.schemaVersion > DatabaseHelper.schemaVersion) {
      throw FormatException(
        'The backup was made by a newer app version '
        '(schema ${info.schemaVersion} > ${DatabaseHelper.schemaVersion}). '
        'Update the app first.',
      );
    }

    final helper = DatabaseHelper.instance;
    final dbPath = await helper.databaseFilePath();
    await helper.close();

    final dbBytes = archive.findFile(_dbEntryName)!.content as List<int>;

    await _deleteDbFiles(dbPath);
    await File(dbPath).writeAsBytes(dbBytes);

    final docs = await getApplicationDocumentsDirectory();

    // Fotók: új, saját mappába, és az útvonalak átírása.
    final photosDir = Directory(p.join(docs.path, _restoredPhotosDirName));
    if (await photosDir.exists()) await photosDir.delete(recursive: true);
    await photosDir.create(recursive: true);
    for (final entry in archive.files) {
      if (!entry.isFile || !entry.name.startsWith(_photosPrefix)) continue;
      final name = p.basename(entry.name);
      await File(p.join(photosDir.path, name))
          .writeAsBytes(entry.content as List<int>);
    }
    final db = await openDatabase(dbPath);
    try {
      final rows = await db.query(
        'measurement_points',
        columns: ['id', 'photo_path'],
        where: 'photo_path IS NOT NULL',
      );
      for (final row in rows) {
        final path = row['photo_path'] as String?;
        if (path == null || !path.startsWith(_photoPathMarker)) continue;
        final restored = p.join(photosDir.path, p.basename(path));
        await db.update(
          'measurement_points',
          {'photo_path': await File(restored).exists() ? restored : null},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    } finally {
      await db.close();
    }

    // Képernyőképek.
    final screenshotsDir = Directory(p.join(docs.path, _screenshotsDirName));
    if (await screenshotsDir.exists()) {
      await screenshotsDir.delete(recursive: true);
    }
    for (final entry in archive.files) {
      if (!entry.isFile || !entry.name.startsWith(_screenshotsPrefix)) continue;
      final rel = entry.name.substring(_screenshotsPrefix.length);
      final out = File(p.joinAll([screenshotsDir.path, ...rel.split('/')]));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(entry.content as List<int>);
    }

    await _afterDataReplaced();
    return info.name;
  }

  // ---------------------------------------------------------------- törlés

  /// Az összes adat törlése (adatbázis, fotók, képernyőképek). A beállítások
  /// (téma, nyelv, küszöbértékek) megmaradnak.
  Future<void> clearDatabase() async {
    final helper = DatabaseHelper.instance;
    final dbPath = await helper.databaseFilePath();
    await helper.close();
    await _deleteDbFiles(dbPath);

    final docs = await getApplicationDocumentsDirectory();
    for (final name in [_restoredPhotosDirName, _screenshotsDirName]) {
      final dir = Directory(p.join(docs.path, name));
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    await _afterDataReplaced();
  }

  // ----------------------------------------------------------- segédek

  Future<void> _afterDataReplaced() async {
    try {
      await ExpiryNotificationService.instance.rescheduleAll();
    } catch (_) {
      // az értesítések hibája ne buktassa el az importot
    }
  }

  Future<void> _deleteDbFiles(String dbPath) async {
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final f = File('$dbPath$suffix');
      if (await f.exists()) await f.delete();
    }
  }

  Future<int> _readUserVersion(String dbPath) async {
    final db = await openDatabase(dbPath, readOnly: true);
    try {
      final r = await db.rawQuery('PRAGMA user_version');
      return (r.first.values.first as int?) ?? 0;
    } finally {
      await db.close();
    }
  }

  String _dateStamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}';
  }
}
