import '../l10n/app_localizations.dart';
import 'instrument_calibration.dart';

String calibrationKindLabel(AppLocalizations loc, CalibrationKind k) =>
    k == CalibrationKind.verification
        ? loc.calibrationKindVerification
        : loc.calibrationKindCalibration;

String calibrationStatusLabel(AppLocalizations loc, CalibrationStatus s) {
  switch (s) {
    case CalibrationStatus.valid:
      return loc.calibrationStatusValid;
    case CalibrationStatus.expiringSoon:
      return loc.calibrationStatusSoon;
    case CalibrationStatus.expired:
      return loc.calibrationStatusExpired;
    case CalibrationStatus.unknown:
      return loc.calibrationStatusUnknown;
  }
}

String calibrationDateText(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.'
    '${d.day.toString().padLeft(2, '0')}';
