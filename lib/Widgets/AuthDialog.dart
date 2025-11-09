import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session.dart';

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
      Session.currentUser = AppUser.fromJson(json['user']);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
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
      Session.currentUser = AppUser.fromJson(json['user']);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        // Dismiss keyboard if user taps outside fields
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              // This is key: use scrollable content but fixed container height
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _tab,
                    builder: (context, _) {
                      final isLogin = _tab.index == 0;
                      return Column(
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

                          // The scrollable area — fixed container height
                          SizedBox(
                            height: isLogin ? 320 : 480,
                            child: TabBarView(
                              controller: _tab,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildLoginForm(),
                                _buildRegisterForm(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLogin
                                    ? "Don’t have an account? "
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
    );
  }

  // LOGIN form
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
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
          const SizedBox(height: 16),
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
      ),
    );
  }

  // REGISTER form
  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
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
      ),
    );
  }
}
