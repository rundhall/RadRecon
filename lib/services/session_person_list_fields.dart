import 'field_set_store.dart';

/// A felmérés-összerendelés ablakában a személy sorában megjeleníthető adatok.
enum SessionPersonListField {
  role,
  triage,
  injuries,
  expiry,
  certificates,
  contact,
  identifier,
  address,
  physical,
  notes,
  doseTotal,
  doseBreakdown,
}

/// Alapértelmezetten a név mellett ezek látszanak.
const kDefaultSessionPersonListFields = <SessionPersonListField>{
  SessionPersonListField.role,
  SessionPersonListField.triage,
  SessionPersonListField.doseTotal,
};

/// Az összerendelés-ablak mezőbeállításainak mentése (ezen az eszközön).
final sessionPersonListFieldsStore = FieldSetStore<SessionPersonListField>(
  key: 'session_person_list_fields',
  values: SessionPersonListField.values,
  defaults: kDefaultSessionPersonListFields,
);
