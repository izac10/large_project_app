import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  static Uri _u(String p, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$p').replace(queryParameters: q);

  // ==================== AUTH ====================

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

  // ==================== ORGANIZATIONS/CLUBS ====================

  /// Fetch ALL clubs/organizations
  static Future<List<Map<String, dynamic>>> fetchAllOrgs() async {
    final resp = await http.get(_u('/org/all'));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final List<dynamic> list = jsonDecode(resp.body);
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Fetch all orgs failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch a specific club by ID
  static Future<Map<String, dynamic>> fetchOrgById(String id) async {
    final resp = await http.get(_u('/org/$id'));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Fetch org failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch the club/organization that this admin/officer manages
  static Future<Map<String, dynamic>?> fetchOrgByAdminEmail(String email) async {
    final resp = await http.get(_u('/org/by-admin', {'email': email}));
    if (resp.statusCode == 404) return null;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Fetch org failed ${resp.statusCode}: ${resp.body}');
  }

  /// Create or update a club/organization
  static Future<Map<String, dynamic>> upsertOrg(Map<String, dynamic> payload) async {
    final resp = await http.post(_u('/org/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Save failed ${resp.statusCode}: ${resp.body}');
  }

  /// Delete a club/organization by ID
  static Future<void> deleteOrg(String id) async {
    final resp = await http.delete(_u('/org/$id'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Delete failed ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Join a club (add user to members list)
  static Future<Map<String, dynamic>> joinOrg(String clubId, String userId) async {
    final resp = await http.post(_u('/org/$clubId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Join failed ${resp.statusCode}: ${resp.body}');
  }

  /// Leave a club (remove user from members list)
  static Future<Map<String, dynamic>> leaveOrg(String clubId, String userId) async {
    final resp = await http.post(_u('/org/$clubId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Leave failed ${resp.statusCode}: ${resp.body}');
  }

  // ==================== EVENTS ====================

  /// Fetch ALL events
  static Future<List<Map<String, dynamic>>> fetchAllEvents() async {
    final resp = await http.get(_u('/event/all'));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final List<dynamic> list = jsonDecode(resp.body);
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Fetch all events failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch a specific event by ID
  static Future<Map<String, dynamic>> fetchEventById(String id) async {
    final resp = await http.get(_u('/event/$id'));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Fetch event failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch events created by a specific officer (by email)
  static Future<List<Map<String, dynamic>>> fetchEventsByAdminEmail(String email) async {
    final resp = await http.get(_u('/event/by-admin', {'email': email}));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final List<dynamic> list = jsonDecode(resp.body);
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Fetch events failed ${resp.statusCode}: ${resp.body}');
  }

  /// Create or update an event
  static Future<Map<String, dynamic>> upsertEvent(Map<String, dynamic> payload) async {
    final resp = await http.post(_u('/event/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Save event failed ${resp.statusCode}: ${resp.body}');
  }

  /// Delete an event by ID
  static Future<void> deleteEvent(String id) async {
    final resp = await http.delete(_u('/event/$id'));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Delete event failed ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Join an event (add user to attendees list)
  static Future<Map<String, dynamic>> joinEvent(String eventId, String userId) async {
    final resp = await http.post(_u('/event/$eventId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Join event failed ${resp.statusCode}: ${resp.body}');
  }

  /// Leave an event (remove user from attendees list)
  static Future<Map<String, dynamic>> leaveEvent(String eventId, String userId) async {
    final resp = await http.post(_u('/event/$eventId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Leave event failed ${resp.statusCode}: ${resp.body}');
  }
}