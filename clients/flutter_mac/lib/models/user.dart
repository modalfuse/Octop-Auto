class User {
  const User({
    required this.id,
    required this.username,
    required this.role,
    required this.locale,
    this.displayName,
  });

  final int id;
  final String username;
  final String role;
  final String? displayName;
  final String locale;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      displayName: json['display_name'] as String?,
      locale: json['locale'] as String? ?? 'zh',
    );
  }
}
