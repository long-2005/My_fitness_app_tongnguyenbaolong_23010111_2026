import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageService extends ChangeNotifier {
  static const _langKey = 'languageCode';
  static const String langEn = 'en';
  static const String langVi = 'vi';

  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _languageCode = langEn;
  String? _loadedUid;

  String get languageCode => _languageCode;
  bool get isVietnamese => _languageCode == langVi;

  Future<void> init() async {
    await loadForCurrentUser();

    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _loadedUid = null;
        _setLocalLanguage(langEn);
        return;
      }

      if (_loadedUid != user.uid) {
        loadForCurrentUser();
      }
    });
  }

  Future<void> setLanguage(String code) async {
    if (!_isSupported(code)) return;

    if (_languageCode == code) return;
    _setLocalLanguage(code);

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      _langKey: code,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> loadForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      _loadedUid = null;
      _setLocalLanguage(langEn);
      return;
    }

    if (_loadedUid == user.uid) return;
    _loadedUid = user.uid;

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final code = snapshot.data()?[_langKey] as String?;
      _setLocalLanguage(_isSupported(code) ? code! : langEn);
    } catch (e) {
      debugPrint('Failed to load language from Firebase: $e');
    }
  }

  bool _isSupported(String? code) => code == langEn || code == langVi;

  void _setLocalLanguage(String code) {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
  }
}
