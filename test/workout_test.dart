import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/models/calisthenics_exercise.dart';
import 'package:flutter_application_1/data/models/planned_exercise.dart';
import 'package:flutter_application_1/data/models/workout_session_record.dart';

void main() {
  group('CalisthenicsExercise Unit Tests', () {
    test('Parse exercise from JSON Map', () {
      final json = {
        'id': 'ex_01',
        'name': 'Push Up',
        'level': 'Beginner',
        'equipment': 'None',
        'primaryMuscles': ['Chest', 'Triceps'],
        'secondaryMuscles': ['Shoulders'],
      };

      final exercise = CalisthenicsExercise.fromJson(json);

      expect(exercise.id, 'ex_01');
      expect(exercise.name, 'Push Up');
      expect(exercise.level, 'Beginner');
      expect(exercise.allMuscles, containsAll(['Chest', 'Triceps', 'Shoulders']));
    });

    test('Parse exercise with missing/null values and fallbacks', () {
      final json = {
        'id': 'ex_02',
        // 'name' and muscles missing
      };

      final exercise = CalisthenicsExercise.fromJson(json);

      expect(exercise.name, 'Unnamed Exercise');
      expect(exercise.level, 'Beginner');
      expect(exercise.primaryMuscles, isEmpty);
      expect(exercise.secondaryMuscles, isEmpty);
    });
  });

  group('PlannedExercise Unit Tests', () {
    test('Serialize and Deserialize PlannedExercise', () {
      final planned = const PlannedExercise(
        exerciseId: 'ex_01',
        sets: 4,
        reps: 12,
        isHold: false,
        holdSeconds: 0,
        restSeconds: 90,
      );

      final map = planned.toMap();
      expect(map['exerciseId'], 'ex_01');
      expect(map['sets'], 4);
      expect(map['restSeconds'], 90);

      final fromMap = PlannedExercise.fromMap(map);
      expect(fromMap.sets, 4);
      expect(fromMap.reps, 12);
      expect(fromMap.restSeconds, 90);
    });
  });

  group('WorkoutSessionRecord Unit Tests', () {
    test('Format duration seconds into human readable string', () {
      final record1 = WorkoutSessionRecord(
        id: 'r_01',
        dayName: 'Monday',
        exercises: const [],
        totalSets: 10,
        durationSeconds: 45,
        completedAt: DateTime.now(),
      );
      expect(record1.formattedDuration, '45s');

      final record2 = WorkoutSessionRecord(
        id: 'r_02',
        dayName: 'Tuesday',
        exercises: const [],
        totalSets: 12,
        durationSeconds: 120,
        completedAt: DateTime.now(),
      );
      expect(record2.formattedDuration, '2m');

      final record3 = WorkoutSessionRecord(
        id: 'r_03',
        dayName: 'Wednesday',
        exercises: const [],
        totalSets: 8,
        durationSeconds: 75,
        completedAt: DateTime.now(),
      );
      expect(record3.formattedDuration, '1m 15s');
    });
  });
}
