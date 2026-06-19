import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/models/food_item.dart';
import 'package:flutter_application_1/data/models/meal_entry.dart';

void main() {
  group('FoodItem & Nutrition Unit Tests', () {
    const apple = FoodItem(
      name: 'Apple',
      caloriesPer100g: 52.0,
      proteinPer100g: 0.3,
      fatPer100g: 0.2,
      carbsPer100g: 14.0,
      searchName: 'apple',
      category: 'Fruits',
      fiberPer100g: 2.4,
      vitaminCMg: 4.6,
    );

    test('Calculate nutrients based on weight (grams)', () {
      // Test for 200g of Apple
      expect(apple.caloriesFor(200), 104.0);
      expect(apple.proteinFor(200), 0.6);
      expect(apple.fatFor(200), 0.4);
      expect(apple.carbsFor(200), 28.0);
      expect(apple.fiberFor(200), 4.8);
      expect(apple.vitaminCFor(200), 9.2);
    });

    test('Verify micronutrient flag indicator', () {
      expect(apple.hasMicronutrients, isTrue);

      const pureSugar = FoodItem(
        name: 'Sugar',
        caloriesPer100g: 387.0,
        proteinPer100g: 0.0,
        fatPer100g: 0.0,
        carbsPer100g: 100.0,
        searchName: 'sugar',
      );
      expect(pureSugar.hasMicronutrients, isFalse);
    });

    test('FoodItem model mapping to and from Firestore', () {
      final map = apple.toFirestore();
      expect(map['name'], 'Apple');
      expect(map['calories'], 52.0);
      expect(map['category'], 'Fruits');

      final food = FoodItem.fromFirestore('test_id', map);
      expect(food.id, 'test_id');
      expect(food.name, 'Apple');
      expect(food.isCustom, isTrue);
      expect(food.fiberPer100g, 2.4);
    });
  });
}
