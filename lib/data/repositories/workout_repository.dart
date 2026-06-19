// ============================================================
//  SERVICE: WorkoutService
//  Chịu trách nhiệm:
//    - Đọc danh sách bài tập từ Firestore (collection 'exercises')
//    - Lưu / tải lịch tập tuần (weekly plan) lên Hive và Firebase
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_application_1/data/models/calisthenics_exercise.dart';
import 'package:flutter_application_1/data/models/planned_exercise.dart';
import 'package:flutter_application_1/data/models/workout_session_record.dart';

class WorkoutService {
  // ── Singleton ──────────────────────────────────────────────
  WorkoutService._();
  static final WorkoutService instance = WorkoutService._();

  // ── Constants ──────────────────────────────────────────────
  static const String _scheduleBox = 'training_schedule';
  static const String _weeklyPlanKey = 'weekly_plan';
  static const int totalDays = 7;

  // ── Firebase ───────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // ── Cache bài tập ──────────────────────────────────────────
  List<CalisthenicsExercise>? _exercisesCache;

  // ── Lấy danh sách bài tập từ Firestore (có cache) ─────────
  Future<List<CalisthenicsExercise>> getExercises() async {
    if (_exercisesCache != null) return _exercisesCache!;

    try {
      final snapshot = await _firestore
          .collection('exercises')
          .orderBy('name')
          .get();

      _exercisesCache = snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Đảm bảo field 'id' luôn có giá trị (dùng doc.id làm fallback)
            if (!data.containsKey('id')) data['id'] = doc.id;
            return CalisthenicsExercise.fromJson(data);
          })
          .toList(growable: false);

      return _exercisesCache!;
    } catch (e) {
      print("Error loading exercises from Firestore: $e");
      throw Exception("Failed to load exercises: $e");
    }
  }

  // ── Xóa cache bài tập (dùng khi cần refresh) ──────────────
  void clearExerciseCache() => _exercisesCache = null;

  // ── Lưu buổi tập hoàn thành vào Firestore ─────────────────
  Future<void> saveSession(WorkoutSessionRecord record) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_sessions')
          .add({
            ...record.toMap(),
            'server_time': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print("Error saving workout session: $e");
      throw Exception("Failed to save workout session: $e");
    }
  }

  // ── Stream lịch sử buổi tập (30 ngày gần nhất) ────────────
  Stream<List<WorkoutSessionRecord>>? getSessionsStream() {
    final user = currentUser;
    if (user == null) return null;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    try {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_sessions')
          .where(
            'completed_at',
            isGreaterThanOrEqualTo: cutoff.toIso8601String(),
          )
          .orderBy('completed_at', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => WorkoutSessionRecord.fromMap(d.id, d.data()))
                .toList(),
          );
    } catch (e) {
      print("Error getting workout sessions stream: $e");
      return Stream.value(<WorkoutSessionRecord>[]);
    }
  }

  // ── Tải lịch tập (Hive trước, Firebase sau) ───────────────
  Future<Map<int, Map<String, PlannedExercise>>> loadWeeklyPlan() async {
    final emptyPlan = _emptyPlan();

    // 1. Đọc từ Hive (local cache — nhanh)
    try {
      final box = await Hive.openBox(_scheduleBox);
      final saved = box.get(_weeklyPlanKey);
      if (saved is Map) {
        _applyPlanMap(emptyPlan, saved);
      }
    } catch (e) {
      print("Error reading plan from local Hive cache: $e");
    }

    // 2. Đồng bộ từ Firebase nếu đã đăng nhập
    final user = currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('training_schedules')
            .doc(user.uid)
            .get();
        final remotePlan = snapshot.data()?[_weeklyPlanKey];
        if (remotePlan is Map) {
          _applyPlanMap(emptyPlan, remotePlan);
          // Ghi ngược lại Hive để đồng bộ offline
          final box = await Hive.openBox(_scheduleBox);
          await box.put(_weeklyPlanKey, _serializePlan(emptyPlan));
        }
      } catch (e) {
        print("Error syncing training schedule from Firebase: $e");
      }
    }

    return emptyPlan;
  }

  // ── Lưu lịch tập (Hive + Firebase) ────────────────────────
  Future<void> saveWeeklyPlan(
    Map<int, Map<String, PlannedExercise>> plan,
  ) async {
    final serialized = _serializePlan(plan);

    try {
      // Lưu local trước (offline first)
      final box = await Hive.openBox(_scheduleBox);
      await box.put(_weeklyPlanKey, serialized);
    } catch (e) {
      print("Error saving plan to local Hive cache: $e");
    }

    // Sync lên Firebase nếu đã đăng nhập
    final user = currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('training_schedules')
          .doc(user.uid)
          .set({
            _weeklyPlanKey: serialized,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print("Error syncing plan to Firebase: $e");
      throw Exception("Failed to sync training schedule online: $e");
    }
  }

  // ── Helpers ────────────────────────────────────────────────
  Map<int, Map<String, PlannedExercise>> _emptyPlan() => {
    for (var i = 0; i < totalDays; i++) i: <String, PlannedExercise>{},
  };

  void _applyPlanMap(
    Map<int, Map<String, PlannedExercise>> target,
    Map source,
  ) {
    for (final entry in source.entries) {
      final day = int.tryParse(entry.key.toString());
      final items = entry.value;
      if (day == null || !target.containsKey(day) || items is! List) continue;
      for (final item in items) {
        if (item is! Map) continue;
        final planned = PlannedExercise.fromMap(item);
        target[day]![planned.exerciseId] = planned;
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _serializePlan(
    Map<int, Map<String, PlannedExercise>> plan,
  ) => {
    for (final entry in plan.entries)
      entry.key.toString(): entry.value.values
          .map((p) => p.toMap())
          .toList(),
  };
}
