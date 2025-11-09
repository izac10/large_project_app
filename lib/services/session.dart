
import '../models/user.dart';

class Session {
  static AppUser? currentUser;

  static bool get isLoggedIn => currentUser != null;

  // officer = admin
  static bool get isAdmin =>
      currentUser?.role.toLowerCase() == 'officer';

  static String? get email => currentUser?.email;
}
