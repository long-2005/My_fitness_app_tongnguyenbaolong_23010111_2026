/// Dữ liệu của một bài tập thể dục đọc từ file JSON nội bộ.
class CalisthenicsExercise {
  const CalisthenicsExercise({
    required this.id,
    required this.name,
    required this.level,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
  });

  factory CalisthenicsExercise.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return CalisthenicsExercise(
      id: map['id'] as String,
      name: map['name'] as String,
      level: map['level'] as String,
      equipment: map['equipment'] as String,
      primaryMuscles: List<String>.from(map['primaryMuscles'] as List),
      secondaryMuscles: List<String>.from(map['secondaryMuscles'] as List),
    );
  }

  final String id;
  final String name;
  final String level;
  final String equipment;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  Set<String> get allMuscles => {...primaryMuscles, ...secondaryMuscles};
}
