import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_application_1/presentation/views/auth/sign_in_view.dart';
import 'package:flutter_application_1/presentation/views/auth/sign_up_view.dart';
import 'package:flutter_application_1/presentation/views/home/home_view.dart';
import 'package:flutter_application_1/presentation/views/auth/forgot_password_view.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_application_1/data/repositories/language_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    // Fix đăng nhập fb: Khởi tạo Facebook SDK trên nền tảng Web
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: '1634772734402321',
      cookie: true,
      xfbml: true,
      version: 'v18.0',
    );
  }

  // App Check cho Android/iOS — bỏ qua web (chưa có reCAPTCHA key).
  // Debug mode: tự sinh token debug, in ra logcat → đăng ký trên Firebase Console.
  // Release Android: Play Integrity; Release iOS: Device Check.
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
  }

  final languageService = LanguageService();
  await languageService.init();

  runApp(
    ChangeNotifierProvider<LanguageService>.value(
      value: languageService,
      child: const HealthApp(),
    ),
  );
}

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String bmi = '/bmi';
  static const String forgotPassword = '/forgot-password';
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  // Bật/tắt hiển thị FPS và hiệu năng trên màn hình (để test mượt mà)
  static const bool showFpsOverlay = true;

  @override
  Widget build(BuildContext context) {
    // Listen to language changes to rebuild MaterialApp
    context.watch<LanguageService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (showFpsOverlay && child != null) {
          return FpsCounter(child: child);
        }
        return child!;
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthGate(),
      routes: {
        AppRoutes.login: (context) => const SignInView(),
        AppRoutes.signup: (context) => const SignUpView(),
        AppRoutes.home: (context) => const HomeView(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordView(),
      },
    );
  }
}

// ── Custom FPS Counter Widget ───────────────────────────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupView();
        }

        if (snapshot.hasData) {
          return const HomeView();
        }

        return const SignInView();
      },
    );
  }
}

class _StartupView extends StatelessWidget {
  const _StartupView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFE16D6D)),
      ),
    );
  }
}

class FpsCounter extends StatefulWidget {
  final Widget child;
  const FpsCounter({super.key, required this.child});

  @override
  State<FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<FpsCounter>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<int> _fpsNotifier = ValueNotifier<int>(0);
  int _frameCount = 0;
  DateTime _lastTime = DateTime.now();
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _frameCount++;
    final now = DateTime.now();
    final diff = now.difference(_lastTime).inMilliseconds;
    if (diff >= 1000) {
      _fpsNotifier.value = (_frameCount * 1000 / diff).round();
      _frameCount = 0;
      _lastTime = now;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fpsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 45, // Nằm dưới thanh trạng thái
            right: 20, // Góc phải
            child: IgnorePointer(
              child: ValueListenableBuilder<int>(
                valueListenable: _fpsNotifier,
                builder: (context, fps, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: fps >= 50 ? Colors.green : Colors.redAccent,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$fps FPS',
                      style: TextStyle(
                        color: fps >= 50 ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
