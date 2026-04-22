class BmiRecord {
  // Dữ liệu đầu vào
  final double weight;
  final double height;
  final int age;
  final String gender;
  final double activityLevel;

  // ── Kết quả tính toán ─────────────────────────────────────
  final double bmi;       // Chỉ số BMI
  final String bmiStatus; // Phân loại BMI
  final int bmr;          // Basal Metabolic Rate (kcal/ngày)
  final int tdee;         // Total Daily Energy Expenditure (kcal/ngày)

  final DateTime timestamp;

  BmiRecord({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.bmi,
    required this.bmiStatus,
    required this.bmr,
    required this.tdee,
    required this.timestamp,
  });

  /// Nhận dữ liệu thô → tính bmi, bmr, tdee → trả về BmiRecord đầy đủ
  factory BmiRecord.calculate({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required double activityLevel,
  }) {
    // Tính BMI
    final double heightM = height / 100;
    final double bmiVal =
        double.parse((weight / (heightM * heightM)).toStringAsFixed(1));

    // Tính BMR theo công thức Mifflin-St Jeor
    final double bmrVal = gender == 'Male'
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    final int tdeeVal = (bmrVal * activityLevel).round();

    return BmiRecord(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      bmi: bmiVal,
      bmiStatus: getBmiStatus(bmiVal),
      bmr: bmrVal.round(),
      tdee: tdeeVal,
      timestamp: DateTime.now(),
    );
  }

  /// Tạo BmiRecord từ Map đọc từ Firestore
  factory BmiRecord.fromMap(Map<String, dynamic> map, DateTime date) {
    final double bmiVal = (map['bmi'] as num?)?.toDouble() ?? 0.0;
    return BmiRecord(
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] as String? ?? 'Unknown',
      activityLevel: (map['activity_level'] as num?)?.toDouble() ?? 1.2,
      bmi: bmiVal,
      bmiStatus: map['bmi_status'] as String? ?? getBmiStatus(bmiVal),
      bmr: (map['bmr'] as num?)?.toInt() ?? 0,
      tdee: (map['tdee'] as num?)?.toInt() ?? 0,
      timestamp: date,
    );
  }

  /// Chuyển thành Map để lưu lên Firestore
  Map<String, dynamic> toMap() => {
        'weight': weight,
        'height': height,
        'age': age,
        'gender': gender,
        'activity_level': activityLevel,
        'bmi': bmi,
        'bmi_status': bmiStatus,
        'bmr': bmr,
        'tdee': tdee,
        'timestamp': timestamp,
      };

  static String getBmiStatus(double bmi) {
    if (bmi <= 0) return 'Ready to calculate';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}
