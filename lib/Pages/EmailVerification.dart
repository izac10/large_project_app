// Pages/EmailVerification.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/session.dart';
import '../models/user.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String? userName;

  const EmailVerificationPage({
    super.key,
    required this.email,
    this.userName,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
        (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  String? _error;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyCode() async {
    final code = _code;
    if (code.length != 6) {
      setState(() => _error = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final response = await ApiService.verifyEmail(widget.email, code);

      // Update session with verified user
      if (response['user'] != null) {
        Session.currentUser = AppUser.fromJson(response['user']);
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Email verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back and indicate success
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString().contains('Invalid or expired')
            ? 'Invalid or expired code. Please try again.'
            : 'Verification failed. Please try again.';
        _verifying = false;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      await ApiService.resendVerificationCode(widget.email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent!'),
          backgroundColor: Colors.green,
        ),
      );

      _startResendCountdown();
    } catch (e) {
      setState(() => _error = 'Failed to resend code. Please try again.');
    } finally {
      setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 40,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'VERIFY YOUR EMAIL ADDRESS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'A verification code has been sent to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your inbox and enter the verification code below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The code will expire in 15 minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),

              // Code input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildCodeBox(index)),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Verify',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend code
              Text(
                "Still can't find the email?",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _resending || _resendCountdown > 0 ? null : _resendCode,
                child: _resending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  _resendCountdown > 0
                      ? 'Resend code in ${_resendCountdown}s'
                      : 'Resend Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _resendCountdown > 0
                        ? Colors.grey
                        : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to change email screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Change email feature coming soon'),
                    ),
                  );
                },
                child: const Text(
                  'Change email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(
          color: _codeControllers[index].text.isNotEmpty
              ? Colors.green
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // All fields filled, hide keyboard
              FocusScope.of(context).unfocus();
            }
          } else {
            // Move to previous field on backspace
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {});
        },
      ),
    );
  }
}