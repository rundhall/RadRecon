/// A sugárzás típusa (dózisteljesítmény és beütésszám esetén).
enum RadiationKind {
  alpha('alpha'),
  beta('beta'),
  gamma('gamma'),
  neutron('neutron');

  const RadiationKind(this.dbValue);

  final String dbValue;

  /// Régi, megjelölés nélküli rekordok gamma-ként olvasódnak.
  static RadiationKind fromDbValue(String? value) => values.firstWhere(
        (k) => k.dbValue == value,
        orElse: () => RadiationKind.gamma,
      );
}
