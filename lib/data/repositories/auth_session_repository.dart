import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthSessionRepository {
  const AuthSessionRepository._();

  static Future<void> signOut() async {
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      GoogleSignIn.instance.signOut().catchError((_) {}),
      FacebookAuth.instance.logOut().catchError((_) {}),
    ]);
  }
}
