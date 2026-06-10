import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_application_1/l10n/app_strings.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: backgroundColor ?? const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getFriendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your Wi-Fi or mobile data.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      _showSnackBar(_getFriendlyAuthError(e.code), backgroundColor: Colors.redAccent);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout')) {
        _showSnackBar(
          'No internet connection. Please check your Wi-Fi or mobile data.',
          backgroundColor: Colors.redAccent,
        );
      } else {
        _showSnackBar(
          'An unexpected error occurred. Please try again.',
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0505), Color(0xFF0A0A0A), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 32),

                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF851414), Color(0xFFB41414)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB41414).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                // Title
                Text(
                  s.forgotPasswordTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),

                const SizedBox(height: 10),

                Text(
                  s.forgotPasswordSubtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey.shade400,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 36),

                // Success or form
                _emailSent ? _buildSuccessCard(s) : _buildForm(s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AppStrings s) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color.fromARGB(16, 218, 218, 218),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(180, 0, 0, 0),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _handleSendResetEmail();
                  },
                  style: const TextStyle(
                    color: Color.fromARGB(239, 227, 227, 227),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return s.pleaseEnterEmail;
                    if (!email.contains('@') || !email.contains('.')) {
                      return s.invalidEmail;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: s.email,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.grey,
                    ),
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 215, 215, 215),
                      fontFamily: 'Poppins',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFB41414),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF851414),
                      disabledBackgroundColor:
                          const Color(0xFF851414).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                s.sendResetLink,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

        const SizedBox(height: 24),

        // Back to sign in
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              s.backToSignIn,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFE16D6D),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildSuccessCard(AppStrings s) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D2B0D), Color(0xFF111111)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.greenAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.resetEmailSent,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _emailController.text.trim(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE16D6D), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFE16D6D),
              size: 16,
            ),
            label: Text(
              s.backToSignIn,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFE16D6D),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}
