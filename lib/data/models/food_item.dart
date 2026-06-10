/// **FoodItem** — Thực thể mô tả một loại thực phẩm trong cơ sở dữ liệu dinh dưỡng.
///
/// Lưu thông tin dinh dưỡng cơ bản (calo, protein, chất béo, carbs)
/// và vi chất dinh dưỡng (vitamin, canxi, sắt, chất xơ) cho mọi 100g thực phẩm.
///
/// Có hai nguồn gốc:
/// - Tự động tải từ file JSON nội bộ qua `FoodItem.fromDb(...)`.
/// - Do người dùng tự tạo và được lưu trên Firestore qua `FoodItem.fromFirestore(...)`.
///
/// Các hàm tiện ích như `caloriesFor(grams)`, `proteinFor(grams)`...
/// giúp tính toán lượng dinh dưỡng thực tế theo khối lượng người dùng ăn.
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
    // Micronutrients (per 100g)
    this.fiberPer100g = 0,
    this.calciumMg = 0,
    this.phosphorusMg = 0,
    this.ironMg = 0,
    this.sodiumMg = 0,
    this.potassiumMg = 0,
    this.betaCaroteneMcg = 0,
    this.vitaminAMcg = 0,
    this.vitaminB1Mg = 0,
    this.vitaminCMg = 0,
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

  // Micronutrients
  final double fiberPer100g;
  final double calciumMg;
  final double phosphorusMg;
  final double ironMg;
  final double sodiumMg;
  final double potassiumMg;
  final double betaCaroteneMcg;
  final double vitaminAMcg;
  final double vitaminB1Mg;
  final double vitaminCMg;

  /// Returns true if this item has any micronutrient data.
  bool get hasMicronutrients =>
      fiberPer100g > 0 ||
      calciumMg > 0 ||
      ironMg > 0 ||
      vitaminCMg > 0 ||
      vitaminAMcg > 0 ||
      betaCaroteneMcg > 0 ||
      vitaminB1Mg > 0;

  factory FoodItem.fromDb(Map<String, Object?> map) {
    return FoodItem(
      name: map['name'] as String? ?? 'Unknown food',
      caloriesPer100g: (map['calories'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (map['protein'] as num?)?.toDouble() ?? 0,
      fatPer100g: (map['fat'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (map['carbs'] as num?)?.toDouble() ?? 0,
      searchName: map['search_name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      fiberPer100g: (map['fiber'] as num?)?.toDouble() ?? 0,
      calciumMg: (map['calcium'] as num?)?.toDouble() ?? 0,
      phosphorusMg: (map['phosphorus'] as num?)?.toDouble() ?? 0,
      ironMg: (map['iron'] as num?)?.toDouble() ?? 0,
      sodiumMg: (map['sodium_mg'] as num?)?.toDouble() ?? 0,
      potassiumMg: (map['potassium'] as num?)?.toDouble() ?? 0,
      betaCaroteneMcg: (map['beta_carotene'] as num?)?.toDouble() ?? 0,
      vitaminAMcg: (map['vitamin_a'] as num?)?.toDouble() ?? 0,
      vitaminB1Mg: (map['vitamin_b1'] as num?)?.toDouble() ?? 0,
      vitaminCMg: (map['vitamin_c'] as num?)?.toDouble() ?? 0,
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
      fiberPer100g: (map['fiber'] as num?)?.toDouble() ?? 0,
      calciumMg: (map['calcium'] as num?)?.toDouble() ?? 0,
      phosphorusMg: (map['phosphorus'] as num?)?.toDouble() ?? 0,
      ironMg: (map['iron'] as num?)?.toDouble() ?? 0,
      sodiumMg: (map['sodium_mg'] as num?)?.toDouble() ?? 0,
      potassiumMg: (map['potassium'] as num?)?.toDouble() ?? 0,
      betaCaroteneMcg: (map['beta_carotene'] as num?)?.toDouble() ?? 0,
      vitaminAMcg: (map['vitamin_a'] as num?)?.toDouble() ?? 0,
      vitaminB1Mg: (map['vitamin_b1'] as num?)?.toDouble() ?? 0,
      vitaminCMg: (map['vitamin_c'] as num?)?.toDouble() ?? 0,
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
      'fiber': fiberPer100g,
      'calcium': calciumMg,
      'phosphorus': phosphorusMg,
      'iron': ironMg,
      'sodium_mg': sodiumMg,
      'potassium': potassiumMg,
      'beta_carotene': betaCaroteneMcg,
      'vitamin_a': vitaminAMcg,
      'vitamin_b1': vitaminB1Mg,
      'vitamin_c': vitaminCMg,
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
    double? fiberPer100g,
    double? calciumMg,
    double? phosphorusMg,
    double? ironMg,
    double? sodiumMg,
    double? potassiumMg,
    double? betaCaroteneMcg,
    double? vitaminAMcg,
    double? vitaminB1Mg,
    double? vitaminCMg,
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
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      calciumMg: calciumMg ?? this.calciumMg,
      phosphorusMg: phosphorusMg ?? this.phosphorusMg,
      ironMg: ironMg ?? this.ironMg,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      betaCaroteneMcg: betaCaroteneMcg ?? this.betaCaroteneMcg,
      vitaminAMcg: vitaminAMcg ?? this.vitaminAMcg,
      vitaminB1Mg: vitaminB1Mg ?? this.vitaminB1Mg,
      vitaminCMg: vitaminCMg ?? this.vitaminCMg,
    );
  }

  double caloriesFor(double grams) => caloriesPer100g * grams / 100;
  double proteinFor(double grams) => proteinPer100g * grams / 100;
  double fatFor(double grams) => fatPer100g * grams / 100;
  double carbsFor(double grams) => carbsPer100g * grams / 100;
  double fiberFor(double grams) => fiberPer100g * grams / 100;
  double vitaminCFor(double grams) => vitaminCMg * grams / 100;
  double vitaminAFor(double grams) => vitaminAMcg * grams / 100;
  double vitaminB1For(double grams) => vitaminB1Mg * grams / 100;
  double calciumFor(double grams) => calciumMg * grams / 100;
  double ironFor(double grams) => ironMg * grams / 100;
}
