// models/user.dart
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // "member" or "officer"
  final bool isAdmin; // derived from backend

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isAdmin,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    // Get role from JSON
    final role = (j['role']?.toString() ?? 'member').toLowerCase();

    // Get isAdmin from JSON, or derive it from role
    final isAdmin = j['isAdmin'] == true || role == 'officer' || role == 'admin';

    // Backend sends 'id' not '_id'
    final userId = j['id']?.toString() ?? j['_id']?.toString() ?? '';

    return AppUser(
      id: userId,
      name: j['name'] ?? '',
      email: j['email'] ?? '',
      role: role,
      isAdmin: isAdmin,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'isAdmin': isAdmin,
  };
}