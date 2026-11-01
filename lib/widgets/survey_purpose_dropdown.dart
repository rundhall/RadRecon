import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../models/survey_purpose.dart';

/// A felmérés céljának választója. A `null` érték: nincs cél (általános
/// jegyzőkönyv).
class SurveyPurposeDropdown extends StatelessWidget {
  const SurveyPurposeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SurveyPurpose? value;
  final ValueChanged<SurveyPurpose?> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DropdownButtonFormField<SurveyPurpose?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: loc.surveyPurposeLabel),
      items: [
        DropdownMenuItem<SurveyPurpose?>(
          value: null,
          child: Text(
            loc.surveyPurposeGeneral,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final purpose in SurveyPurpose.values)
          DropdownMenuItem<SurveyPurpose?>(
            value: purpose,
            child: Text(
              purpose.localized(loc),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
