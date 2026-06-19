import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/data/models/bmi_record.dart';
import 'package:flutter_application_1/data/models/food_item.dart';
import 'package:flutter_application_1/data/models/meal_entry.dart';

void main() {
  group('Firebase ORM (Mapping) & Exception Handling Unit Tests', () {
    
    // ── 1. Kiểm thử ORM cho MealEntry ────────────────────────
    test('MealEntry ORM complete serialization and deserialization cycle', () {
      final loggedAt = DateTime(2026, 6, 19, 12, 0);
      
      final meal = MealEntry(
        id: 'test_meal_123',
        foodName: 'Grilled Chicken Breast',
        description: 'High protein lunch',
        grams: 250.0,
        calories: 412.5,
        protein: 77.5,
        fat: 9.0,
        carbs: 0.0,
        mealType: 'Lunch',
        loggedAt: loggedAt,
        isCustom: true,
        vitaminC: 1.5,
        vitaminA: 10.0,
        vitaminB1: 0.2,
        calcium: 30.0,
        iron: 2.5,
        fiber: 0.0,
      );

      // Serialize (Object -> Map)
      final map = meal.toMap();
      
      expect(map['food_name'], 'Grilled Chicken Breast');
      expect(map['description'], 'High protein lunch');
      expect(map['grams'], 250.0);
      expect(map['calories'], 412.5);
      expect(map['protein'], 77.5);
      expect(map['fat'], 9.0);
      expect(map['carbs'], 0.0);
      expect(map['meal_type'], 'Lunch');
      expect(map['logged_at'], loggedAt);
      expect(map['is_custom'], isTrue);
      expect(map['vitamin_c'], 1.5);
      expect(map['vitamin_a'], 10.0);
      expect(map['vitamin_b1'], 0.2);
      expect(map['calcium'], 30.0);
      expect(map['iron'], 2.5);
      expect(map['fiber'], 0.0);

      // Deserialize (Map -> Object)
      // Giả lập Timestamp từ Firestore
      final firestoreMap = Map<String, dynamic>.from(map);
      firestoreMap['logged_at'] = Timestamp.fromDate(loggedAt);
      
      final parsedMeal = MealEntry.fromFirestore('test_meal_123', firestoreMap);
      
      expect(parsedMeal.id, 'test_meal_123');
      expect(parsedMeal.foodName, 'Grilled Chicken Breast');
      expect(parsedMeal.description, 'High protein lunch');
      expect(parsedMeal.grams, 250.0);
      expect(parsedMeal.calories, 412.5);
      expect(parsedMeal.protein, 77.5);
      expect(parsedMeal.fat, 9.0);
      expect(parsedMeal.carbs, 0.0);
      expect(parsedMeal.mealType, 'Lunch');
      expect(parsedMeal.loggedAt, loggedAt);
      expect(parsedMeal.isCustom, isTrue);
      expect(parsedMeal.vitaminC, 1.5);
      expect(parsedMeal.vitaminA, 10.0);
      expect(parsedMeal.vitaminB1, 0.2);
      expect(parsedMeal.calcium, 30.0);
      expect(parsedMeal.iron, 2.5);
      expect(parsedMeal.fiber, 0.0);
    });

    // ── 2. Kiểm thử khả năng bắt lỗi dữ liệu bẩn / thiếu của BmiRecord ──────
    test('BmiRecord.fromMap parses safely with missing or dirty Firestore data', () {
      final testDate = DateTime.now();
      
      // Trường hợp 1: Dữ liệu trống rỗng (empty map)
      final emptyMap = <String, dynamic>{};
      final recordFromEmpty = BmiRecord.fromMap(emptyMap, testDate, 'empty_id');
      
      expect(recordFromEmpty.id, 'empty_id');
      expect(recordFromEmpty.weight, 0.0);
      expect(recordFromEmpty.height, 0.0);
      expect(recordFromEmpty.age, 0);
      expect(recordFromEmpty.gender, 'Unknown');
      expect(recordFromEmpty.activityLevel, 1.2);
      expect(recordFromEmpty.bmi, 0.0);
      expect(recordFromEmpty.bmiStatus, 'Ready to calculate');
      expect(recordFromEmpty.bmr, 0);
      expect(recordFromEmpty.tdee, 0);
      expect(recordFromEmpty.timestamp, testDate);

      // Trường hợp 2: Sai kiểu dữ liệu (Double truyền dạng Int hoặc ngược lại)
      final dirtyMap = <String, dynamic>{
        'weight': 70, // Int thay vì Double
        'height': 175.5,
        'age': 25.5, // Double thay vì Int
        'gender': 'Male',
        'activity_level': 1, // Int thay vì Double
        'bmi': 22.7,
        'bmr': 1600.0, // Double thay vì Int
      };
      
      final recordFromDirty = BmiRecord.fromMap(dirtyMap, testDate, 'dirty_id');
      expect(recordFromDirty.weight, 70.0);
      expect(recordFromDirty.height, 175.5);
      expect(recordFromDirty.age, 25);
      expect(recordFromDirty.activityLevel, 1.0);
      expect(recordFromDirty.bmr, 1600);
    });

    // ── 3. Kiểm thử khả năng bắt lỗi dữ liệu bẩn của FoodItem ─────────────────
    test('FoodItem parses safely with null or dirty types', () {
      final dbMap = <String, dynamic>{
        'name': null, // null name
        'calories': 150, // int
        'protein': 12.5,
        'fat': 2, // int
        'carbs': 40.5,
        'search_name': null,
      };

      final food = FoodItem.fromDb(dbMap);
      expect(food.name, 'Unknown food');
      expect(food.caloriesPer100g, 150.0);
      expect(food.fatPer100g, 2.0);
      expect(food.searchName, '');
      expect(food.category, 'Other');
    });

    // ── 4. Kiểm thử các ràng buộc đầu vào ngoại lệ (Exception Validation) ──────
    test('BmiRecord.calculate throws ArgumentError for invalid parameters', () {
      // Cân nặng hợp lệ nhưng chiều cao bằng 0
      expect(
        () => BmiRecord.calculate(
          weight: 60.0,
          height: 0.0,
          age: 20,
          gender: 'Female',
          activityLevel: 1.2,
        ),
        throwsArgumentError,
      );

      // Cân nặng âm
      expect(
        () => BmiRecord.calculate(
          weight: -10.0,
          height: 160.0,
          age: 25,
          gender: 'Female',
          activityLevel: 1.2,
        ),
        throwsArgumentError,
      );

      // Tuổi bằng 0
      expect(
        () => BmiRecord.calculate(
          weight: 55.0,
          height: 165.0,
          age: 0,
          gender: 'Male',
          activityLevel: 1.55,
        ),
        throwsArgumentError,
      );
    });
  });
}
