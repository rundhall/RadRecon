/// Közreműködő személy vagy szervezet a köszönetnyilvánító listában.
class Contributor {
  final String name;
  final String? organization;
  final List<String> roles;

  const Contributor({
    required this.name,
    this.organization,
    this.roles = const [],
  });

  /// Hibás vagy névtelen elem esetén `null`-t ad.
  static Contributor? tryParse(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final org = json['organization'];
    final roles = json['roles'];
    return Contributor(
      name: name.trim(),
      organization:
          (org is String && org.trim().isNotEmpty) ? org.trim() : null,
      roles: roles is List ? roles.whereType<String>().toList() : const [],
    );
  }
}

/// A `landingpage/contributors.json` tartalma. A weboldal és az app ugyanazt
/// a fájlt használja, ezért a feldolgozás hibatűrő: a rossz elemek kimaradnak.
class ContributorList {
  final List<Contributor> organizations;
  final List<Contributor> people;

  const ContributorList({
    this.organizations = const [],
    this.people = const [],
  });

  bool get isEmpty => organizations.isEmpty && people.isEmpty;

  factory ContributorList.fromJson(Object? json) {
    if (json is! Map) return const ContributorList();
    List<Contributor> parse(Object? list) => list is List
        ? list.map(Contributor.tryParse).whereType<Contributor>().toList()
        : const [];
    return ContributorList(
      organizations: parse(json['organizations']),
      people: parse(json['people']),
    );
  }
}
