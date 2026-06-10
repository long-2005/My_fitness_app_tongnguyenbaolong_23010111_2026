/// Dữ liệu cấu hình bài tập do người dùng lập kế hoạch cho 1 ngày trong tuần.
class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.isHold = false,
    this.holdSeconds = 30,
    this.restSeconds = 60,
  });

  factory PlannedExercise.fromMap(Map<dynamic, dynamic> map) {
    return PlannedExercise(
      exerciseId: map['exerciseId'] as String,
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      reps: (map['reps'] as num?)?.toInt() ?? 10,
      isHold: map['isHold'] as bool? ?? false,
      holdSeconds: (map['holdSeconds'] as num?)?.toInt() ?? 30,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
    );
  }

  final String exerciseId;
  final int sets;
  final int reps;
  final bool isHold;
  final int holdSeconds;
  final int restSeconds;

  Map<String, dynamic> toMap() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'reps': reps,
    'isHold': isHold,
    'holdSeconds': holdSeconds,
    'restSeconds': restSeconds,
  };
}
