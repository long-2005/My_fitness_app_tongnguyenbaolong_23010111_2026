import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_application_1/data/repositories/language_repository.dart';
import 'package:flutter_application_1/l10n/app_strings.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/presentation/views/auth/forgot_password_view.dart';
import 'package:flutter_application_1/presentation/widgets/ui_background.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '958242886503-pe7im64b2nd9c6qe44scre90f6hdukb4.apps.googleusercontent.com',
      );
    } catch (e) {
      debugPrint('Google Sign-In init error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getFriendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email. Please check and try again.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your Wi-Fi or mobile data.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please check your credentials.';
      case 'account-exists-with-different-credential':
        return 'This email is already registered with a different sign-in method.';
      case 'email-already-in-use':
        return 'This email is already in use. Please sign in or use a different email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Your session has expired. Please sign in again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;
    // Về root '/' = AuthGate, không phải '/home' trực tiếp.
    // Khi logout, AuthGate stream tự detect và chuyển về SignInView.
    await Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await LanguageService().loadForCurrentUser();
      await _navigateToHome();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      _showErrorSnackBar(
        'Google sign-in failed. Please check your internet connection and try again.',
      );
      debugPrint('Google sign-in error: ${e.description}');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(_getFriendlyAuthError(e.code));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('timeout')) {
        _showErrorSnackBar(
          'No internet connection. Please check your Wi-Fi or mobile data.',
        );
      } else {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
      debugPrint('Unexpected Google sign-in error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    _setLoading(true);

    try {
      // Fix đăng nhập fb: Sử dụng FacebookAuth login với các quyền cấu hình hợp lệ
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.cancelled) return;

      final accessToken = loginResult.accessToken;
      if (loginResult.status != LoginStatus.success || accessToken == null) {
        _showErrorSnackBar(
          loginResult.message ??
              'Facebook sign-in failed. Please try again.',
        );
        return;
      }

      final credential = FacebookAuthProvider.credential(accessToken.tokenString);

      await _auth.signInWithCredential(credential);
      await LanguageService().loadForCurrentUser();
      await _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(_getFriendlyAuthError(e.code));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('timeout')) {
        _showErrorSnackBar(
          'No internet connection. Please check your Wi-Fi or mobile data.',
        );
      } else {
        _showErrorSnackBar(
          'Facebook sign-in failed. Please check your setup and try again.',
        );
      }
      debugPrint('Unexpected Facebook sign-in error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleSignIn() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    _setLoading(true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await LanguageService().loadForCurrentUser();
      await _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(_getFriendlyAuthError(e.code));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('timeout')) {
        _showErrorSnackBar(
          'No internet connection. Please check your Wi-Fi or mobile data.',
        );
      } else {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
      debugPrint('Unexpected sign-in error: $e');
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
                20,
                32,
                20,
                mediaQuery.viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      mediaQuery.size.height -
                      mediaQuery.padding.top -
                      mediaQuery.padding.bottom -
                      56,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 88),
                    _buildSignInCard(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.welcomeTo,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 215, 215, 215),
          ),
        ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 6),
        Text(
          s.appName,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 215, 215, 215),
          ),
        ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _buildSignInCard() {
    final s = AppStrings.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(16, 218, 218, 218),
        borderRadius: BorderRadius.circular(20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.signIn,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 215, 215, 215),
              ),
            ),
            const SizedBox(height: 20),
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 8),
            _buildForgotPasswordLink().animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            _buildPrimaryButton(),
            const SizedBox(height: 20),
            _buildSignUpPrompt().animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 20),
            _buildSocialRow().animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildEmailField() {
    final s = AppStrings.of(context);
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      style: const TextStyle(
        color: Color.fromARGB(239, 227, 227, 227),
        fontSize: 16,
        fontFamily: 'Poppins',
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return s.pleaseEnterEmail;
        if (!email.contains('@') || !email.contains('.')) return s.invalidEmail;
        return null;
      },
      decoration: InputDecoration(
        labelText: s.email,
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 215, 215, 215),
          fontFamily: 'Poppins',
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPasswordField() {
    final s = AppStrings.of(context);
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) {
        if (!_isLoading) _handleSignIn();
      },
      style: const TextStyle(
        color: Color.fromARGB(239, 227, 227, 227),
        fontSize: 16,
        fontFamily: 'Poppins',
      ),
      validator: (value) {
        final pw = value?.trim() ?? '';
        if (pw.isEmpty) return s.pleaseEnterPassword;
        if (pw.length < 6) return s.passwordTooShort;
        return null;
      },
      decoration: InputDecoration(
        labelText: s.password,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color.fromARGB(255, 215, 215, 215),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final s = AppStrings.of(context);
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 133, 20, 20),
          disabledBackgroundColor: const Color.fromARGB(
            255,
            133,
            20,
            20,
          ).withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
                s.letsGo,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    final s = AppStrings.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
        ),
        child: Text(
          s.forgotPassword,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFFE16D6D),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    final s = AppStrings.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          s.noAccount,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
          child: Text(
            s.signUp,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color.fromARGB(255, 133, 20, 20),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton(
          iconPath: 'assets/image/google_logo.png',
          onTap: _isLoading ? null : _handleGoogleSignIn,
        ),
        _buildSocialButton(
          iconPath: 'assets/image/facebook_logo.png',
          onTap: _isLoading ? null : _handleFacebookSignIn,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String iconPath,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Image.asset(
          iconPath,
          height: 30,
          width: 30,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
