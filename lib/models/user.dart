// models/user.dart
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // "member" or "officer"

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['_id']?.toString() ?? j['id'],
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    role: j['role'] ?? 'member',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };
}
