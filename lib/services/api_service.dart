
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  static Uri _u(String p,[Map<String,String>? q]) => Uri.parse('$baseUrl$p').replace(queryParameters: q);

  // Auth
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final resp = await http.post(_u('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Register failed ${resp.statusCode}: ${resp.body}');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await http.post(_u('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Login failed ${resp.statusCode}: ${resp.body}');
  }

  // Organization CRUD
  static Future<Map<String, dynamic>> fetchOrgByAdminEmail(String email) async {
    final resp = await http.get(_u('/org/by-admin', {'email': email}));
    if (resp.statusCode == 404) return {};
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Fetch org failed ${resp.statusCode}: ${resp.body}');
  }

  static Future<void> upsertOrg(Map<String, dynamic> payload) async {
    final resp = await http.post(_u('/org/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Save failed ${resp.statusCode}: ${resp.body}');
    }
  }

  static Future<void> deleteOrg(String id) async {
    final resp = await http.delete(_u('/org/$id'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Delete failed ${resp.statusCode}: ${resp.body}');
    }
  }
}
