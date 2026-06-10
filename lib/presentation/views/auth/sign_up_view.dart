import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_application_1/data/repositories/language_repository.dart';
import 'package:flutter_application_1/l10n/app_strings.dart';
import 'package:flutter_application_1/presentation/widgets/ui_background.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isObscure = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getFriendlyAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng dùng ít nhất 6 ký tự.';
      case 'operation-not-allowed':
        return 'Phương thức đăng ký này chưa được hỗ trợ.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng chờ vài phút rồi thử lại.';
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
    }
  }

  Future<void> _handleSignUp() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    _setLoading(true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': name,
        'email': email,
        'createdAt': DateTime.now(),
        'languageCode': LanguageService().languageCode,
        'role': 'user',
      });

      if (!mounted) return;
      _showSnackBar(
        'Account created successfully!',
        backgroundColor: Colors.green,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
        _getFriendlyAuthError(e.code),
        backgroundColor: Colors.redAccent,
      );
    } catch (e) {
      debugPrint('System Error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('timeout')) {
        _showSnackBar(
          'No internet connection. Please check your Wi-Fi or mobile data.',
          backgroundColor: Colors.redAccent,
        );
      } else {
        _showSnackBar(
          'A system error occurred. Please try again later.',
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const BackgroundModify(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                25,
                20,
                25,
                mediaQuery.viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      mediaQuery.size.height -
                      mediaQuery.padding.top -
                      mediaQuery.padding.bottom -
                      40,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color.fromARGB(255, 245, 245, 245),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildSignUpCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final s = AppStrings.of(context);
    return Text(
      s.createAccount,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSignUpCard() {
    final s = AppStrings.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(16, 218, 218, 218),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(218, 0, 0, 0),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              label: s.fullName,
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return s.pleaseEnterName;
                if (name.length < 2) return s.nameTooShort;
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _emailController,
              label: s.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return s.pleaseEnterEmail;
                if (!email.contains('@') || !email.contains('.')) {
                  return s.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              controller: _passwordController,
              label: s.password,
              isObscure: _isObscure,
              onToggle: () => setState(() => _isObscure = !_isObscure),
              validator: (value) {
                final password = value?.trim() ?? '';
                if (password.isEmpty) return s.pleaseEnterPassword;
                if (password.length < 6) return s.passwordTooShort;
                return null;
              },
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: s.confirmPassword,
              isObscure: _isObscureConfirm,
              onToggle: () =>
                  setState(() => _isObscureConfirm = !_isObscureConfirm),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isLoading) _handleSignUp();
              },
              validator: (value) {
                final confirmPassword = value?.trim() ?? '';
                if (confirmPassword.isEmpty) return s.pleaseConfirmPassword;
                if (confirmPassword != _passwordController.text.trim()) {
                  return s.passwordsDoNotMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 133, 20, 20),
                  disabledBackgroundColor: const Color.fromARGB(
                    255,
                    133,
                    20,
                    20,
                  ).withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        s.signUp.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).moveY(begin: 30, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Color.fromARGB(255, 254, 254, 254),
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Color.fromARGB(252, 255, 255, 255),
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
