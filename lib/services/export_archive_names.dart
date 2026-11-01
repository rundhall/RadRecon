/// A mentés-zip neve: `<cégnév>_<ÉÉÉÉHHNN>_<ÓÓPP>.zip`. Ilyen nevű fájlt
/// csak a mentés hoz létre, ezért a takarítás ezt a mintát használja.
final RegExp _exportArchivePattern = RegExp(r'_\d{8}_\d{4}\.zip$');

/// Igaz, ha a fájlnév egy korábbi mentés neve.
bool isExportArchiveName(String fileName) =>
    _exportArchivePattern.hasMatch(fileName);
