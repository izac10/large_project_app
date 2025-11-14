import '../models/user.dart';
import '../services/api_service.dart';

class Session {
  static AppUser? currentUser;
  static String? _authToken;

  static bool get isLoggedIn => currentUser != null && _authToken != null;

  // Use the isAdmin field directly from the user object
  static bool get isAdmin => currentUser?.isAdmin ?? false;

  static String? get email => currentUser?.email;

  static String? get userId => currentUser?.id;

  static String? get authToken => _authToken;

  // Set user and token together
  static void setUser(AppUser user, String token) {
    currentUser = user;
    _authToken = token;
    ApiService.setAuthToken(token);
  }

  // Helper to check if user has a specific role
  static bool hasRole(String role) {
    return currentUser?.role.toLowerCase() == role.toLowerCase();
  }

  // Clear session on logout
  static void clear() {
    currentUser = null;
    _authToken = null;
    ApiService.clearAuthToken();
  }
}