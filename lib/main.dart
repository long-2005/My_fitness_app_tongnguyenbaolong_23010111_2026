import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/view/fontend/sign_in.dart';
import 'package:flutter_application_1/view/fontend/sign_up.dart';
import 'package:flutter_application_1/view/fontend/Home_view.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HealthApp()); 
}
class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String bmi = '/bmi';
}
class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const SignInView(),
        AppRoutes.signup: (context) => const SignUpView(),
        AppRoutes.home: (context) => const HomeView(),
      },
    );
  }
}
