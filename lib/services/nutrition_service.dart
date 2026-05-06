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
      // ── Sữa & Trứng ──────────────────────────────────────────
      ' sua chua ': ' yogurt ',
      ' pho mai ': ' cheese ',
      ' sua dau nanh ': ' soy milk ',
      ' dau hu ': ' tofu ',
      ' dau phu ': ' tofu ',
      ' trung ga ': ' chicken egg ',
      ' trung vit ': ' duck egg ',
      ' trung ': ' egg ',
      ' sua ': ' milk ',
      // ── Thịt — tên chung ─────────────────────────────────────
      ' thit ga ': ' chicken meat ',
      ' thit bo ': ' beef meat ',
      ' thit heo ': ' pork meat ',
      ' thit lon ': ' pork meat ',
      ' thit vit ': ' duck meat ',
      ' thit de ': ' goat meat ',
      ' thit cuu ': ' lamb meat ',
      ' thit be ': ' veal meat ',
      ' thit tho ': ' rabbit meat ',
      ' thit ': ' meat ',
      ' ga ': ' chicken ',
      ' heo ': ' pork ',
      ' lon ': ' pork ',
      ' vit ': ' duck ',
      ' de ': ' goat ',
      // ── Gà — bộ phận cụ thể ──────────────────────────────────
      ' uc ga ': ' chicken breast ',
      ' dui ga ': ' chicken thigh ',
      ' bap dui ga ': ' chicken thigh drumstick ',
      ' canh ga ': ' chicken wing ',
      ' co ga ': ' chicken neck ',
      ' chan ga ': ' chicken feet ',
      ' da ga ': ' chicken skin ',
      ' luong ga ': ' chicken back ',
      // ── Heo — bộ phận cụ thể ─────────────────────────────────
      ' vai heo ': ' pork shoulder ',
      ' co heo ': ' pork neck ',
      ' than heo ': ' pork loin ',
      ' phi le heo ': ' pork tenderloin ',
      ' suon heo ': ' pork ribs ',
      ' gio heo ': ' pork leg ',
      ' chan heo ': ' pork leg ',
      ' ba chi ': ' pork belly ',
      ' thit heo xay ': ' pork minced ',
      ' thit xay heo ': ' pork minced ',
      ' nac heo ': ' lean pork ',
      // ── Bò — bộ phận cụ thể ──────────────────────────────────
      ' uc bo ': ' beef brisket ',
      ' phi le bo ': ' beef tenderloin sirloin ',
      ' bo phi le ': ' beef tenderloin ',
      ' suon bo ': ' beef ribs short ribs ribeye ',
      ' bap bo ': ' beef shank ',
      ' gau bo ': ' beef flank ',
      ' vai bo ': ' beef chuck ',
      ' thit bo xay ': ' beef minced ',
      ' bo xay ': ' beef minced ',
      // ── Vịt — bộ phận ────────────────────────────────────────
      ' uc vit ': ' duck breast ',
      ' dui vit ': ' duck thigh ',
      ' canh vit ': ' duck wing ',
      // ── Cừu/Dê ───────────────────────────────────────────────
      ' dui cuu ': ' lamb leg ',
      ' suon cuu ': ' lamb ribs ',
      ' dui de ': ' goat leg ',
      // ── Trứng chi tiết ───────────────────────────────────────
      ' long trang ': ' egg white ',
      ' long trang trung ': ' egg white ',
      ' long do trung ': ' egg yolk ',
      ' long do ': ' egg yolk ',
      // ── Hải sản ──────────────────────────────────────────────
      ' ca ': ' fish ',
      ' tom ': ' shrimp ',
      ' cua ': ' crab ',
      ' muc ': ' squid ',
      // ── Ngũ cốc & Tinh bột ───────────────────────────────────
      ' rau ': ' vegetable ',
      ' khoai lang ': ' sweet potato ',
      ' khoai tay ': ' potato ',
      ' khoai mon ': ' taro ',
      ' khoai ': ' potato ',
      ' gao ': ' rice ',
      ' bun ': ' vermicelli ',
      ' pho ': ' noodles ',
      // ── Rau lá & Rau gia vị ──────────────────────────────────
      ' bap cai tim ': ' purple cabbage ',
      ' bap cai ': ' cabbage ',
      ' cai tim ': ' purple cabbage ',
      ' cai xanh ': ' mustard green ',
      ' cai be xanh ': ' mustard green ',
      ' cai thia ': ' chinese cabbage ',
      ' bok choy ': ' chinese cabbage ',
      ' xa lach ': ' lettuce ',
      ' rau muong ': ' morning glory ',
      ' rau bo xoi ': ' spinach ',
      ' bo xoi ': ' spinach ',
      ' bong cai xanh ': ' broccoli ',
      ' bong cai trang ': ' cauliflower ',
      ' bong cai ': ' cauliflower broccoli ',
      ' can tay ': ' celery ',
      ' tia to ': ' perilla ',
      ' hung que ': ' basil ',
      ' rau hung ': ' basil ',
      ' rau ram ': ' vietnamese mint ',
      ' rau mui ': ' coriander ',
      ' rau ngo ': ' coriander cilantro ',
      ' thi la ': ' dill ',
      ' rau ma ': ' pennywort ',
      ' chum ngay ': ' moringa ',
      ' dua cai ': ' mustard green pickled ',
      // ── Củ & Quả Bầu Bí ──────────────────────────────────────
      ' su su ': ' chayote ',
      ' ca rot ': ' carrot ',
      ' ca chua ': ' tomato ',
      ' cu cai trang ': ' radish daikon ',
      ' cu cai do ': ' beetroot ',
      ' cu cai ': ' radish ',
      ' kho qua ': ' bitter melon ',
      ' muop dang ': ' bitter melon ',
      ' muop ': ' luffa ',
      ' bau ': ' bottle gourd ',
      ' bi dao ': ' winter melon ',
      ' bi xanh ': ' winter melon ',
      ' bi do ': ' pumpkin ',
      ' bi ngo ': ' pumpkin ',
      ' dua leo ': ' cucumber ',
      ' dua chuot ': ' cucumber ',
      ' ca tim ': ' eggplant ',
      ' ca phao ': ' eggplant ',
      ' ot ngot ': ' bell pepper ',
      ' ot chuong ': ' bell pepper ',
      ' ot ': ' chili pepper ',
      ' hanh tay ': ' onion ',
      ' hanh khau ': ' shallot ',
      ' cu hanh ': ' shallot ',
      ' hanh la ': ' spring onion ',
      ' hanh hoa ': ' spring onion ',
      ' toi ': ' garlic ',
      ' gung ': ' ginger ',
      ' nghe ': ' turmeric ',
      ' sa ': ' lemongrass ',
      ' ngu cu sen ': ' lotus root ',
      ' cu sen ': ' lotus root ',
      ' cuong sen ': ' lotus stem ',
      ' nang ': ' water chestnut ',
      ' mang ': ' bamboo shoots ',
      ' su hao ': ' kohlrabi ',
      ' san ': ' cassava ',
      ' mang tay ': ' asparagus ',
      // ── Đậu & Hạt ────────────────────────────────────────────
      ' gia do ': ' bean sprouts ',
      ' giao do ': ' bean sprouts ',
      ' dau bap ': ' okra ',
      ' dau dua ': ' long bean ',
      ' dau que ': ' green beans ',
      ' dau co ve ': ' green beans ',
      ' dau ha lan ': ' snow pea peas ',
      ' dau rong ': ' winged bean ',
      // ── Nấm ─────────────────────────────────────────────────
      ' nam so ': ' oyster mushroom ',
      ' nam dong co ': ' shiitake mushroom ',
      ' nam kim cham ': ' enoki mushroom ',
      ' nam meo ': ' wood ear mushroom ',
      ' nam moc nhi ': ' wood ear mushroom ',
      ' nam rom ': ' straw mushroom ',
      ' nam ': ' mushroom ',
      // ── Ngô & Hoa quả rau ─────────────────────────────────────
      ' bap ngo ngot ': ' sweet corn ',
      ' bap ngo ': ' corn ',
      ' ngo ': ' corn ',
      ' hoa chuoi ': ' banana flower ',
      // ── Trái cây ─────────────────────────────────────────────
      ' chuoi ': ' banana ',
      ' xoai ': ' mango ',
      ' dua hau ': ' watermelon ',
      ' dua thom ': ' pineapple ',
      ' qua dua ': ' pineapple ',
      ' thom ': ' pineapple ',
      ' du du ': ' papaya ',
      ' thanh long ': ' dragon fruit ',
      ' mit ': ' jackfruit ',
      ' oi ': ' guava ',
      ' nhan ': ' longan ',
      ' vai ': ' lychee ',
      ' quit ': ' mandarin orange ',
      ' cam ': ' orange ',
      ' buoi ': ' pomelo grapefruit ',
      ' khe ': ' star fruit ',
      ' me ': ' tamarind ',
      ' mang cau xiem ': ' soursop ',
      ' mang cau ta ': ' custard apple ',
      ' chom chom ': ' rambutan ',
      ' sau rieng ': ' durian ',
      ' man ': ' plum ',
      ' hong xiem ': ' sapodilla ',
      ' roi ': ' rose apple ',
      ' tao ta ': ' jujube ',
      ' chanh day ': ' passion fruit ',
      ' dau tay ': ' strawberry ',
      ' qua bo ': ' avocado ',
      ' chanh xanh ': ' lime ',
      ' chanh vang ': ' lemon ',
      ' chanh ': ' lime lemon ',
      ' nuoc dua ': ' coconut water ',
      ' tao ': ' apple jujube ',
      // ── Đồ muối & Lên men ────────────────────────────────────
      ' dua chua ': ' pickled fermented vegetable ',
      ' dua cai chua ': ' pickled mustard green fermented ',
      ' dua cai muoi ': ' pickled mustard sour ',
      ' dua mon ': ' pickled mixed vegetable ',
      ' dua hanh ': ' pickled onion ',
      ' dua giai ': ' pickled young cucumber ',
      ' ca muoi ': ' salted fermented ',
      ' kim chi ': ' kimchi ',
      ' bap cai muoi ': ' kimchi sauerkraut pickled cabbage ',
      ' cu cai muoi ': ' pickled radish ',
      ' mam ': ' fermented paste sauce ',
      ' mam tom ': ' shrimp paste ',
      ' mam ca ': ' fermented fish ',
      ' mam ruoc ': ' shrimp paste ',
      ' muoi ': ' salt pickled ',
      ' chua ': ' sour fermented ',
      ' tom chua ': ' fermented shrimp ',
      ' nem chua ': ' fermented pork roll ',
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
    if (text.contains(' pickled ') ||
        text.contains(' fermented ') ||
        text.contains(' kimchi ') ||
        text.contains(' sauerkraut ') ||
        text.contains(' dua chua ') ||
        text.contains(' mang chua ')) {
      return 'Fermented';
    }
    if (text.contains(' sauce ') ||
        text.contains(' paste ') ||
        text.contains(' condiment ') ||
        text.contains(' nuoc mam ')) {
      return 'Condiments';
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
      'vitamin_c': food.vitaminCFor(grams),
      'vitamin_a': food.vitaminAFor(grams),
      'vitamin_b1': food.vitaminB1For(grams),
      'calcium': food.calciumFor(grams),
      'iron': food.ironFor(grams),
      'fiber': food.fiberFor(grams),
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
