import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../user/food_item.dart';
import '../user/meal_entry.dart';

class NutritionService {
  NutritionService._();

  static const int _mealHistoryRetentionDays = 30;

  static final NutritionService instance = NutritionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<FoodItem>? _foodsCache;

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

  Future<List<FoodItem>> _getFoods() async {
    if (_foodsCache != null) {
      return _foodsCache!;
    }

    final rawJson = await rootBundle.loadString('assets/food_data/foods.json');
    final decoded = jsonDecode(rawJson) as List<dynamic>;
    _foodsCache = decoded
        .map((item) => FoodItem.fromDb(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
    return _foodsCache!;
  }

  CollectionReference<Map<String, dynamic>> _customFoodsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('custom_foods');
  }

  CollectionReference<Map<String, dynamic>> _mealEntriesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('meal_entries');
  }

  DateTime _mealRetentionCutoff() {
    return DateTime.now().subtract(const Duration(days: _mealHistoryRetentionDays));
  }

  Future<void> _pruneOldMealEntries(String uid) async {
    final cutoff = Timestamp.fromDate(_mealRetentionCutoff());
    final oldEntries = await _mealEntriesRef(uid)
        .where('logged_at', isLessThan: cutoff)
        .get();

    if (oldEntries.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in oldEntries.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _aliasText(String searchName) {
    var alias = ' $searchName ';
    const replacements = <String, String>{
      ' sua chua ': ' yogurt ',
      ' pho mai ': ' cheese ',
      ' sua dau nanh ': ' soy milk ',
      ' dau hu ': ' tofu ',
      ' dau phu ': ' tofu ',
      ' trung ga ': ' chicken egg ',
      ' trung vit ': ' duck egg ',
      ' thit ga ': ' chicken meat ',
      ' thit bo ': ' beef meat ',
      ' thit heo ': ' pork meat ',
      ' thit vit ': ' duck meat ',
      ' thit de ': ' goat meat ',
      ' thit be ': ' veal meat ',
      ' thit tho ': ' rabbit meat ',
      ' thit ': ' meat ',
      ' ga ': ' chicken ',
      ' bo ': ' beef ',
      ' heo ': ' pork ',
      ' vit ': ' duck ',
      ' de ': ' goat ',
      ' ca ': ' fish ',
      ' tom ': ' shrimp ',
      ' cua ': ' crab ',
      ' muc ': ' squid ',
      ' trung ': ' egg ',
      ' sua ': ' milk ',
      ' rau ': ' vegetable ',
      ' khoai ': ' potato ',
      ' gao ': ' rice ',
      ' bun ': ' vermicelli ',
      ' pho ': ' noodles ',
    };

    replacements.forEach((source, target) {
      alias = alias.replaceAll(source, target);
    });

    return _normalize(alias);
  }

  String _inferCategory(FoodItem food) {
    if (food.category != 'Other' && food.category.isNotEmpty) {
      return food.category;
    }

    final text = ' ${food.searchName} ${_aliasText(food.searchName)} ';
    if (text.contains(' chicken ') ||
        text.contains(' beef ') ||
        text.contains(' pork ') ||
        text.contains(' duck ') ||
        text.contains(' goat ') ||
        text.contains(' rabbit ') ||
        text.contains(' meat ')) {
      return 'Meat';
    }
    if (text.contains(' fish ') ||
        text.contains(' shrimp ') ||
        text.contains(' crab ') ||
        text.contains(' squid ') ||
        text.contains(' seafood ') ||
        text.contains(' eel ')) {
      return 'Seafood';
    }
    if (text.contains(' egg ')) {
      return 'Eggs';
    }
    if (text.contains(' yogurt ') ||
        text.contains(' cheese ') ||
        text.contains(' milk ')) {
      return 'Dairy';
    }
    if (text.contains(' rice ') ||
        text.contains(' noodles ') ||
        text.contains(' vermicelli ') ||
        text.contains(' bread ') ||
        text.contains(' bun ') ||
        text.contains(' flour ')) {
      return 'Grains';
    }
    if (text.contains(' potato ') ||
        text.contains(' vegetable ') ||
        text.contains(' tofu ') ||
        text.contains(' ginger ') ||
        text.contains(' turmeric ') ||
        text.contains(' peas ')) {
      return 'Vegetables';
    }
    if (text.contains(' pineapple ') ||
        text.contains(' coconut ') ||
        text.contains(' papaya ') ||
        text.contains(' longan ') ||
        text.contains(' lychee ') ||
        text.contains(' fruit ')) {
      return 'Fruits';
    }
    return 'Other';
  }

  FoodItem _enrichFood(FoodItem food) {
    final inferredCategory = _inferCategory(food);
    final enrichedSearchName = _normalize(
      '${food.searchName} ${food.name.toLowerCase()} ${_aliasText(food.searchName)}',
    );

    return food.copyWith(
      category: inferredCategory,
      searchName: enrichedSearchName,
    );
  }

  Future<List<FoodItem>> searchFoods(
    String query, {
    String category = 'All',
  }) async {
    final normalized = _normalize(query);
    final foods = await _getFoods();
    final results = foods
        .map(_enrichFood)
        .where((food) {
          final matchesCategory = category == 'All' || food.category == category;
          final matchesQuery = normalized.isEmpty || food.searchName.contains(normalized);
          return matchesCategory && matchesQuery;
        })
        .take(normalized.isEmpty && category == 'All' ? 40 : 60)
        .toList();
    final user = currentUser;

    if (user == null) {
      return results;
    }

    final customSnapshot = await _customFoodsRef(user.uid).get();
    final customFoods = customSnapshot.docs
        .map((doc) => FoodItem.fromFirestore(doc.id, doc.data()))
        .map(_enrichFood)
        .where((food) {
          final matchesQuery = normalized.isEmpty
              ? true
              : food.searchName.contains(normalized) ||
                  food.name.toLowerCase().contains(normalized);
          final matchesCategory = category == 'All' || food.category == category;

          if (normalized.isEmpty) {
            return matchesCategory;
          }
          return matchesQuery && matchesCategory;
        })
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return [...customFoods, ...results];
  }

  Future<void> createCustomFood({
    required String name,
    String? description,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double fatPer100g,
    required double carbsPer100g,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final normalized = _normalize(name);
    await _customFoodsRef(user.uid).add({
      'name': name.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'calories': caloriesPer100g,
      'protein': proteinPer100g,
      'fat': fatPer100g,
      'carbs': carbsPer100g,
      'search_name': normalized,
      'category': 'Custom',
      'is_custom': true,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMealEntry({
    required FoodItem food,
    required double grams,
    required String mealType,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    await _pruneOldMealEntries(user.uid);
    await _mealEntriesRef(user.uid).add({
      'food_name': food.name,
      'description': food.description,
      'grams': grams,
      'meal_type': mealType,
      'calories': food.caloriesFor(grams),
      'protein': food.proteinFor(grams),
      'fat': food.fatFor(grams),
      'carbs': food.carbsFor(grams),
      'logged_at': FieldValue.serverTimestamp(),
      'is_custom': food.isCustom,
    });
  }

  Stream<List<MealEntry>>? getTodayMealEntriesStream() {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    unawaited(_pruneOldMealEntries(user.uid));

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return _mealEntriesRef(user.uid)
        .where('logged_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('logged_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('logged_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MealEntry.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> deleteMealEntry(String id) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    await _mealEntriesRef(user.uid).doc(id).delete();
  }
}
