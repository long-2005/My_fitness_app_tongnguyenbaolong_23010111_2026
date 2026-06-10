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
    this.vitaminC = 0.0,
    this.vitaminA = 0.0,
    this.vitaminB1 = 0.0,
    this.calcium = 0.0,
    this.iron = 0.0,
    this.fiber = 0.0,
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
  final double vitaminC;
  final double vitaminA;
  final double vitaminB1;
  final double calcium;
  final double iron;
  final double fiber;

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
      vitaminC: (map['vitamin_c'] as num?)?.toDouble() ?? 0,
      vitaminA: (map['vitamin_a'] as num?)?.toDouble() ?? 0,
      vitaminB1: (map['vitamin_b1'] as num?)?.toDouble() ?? 0,
      calcium: (map['calcium'] as num?)?.toDouble() ?? 0,
      iron: (map['iron'] as num?)?.toDouble() ?? 0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
    );
  }
}
