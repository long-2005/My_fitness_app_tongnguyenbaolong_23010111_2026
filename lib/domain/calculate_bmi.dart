class User_info {
  String uid;
  String name;
  double height; 
  double weight; 
  String level;  

  User_info({
    required this.uid,
    required this.name,
    required this.height,
    required this.weight,
    required this.level,
  });

  // Hàm tính BMI nhanh
  double get bmi {
    if (height <= 0) return 0;
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Hàm để chuyển đổi sang Map để lưu lên Firebase sau này
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'height': height,
      'weight': weight,
      'level': level,
    };
  }
}