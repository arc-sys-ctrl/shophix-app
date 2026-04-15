class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final String authMethod; // 'email' | 'google' | 'apple'

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'customer',
    this.avatarUrl,
    this.authMethod = 'email',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      authMethod: json['auth_method'] ?? json['authMethod'] ?? 'email',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'auth_method': authMethod,
    };
  }
}
