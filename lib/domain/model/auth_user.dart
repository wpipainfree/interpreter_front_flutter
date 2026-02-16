class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.provider,
    this.linkedProviders = const [],
  });

  final String id;
  final String email;
  final String name;
  final String? provider;
  final List<String> linkedProviders;

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (email.contains('@')) return email.split('@').first;
    return email;
  }
}
