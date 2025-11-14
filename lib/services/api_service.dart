// services/api_service.dart - UPDATED FOR DIGITALOCEAN BACKEND
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔥 DigitalOcean droplet URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://178.128.188.181:5000',
  );

  static Uri _u(String p, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$p').replace(queryParameters: q);

  // Store JWT token
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void clearAuthToken() {
    _authToken = null;
  }

  // Helper to add auth headers
  static Map<String, String> _headers({bool needsAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (needsAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ==================== AUTH ====================

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final resp = await http.post(
      _u('/api/auth/signup'), // Backend uses /signup not /register
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['token'] != null) {
        setAuthToken(data['token']);
      }
      return data;
    }

    // Parse error message from backend
    try {
      final errorData = jsonDecode(resp.body);
      throw Exception(errorData['error'] ?? 'Register failed ${resp.statusCode}');
    } catch (e) {
      throw Exception('Register failed ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await http.post(
      _u('/api/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['token'] != null) {
        setAuthToken(data['token']);
      }
      return data;
    }

    // Parse error message from backend
    try {
      final errorData = jsonDecode(resp.body);
      throw Exception(errorData['error'] ?? 'Login failed ${resp.statusCode}');
    } catch (e) {
      throw Exception('Login failed ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Get current user info
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final resp = await http.post(
      _u('/api/auth/me'),
      headers: _headers(needsAuth: true),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Get user failed ${resp.statusCode}: ${resp.body}');
  }

  /// Verify email with code
  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final resp = await http.post(
      _u('/api/auth/verify'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data;
    }

    // Parse error message from backend
    try {
      final errorData = jsonDecode(resp.body);
      throw Exception(errorData['error'] ?? 'Email verification failed');
    } catch (e) {
      throw Exception('Email verification failed ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Resend verification code
  static Future<void> resendVerificationCode(String email) async {
    final resp = await http.post(
      _u('/api/auth/resend-verification'),
      headers: _headers(),
      body: jsonEncode({'email': email}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return;
    }
    throw Exception('Resend verification failed ${resp.statusCode}: ${resp.body}');
  }

  /// Send password reset code
  static Future<void> sendPasswordResetCode(String email) async {
    // Note: Implement this in your backend if needed
    throw UnimplementedError('Password reset not available in backend yet');
  }

  /// Verify reset code
  static Future<bool> verifyResetCode(String email, String code) async {
    throw UnimplementedError('Password reset not available in backend yet');
  }

  /// Reset password
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    throw UnimplementedError('Password reset not available in backend yet');
  }

  // ==================== ORGANIZATIONS/CLUBS ====================

  /// Fetch ALL organizations
  static Future<List<Map<String, dynamic>>> fetchAllOrgs() async {
    final resp = await http.get(_u('/api/orgs'));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic> list = data['orgs'] ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Fetch all orgs failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch organization by ID
  static Future<Map<String, dynamic>> fetchOrgById(String id) async {
    // Backend uses names, so fetch all and find by ID
    final allOrgs = await fetchAllOrgs();
    final org = allOrgs.firstWhere(
          (o) => o['_id'].toString() == id,
      orElse: () => throw Exception('Organization not found'),
    );
    return org;
  }

  /// Fetch organization by name
  static Future<Map<String, dynamic>> fetchOrgByName(String name) async {
    final encodedName = Uri.encodeComponent(name);
    final resp = await http.get(_u('/api/orgs/$encodedName'));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['organization'] ?? {};
    }
    throw Exception('Fetch org failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch organization by admin email (for officers)
  static Future<Map<String, dynamic>?> fetchOrgByAdminEmail(String email) async {
    try {
      // Get current user's organizations
      final resp = await http.get(
        _u('/api/orgs/my-org'),
        headers: _headers(needsAuth: true),
      );

      if (resp.statusCode == 404) return null;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['organization'];
      }

      return null;
    } catch (e) {
      print('Error fetching org by admin email: $e');
      return null;
    }
  }

  /// Create or update an organization
  static Future<Map<String, dynamic>> upsertOrg(Map<String, dynamic> payload) async {
    final hasId = payload.containsKey('_id');
    final hasName = payload.containsKey('name') || payload.containsKey('title');

    if (hasId || hasName) {
      // UPDATE existing org
      final name = Uri.encodeComponent(payload['name'] ?? payload['title']);
      final resp = await http.patch(
        _u('/api/orgs/$name'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({
          'description': payload['description'],
          'category': payload['category'],
          'logo': payload['imageUrl'],
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['organization'] ?? {};
      }
      throw Exception('Update org failed ${resp.statusCode}: ${resp.body}');
    } else {
      // CREATE new org
      final resp = await http.post(
        _u('/api/orgs'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({
          'name': payload['title'] ?? payload['name'],
          'description': payload['description'],
          'category': payload['category'],
          'logo': payload['imageUrl'],
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['organization'] ?? {};
      }
      throw Exception('Create org failed ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Delete organization
  static Future<void> deleteOrg(String idOrName) async {
    // Try to get org first to find its name
    try {
      final org = await fetchOrgById(idOrName);
      final name = Uri.encodeComponent(org['name'] ?? idOrName);

      final resp = await http.delete(
        _u('/api/orgs/$name'),
        headers: _headers(needsAuth: true),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Delete failed ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      // If not found by ID, try as name directly
      final encodedName = Uri.encodeComponent(idOrName);
      final resp = await http.delete(
        _u('/api/orgs/$encodedName'),
        headers: _headers(needsAuth: true),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Delete failed ${resp.statusCode}: ${resp.body}');
      }
    }
  }

  /// Join an organization
  static Future<Map<String, dynamic>> joinOrg(String orgIdOrName, String userId) async {
    try {
      // Try to get org name from ID
      String orgName = orgIdOrName;
      try {
        final org = await fetchOrgById(orgIdOrName);
        orgName = org['name'] ?? orgIdOrName;
      } catch (e) {
        // If fetch fails, assume it's already a name
      }

      final encodedName = Uri.encodeComponent(orgName);
      final resp = await http.post(
        _u('/api/orgs/$encodedName/join'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {'success': true, 'club': data['organization'] ?? {}};
      }
      throw Exception('Join failed ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      throw Exception('Join failed: $e');
    }
  }

  /// Leave an organization
  static Future<Map<String, dynamic>> leaveOrg(String orgIdOrName, String userId) async {
    try {
      // Try to get org name from ID
      String orgName = orgIdOrName;
      try {
        final org = await fetchOrgById(orgIdOrName);
        orgName = org['name'] ?? orgIdOrName;
      } catch (e) {
        // If fetch fails, assume it's already a name
      }

      final encodedName = Uri.encodeComponent(orgName);
      final resp = await http.post(
        _u('/api/orgs/$encodedName/leave'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {'success': true, 'club': data['organization'] ?? {}};
      }
      throw Exception('Leave failed ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      throw Exception('Leave failed: $e');
    }
  }

  // ==================== EVENTS ====================

  /// Fetch ALL events
  static Future<List<Map<String, dynamic>>> fetchAllEvents() async {
    final resp = await http.get(_u('/api/events'));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic> list = data['events'] ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Fetch all events failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch event by ID
  static Future<Map<String, dynamic>> fetchEventById(String id) async {
    // Backend uses names, so fetch all and find by ID
    final allEvents = await fetchAllEvents();
    final event = allEvents.firstWhere(
          (e) => e['_id'].toString() == id,
      orElse: () => throw Exception('Event not found'),
    );
    return event;
  }

  /// Fetch event by name
  static Future<Map<String, dynamic>> fetchEventByName(String name) async {
    final encodedName = Uri.encodeComponent(name);
    final resp = await http.get(_u('/api/events/$encodedName'));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['event'] ?? {};
    }
    throw Exception('Fetch event failed ${resp.statusCode}: ${resp.body}');
  }

  /// Fetch events by admin email
  static Future<List<Map<String, dynamic>>> fetchEventsByAdminEmail(String email) async {
    try {
      final resp = await http.get(
        _u('/api/events/my-events'),
        headers: _headers(needsAuth: true),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final List<dynamic> list = data['events'] ?? [];
        return list.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('Error fetching events by admin email: $e');
      return [];
    }
  }

  /// Create or update an event
  static Future<Map<String, dynamic>> upsertEvent(Map<String, dynamic> payload) async {
    final hasId = payload.containsKey('_id');
    final hasName = payload.containsKey('name') || payload.containsKey('title');

    if (hasId || hasName) {
      // UPDATE
      final name = Uri.encodeComponent(payload['name'] ?? payload['title']);
      final resp = await http.patch(
        _u('/api/events/$name'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({
          'description': payload['description'],
          'date': payload['dateTime'],
          'location': payload['location'],
          'category': payload['category'],
          'logo': payload['imageUrl'],
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['event'] ?? {};
      }
      throw Exception('Update event failed ${resp.statusCode}: ${resp.body}');
    } else {
      // CREATE
      final resp = await http.post(
        _u('/api/events'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({
          'name': payload['title'] ?? payload['name'],
          'description': payload['description'],
          'date': payload['dateTime'],
          'location': payload['location'],
          'category': payload['category'],
          'organization': payload['organizationName'],
          'logo': payload['imageUrl'],
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['event'] ?? {};
      }
      throw Exception('Create event failed ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Delete event
  static Future<void> deleteEvent(String idOrName) async {
    try {
      // Try to get event first to find its name
      final event = await fetchEventById(idOrName);
      final name = Uri.encodeComponent(event['name'] ?? idOrName);

      final resp = await http.delete(
        _u('/api/events/$name'),
        headers: _headers(needsAuth: true),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Delete failed ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      // If not found by ID, try as name directly
      final encodedName = Uri.encodeComponent(idOrName);
      final resp = await http.delete(
        _u('/api/events/$encodedName'),
        headers: _headers(needsAuth: true),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Delete failed ${resp.statusCode}: ${resp.body}');
      }
    }
  }

  /// Join an event (RSVP)
  static Future<Map<String, dynamic>> joinEvent(String eventIdOrName, String userId) async {
    try {
      // Try to get event name from ID
      String eventName = eventIdOrName;
      try {
        final event = await fetchEventById(eventIdOrName);
        eventName = event['name'] ?? eventIdOrName;
      } catch (e) {
        // If fetch fails, assume it's already a name
      }

      final encodedName = Uri.encodeComponent(eventName);
      final resp = await http.post(
        _u('/api/events/$encodedName/rsvp'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {'success': true, 'event': data['event'] ?? {}};
      }
      throw Exception('Join event failed ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      throw Exception('Join event failed: $e');
    }
  }

  /// Leave an event (Cancel RSVP)
  static Future<Map<String, dynamic>> leaveEvent(String eventIdOrName, String userId) async {
    try {
      // Try to get event name from ID
      String eventName = eventIdOrName;
      try {
        final event = await fetchEventById(eventIdOrName);
        eventName = event['name'] ?? eventIdOrName;
      } catch (e) {
        // If fetch fails, assume it's already a name
      }

      final encodedName = Uri.encodeComponent(eventName);
      final resp = await http.post(
        _u('/api/events/$encodedName/cancel-rsvp'),
        headers: _headers(needsAuth: true),
        body: jsonEncode({}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {'success': true, 'event': data['event'] ?? {}};
      }
      throw Exception('Leave event failed ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      throw Exception('Leave event failed: $e');
    }
  }
}