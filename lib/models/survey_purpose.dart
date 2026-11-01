/// A felmérés célja. Meghatározza, milyen kiegészítő jegyzőkönyv-mezők
/// tartoznak a felméréshez. A cél nélküli (`null`) felmérés általános
/// jegyzőkönyvet kap.
enum SurveyPurpose {
  waste,
  environmental,
  accident,
  sampling,
  decommissioning;

  /// Az adatbázisban tárolt név (az enum-elem neve).
  static SurveyPurpose? fromStorage(String? value) {
    if (value == null) return null;
    for (final purpose in values) {
      if (purpose.name == value) return purpose;
    }
    return null;
  }
}
