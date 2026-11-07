import 'field_set_store.dart';

/// A személylista soraiban megjeleníthető adatcsoportok.
enum PersonListField {
  expiry,
  certificates,
  contact,
  identifier,
  address,
  physical,
  notes,
  injuries,
  lastStatus,
  annualDose,
  doseBreakdown,
  limit,
}

/// Alapértelmezetten a név mellett ezek látszanak.
const kDefaultPersonListFields = <PersonListField>{
  PersonListField.annualDose,
  PersonListField.limit,
};

/// A személylista mezőbeállításainak mentése (ezen az eszközön).
final personListFieldsStore = FieldSetStore<PersonListField>(
  key: 'person_list_fields',
  values: PersonListField.values,
  defaults: kDefaultPersonListFields,
);
