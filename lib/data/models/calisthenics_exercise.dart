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
    final primaryList = map['primaryMuscles'] ?? map['primary_muscles'];
    final secondaryList = map['secondaryMuscles'] ?? map['secondary_muscles'];

    return CalisthenicsExercise(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Exercise',
      level: map['level'] as String? ?? 'Beginner',
      equipment: map['equipment'] as String? ?? 'None',
      primaryMuscles: primaryList is List 
          ? List<String>.from(primaryList) 
          : <String>[],
      secondaryMuscles: secondaryList is List 
          ? List<String>.from(secondaryList) 
          : <String>[],
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
