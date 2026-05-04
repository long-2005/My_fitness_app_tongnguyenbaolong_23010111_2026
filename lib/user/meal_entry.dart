import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  const MealEntry({
    required this.id,
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.mealType,
    required this.loggedAt,
    this.description,
    this.isCustom = false,
  });

  final String id;
  final String foodName;
  final String? description;
  final double grams;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String mealType;
  final DateTime loggedAt;
  final bool isCustom;

  factory MealEntry.fromFirestore(String id, Map<String, dynamic> map) {
    final timestamp = map['logged_at'];
    return MealEntry(
      id: id,
      foodName: map['food_name'] as String? ?? 'Unknown food',
      description: map['description'] as String?,
      grams: (map['grams'] as num?)?.toDouble() ?? 0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      mealType: map['meal_type'] as String? ?? 'Snack',
      loggedAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      isCustom: map['is_custom'] as bool? ?? false,
    );
  }
}
