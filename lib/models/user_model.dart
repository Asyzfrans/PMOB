// lib/models/user_model.dart

enum UserRole { admin, fundraiser, donatur }

class UserSession {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;

  const UserSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    id:       (json['id'] as int?) ?? 0,
    name:     json['name']  as String? ?? '',
    email:    json['email'] as String? ?? '',
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.donatur,
    ),
    photoUrl: json['photo_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id':        id,
    'name':      name,
    'email':     email,
    'role':      role.name,
    'photo_url': photoUrl,
  };

  String get initial   => name.isNotEmpty ? name[0].toUpperCase() : '?';
  String get roleLabel => role.name[0].toUpperCase() + role.name.substring(1);

  @override
  String toString() => 'UserSession($id, $name, ${role.name})';
}
