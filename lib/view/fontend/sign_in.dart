import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/view/widgets/Ui.dart';
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

  Future<void> _navigateToHome() async {
    if (!mounted) return;

    await Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
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
      await _navigateToHome();
    } on GoogleSignInException catch (e) {
      _showErrorSnackBar(e.description ?? 'Google sign in failed');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Authentication failed');
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted && ModalRoute.of(context)?.settings.name == AppRoutes.login) {
        _setLoading(false);
      }
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
      await _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Authentication failed');
    } catch (e) {
      _showErrorSnackBar('Unexpected error: $e');
    } finally {
      if (mounted && ModalRoute.of(context)?.settings.name == AppRoutes.login) {
        _setLoading(false);
      }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome To,',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 215, 215, 215),
          ),
        ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 6),
        Text(
          'The Onyx Lab!',
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
            const Text(
              'Sign in',
              style: TextStyle(
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
            const SizedBox(height: 20),
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
        if (email.isEmpty) return 'Please enter your email';
        if (!email.contains('@') || !email.contains('.')) {
          return 'Please enter a valid email';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 215, 215, 215),
          fontFamily: 'Poppins',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) {
        if (!_isLoading) {
          _handleSignIn();
        }
      },
      style: const TextStyle(
        color: Color.fromARGB(239, 227, 227, 227),
        fontSize: 16,
        fontFamily: 'Poppins',
      ),
      validator: (value) {
        final password = value?.trim() ?? '';
        if (password.isEmpty) return 'Please enter your password';
        if (password.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color.fromARGB(255, 215, 215, 215),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
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
            : const Text(
                'Lets go',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.signup);
          },
          child: const Text(
            'Sign Up',
            style: TextStyle(
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
          onTap: _isLoading
              ? null
              : () {
                  debugPrint('Sign in with facebook');
                },
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
