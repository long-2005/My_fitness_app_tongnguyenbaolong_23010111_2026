// ============================================================
//  SERVICE: NutritionService
//  Chịu trách nhiệm:
//    - Tìm kiếm thực phẩm từ Firestore (collection 'foods')
//    - Quản lý món ăn tùy chỉnh của người dùng (custom_foods)
//    - Ghi / xóa nhật ký bữa ăn hàng ngày (meal_entries)
// ============================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/data/models/food_item.dart';
import 'package:flutter_application_1/data/models/meal_entry.dart';

class NutritionService {
  NutritionService._();

  static const int _mealHistoryRetentionDays = 30;

  static final NutritionService instance = NutritionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Các danh mục hỗ trợ lọc ───────────────────────────────
  static const List<String> smartCategories = [
    'All',
    'Meat',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Seafood',
    'Eggs',
    'Grains',
  ];

  User? get currentUser => _auth.currentUser;

  // ── Reference các collection Firestore ────────────────────

  CollectionReference<Map<String, dynamic>> get _foodsRef =>
      _firestore.collection('foods');

  CollectionReference<Map<String, dynamic>> _customFoodsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('custom_foods');

  CollectionReference<Map<String, dynamic>> _mealEntriesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('meal_entries');

  // ── Tìm kiếm thực phẩm ────────────────────────────────────
  /// Tìm kiếm thực phẩm từ Firestore.
  /// Kết quả được kết hợp: [món tùy chỉnh của user] + [thực phẩm chung]
  Future<List<FoodItem>> searchFoods(
    String query, {
    String category = 'All',
  }) async {
    try {
      final normalized = _normalize(query);

      // 1. Lấy thực phẩm chung từ Firestore
      Query<Map<String, dynamic>> foodQuery = _foodsRef;
      if (category != 'All') {
        foodQuery = foodQuery.where('category', isEqualTo: category);
      }

      final snapshot = await foodQuery.limit(200).get();
      final allFoods = snapshot.docs
          .map((doc) => FoodItem.fromDb(doc.data()))
          .toList();

      // Lọc theo từ khóa tìm kiếm trên client (Firestore free tier không hỗ trợ full-text search)
      final results = allFoods.where((food) {
        if (normalized.isEmpty) return true;
        final searchName = food.searchName.toLowerCase();
        final name = food.name.toLowerCase();
        return searchName.contains(normalized) || name.contains(normalized);
      }).take(60).toList();

      // 2. Lấy món tùy chỉnh của user (nếu đã đăng nhập)
      final user = currentUser;
      if (user == null) return results;

      Query<Map<String, dynamic>> customQuery = _customFoodsRef(user.uid);
      if (category != 'All') {
        customQuery = customQuery.where('category', isEqualTo: category);
      }

      final customSnapshot = await customQuery.get();
      final customFoods = customSnapshot.docs
          .map((doc) => FoodItem.fromFirestore(doc.id, doc.data()))
          .where((food) {
            if (normalized.isEmpty) return true;
            return food.searchName.contains(normalized) ||
                food.name.toLowerCase().contains(normalized);
          })
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return [...customFoods, ...results];
    } catch (e) {
      print("Error searching foods: $e");
      throw Exception("Failed to search foods database: $e");
    }
  }

  // ── Tạo món ăn tùy chỉnh ──────────────────────────────────
  Future<void> createCustomFood({
    required String name,
    String? description,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double fatPer100g,
    required double carbsPer100g,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not signed in');

    try {
      final normalized = _normalize(name);
      await _customFoodsRef(user.uid).add({
        'name': name.trim(),
        'description':
            description?.trim().isEmpty == true ? null : description?.trim(),
        'calories': caloriesPer100g,
        'protein': proteinPer100g,
        'fat': fatPer100g,
        'carbs': carbsPer100g,
        'search_name': normalized,
        'category': 'Custom',
        'is_custom': true,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating custom food: $e");
      throw Exception("Failed to save custom food item: $e");
    }
  }

  // ── Ghi nhật ký bữa ăn ────────────────────────────────────
  Future<void> addMealEntry({
    required FoodItem food,
    required double grams,
    required String mealType,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not signed in');

    try {
      unawaited(_pruneOldMealEntries(user.uid));

      // Sử dụng ORM thông qua đối tượng MealEntry và toMap() của nó
      final entry = MealEntry(
        id: '',
        foodName: food.name,
        description: food.description,
        grams: grams,
        calories: food.caloriesFor(grams),
        protein: food.proteinFor(grams),
        fat: food.fatFor(grams),
        carbs: food.carbsFor(grams),
        mealType: mealType,
        loggedAt: DateTime.now(), // Fallback
        isCustom: food.isCustom,
        vitaminC: food.vitaminCFor(grams),
        vitaminA: food.vitaminAFor(grams),
        vitaminB1: food.vitaminB1For(grams),
        calcium: food.calciumFor(grams),
        iron: food.ironFor(grams),
        fiber: food.fiberFor(grams),
      );

      final map = entry.toMap();
      map['logged_at'] = FieldValue.serverTimestamp(); // Thay thế bằng Firestore server timestamp

      await _mealEntriesRef(user.uid).add(map);
    } catch (e) {
      print("Error adding meal entry: $e");
      throw Exception("Failed to record meal entry: $e");
    }
  }

  // ── Stream nhật ký bữa ăn hôm nay ─────────────────────────
  Stream<List<MealEntry>>? getTodayMealEntriesStream() {
    final user = currentUser;
    if (user == null) return null;

    unawaited(_pruneOldMealEntries(user.uid));

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    try {
      return _mealEntriesRef(user.uid)
          .where(
            'logged_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('logged_at', isLessThan: Timestamp.fromDate(end))
          .orderBy('logged_at', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => MealEntry.fromFirestore(doc.id, doc.data()))
                .toList(),
          );
    } catch (e) {
      print("Error getting today meal entries stream: $e");
      // Trả về stream trống khi lỗi để tránh crash UI
      return Stream.value(<MealEntry>[]);
    }
  }

  // ── Xóa bản ghi bữa ăn ────────────────────────────────────
  Future<void> deleteMealEntry(String id) async {
    final user = currentUser;
    if (user == null) throw Exception('User not signed in');
    try {
      await _mealEntriesRef(user.uid).doc(id).delete();
    } catch (e) {
      print("Error deleting meal entry: $e");
      throw Exception("Failed to delete meal entry: $e");
    }
  }

  // ── Helpers ────────────────────────────────────────────────
  String _normalize(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  DateTime _mealRetentionCutoff() =>
      DateTime.now().subtract(const Duration(days: _mealHistoryRetentionDays));

  Future<void> _pruneOldMealEntries(String uid) async {
    try {
      final cutoff = Timestamp.fromDate(_mealRetentionCutoff());
      final oldEntries = await _mealEntriesRef(uid)
          .where('logged_at', isLessThan: cutoff)
          .get();

      if (oldEntries.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in oldEntries.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Error pruning old meal entries: $e");
    }
  }
}

