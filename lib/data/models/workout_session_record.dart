// ============================================================
//  MODEL: WorkoutSessionRecord
//  Lưu thông tin một buổi tập đã hoàn thành.
// ============================================================

class WorkoutSessionRecord {
  const WorkoutSessionRecord({
    required this.id,
    required this.dayName,
    required this.exercises,
    required this.totalSets,
    required this.durationSeconds,
    required this.completedAt,
  });

  final String id;
  final String dayName;
  final List<SessionExercise> exercises;
  final int totalSets;
  final int durationSeconds;
  final DateTime completedAt;

  Map<String, dynamic> toMap() => {
    'day_name': dayName,
    'exercises': exercises.map((e) => e.toMap()).toList(),
    'total_sets': totalSets,
    'duration_seconds': durationSeconds,
    'completed_at': completedAt.toIso8601String(),
  };

  factory WorkoutSessionRecord.fromMap(String id, Map<String, dynamic> map) {
    final exList = (map['exercises'] as List<dynamic>?)
            ?.map((e) => SessionExercise.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return WorkoutSessionRecord(
      id: id,
      dayName: (map['day_name'] as String?) ?? '',
      exercises: exList,
      totalSets: (map['total_sets'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }
}

class SessionExercise {
  const SessionExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.isHold,
    required this.holdSeconds,
    required this.primaryMuscles,
  });

  final String name;
  final int sets;
  final int reps;
  final bool isHold;
  final int holdSeconds;
  final List<String> primaryMuscles;

  Map<String, dynamic> toMap() => {
    'name': name,
    'sets': sets,
    'reps': reps,
    'is_hold': isHold,
    'hold_seconds': holdSeconds,
    'primary_muscles': primaryMuscles,
  };

  factory SessionExercise.fromMap(Map<String, dynamic> map) => SessionExercise(
    name: (map['name'] as String?) ?? '',
    sets: (map['sets'] as num?)?.toInt() ?? 0,
    reps: (map['reps'] as num?)?.toInt() ?? 0,
    isHold: (map['is_hold'] as bool?) ?? false,
    holdSeconds: (map['hold_seconds'] as num?)?.toInt() ?? 0,
    primaryMuscles: List<String>.from(map['primary_muscles'] as List? ?? []),
  );
}
