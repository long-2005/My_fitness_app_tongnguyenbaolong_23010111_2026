class FoodItem {
  const FoodItem({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    required this.searchName,
    this.category = 'Other',
    this.id,
    this.description,
    this.isCustom = false,
  });

  final String? id;
  final String name;
  final String? description;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;
  final String searchName;
  final String category;
  final bool isCustom;

  factory FoodItem.fromDb(Map<String, Object?> map) {
    return FoodItem(
      name: map['name'] as String? ?? 'Unknown food',
      caloriesPer100g: (map['calories'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (map['protein'] as num?)?.toDouble() ?? 0,
      fatPer100g: (map['fat'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (map['carbs'] as num?)?.toDouble() ?? 0,
      searchName: map['search_name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
    );
  }

  factory FoodItem.fromFirestore(String id, Map<String, dynamic> map) {
    return FoodItem(
      id: id,
      name: map['name'] as String? ?? 'Custom dish',
      description: map['description'] as String?,
      caloriesPer100g: (map['calories'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (map['protein'] as num?)?.toDouble() ?? 0,
      fatPer100g: (map['fat'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (map['carbs'] as num?)?.toDouble() ?? 0,
      searchName: map['search_name'] as String? ?? '',
      category: map['category'] as String? ?? 'Custom',
      isCustom: true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'calories': caloriesPer100g,
      'protein': proteinPer100g,
      'fat': fatPer100g,
      'carbs': carbsPer100g,
      'search_name': searchName,
      'category': category,
      'is_custom': isCustom,
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? carbsPer100g,
    String? searchName,
    String? category,
    bool? isCustom,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      searchName: searchName ?? this.searchName,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  double caloriesFor(double grams) => caloriesPer100g * grams / 100;
  double proteinFor(double grams) => proteinPer100g * grams / 100;
  double fatFor(double grams) => fatPer100g * grams / 100;
  double carbsFor(double grams) => carbsPer100g * grams / 100;
}
