import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../Pages/EmailVerification.dart';
import '../Pages/ForgotPassword.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});
  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // login
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();

  // register
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _role = 'member'; // "member" or "officer"

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      final json = await ApiService.login(
        email: _loginEmail.text.trim(),
        password: _loginPass.text,
      );

      final user = AppUser.fromJson(json['user']);
      Session.currentUser = user;

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged in as ${user.role} (Admin: ${user.isAdmin})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Check if error is due to unverified email
      if (e.toString().contains('verify your email') ||
          e.toString().contains('requiresVerification')) {
        // Navigate to email verification screen
        final verified = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationPage(
              email: _loginEmail.text.trim(),
            ),
          ),
        );

        // If verified, try to login again
        if (verified == true) {
          _login();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      final name = '${_first.text.trim()} ${_last.text.trim()}'.trim();

      final json = await ApiService.register(
        name: name,
        email: _email.text.trim(),
        password: _pass.text,
        role: _role,
      );

      if (!mounted) return;

      // Navigate to email verification screen
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationPage(
            email: _email.text.trim(),
            userName: name,
          ),
        ),
      );

      // If verified, update session and close dialog
      if (verified == true) {
        // Fetch user again to get updated verification status
        try {
          final loginJson = await ApiService.login(
            email: _email.text.trim(),
            password: _pass.text,
          );
          Session.currentUser = AppUser.fromJson(loginJson['user']);
        } catch (e) {
          // If login fails after verification, just use the registration response
          Session.currentUser = AppUser.fromJson(json['user']);
        }

        if (!mounted) return;
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created and verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordPage(),
      ),
    );
  }

  // styles
  static const _cardColor = Color(0xFFF5C948);
  static const _hint = TextStyle(color: Colors.black38, fontSize: 18);
  InputDecoration _decor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: _hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _tab,
                      builder: (context, _) {
                        final isLogin = _tab.index == 0;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLogin ? 'Login' : 'Create Account',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            isLogin ? _buildLoginForm() : _buildRegisterForm(),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLogin
                                      ? "Don't have an account? "
                                      : "Already have an account? ",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _tab.animateTo(isLogin ? 1 : 0),
                                  child: Text(isLogin ? 'Sign Up' : 'Log In'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _loginEmail,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 18),
          decoration: _decor('username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPass,
          obscureText: true,
          style: const TextStyle(fontSize: 18),
          decoration: _decor('password'),
        ),
        const SizedBox(height: 8),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _busy ? null : _login,
            label: const Text(
              'Sign in',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
            icon: const Icon(Icons.lock, color: Colors.black),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _first,
          style: const TextStyle(fontSize: 18),
          decoration: _decor('First Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _last,
          style: const TextStyle(fontSize: 18),
          decoration: _decor('Last Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 18),
          decoration: _decor('UCF Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pass,
          obscureText: true,
          style: const TextStyle(fontSize: 18),
          decoration: _decor('Password'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _role,
          isExpanded: true,
          isDense: true,
          decoration: _decor('Role').copyWith(
            contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          ),
          style: const TextStyle(fontSize: 16, color: Colors.black),
          items: const [
            DropdownMenuItem(
              value: 'member',
              child: Text('Member (Student)'),
            ),
            DropdownMenuItem(
              value: 'officer',
              child: Text('Officer (Administrator)'),
            ),
          ],
          onChanged: (v) => setState(() => _role = v ?? 'member'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _busy ? null : _register,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}