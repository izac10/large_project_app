import '../models/user.dart';

class Session {
  static AppUser? currentUser;

  static bool get isLoggedIn => currentUser != null;

  // Use the isAdmin field directly from the user object
  static bool get isAdmin => currentUser?.isAdmin ?? false;

  static String? get email => currentUser?.email;

  static String? get userId => currentUser?.id;

  // Helper to check if user has a specific role
  static bool hasRole(String role) {
    return currentUser?.role.toLowerCase() == role.toLowerCase();
  }

  // Clear session on logout
  static void clear() {
    currentUser = null;
  }
}