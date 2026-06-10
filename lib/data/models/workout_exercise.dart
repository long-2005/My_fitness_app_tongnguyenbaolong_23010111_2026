/// Public data model for a workout exercise used in the session screen.
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.level,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.sets,
    this.reps = 10,
    this.isHold = false,
    this.holdSeconds = 30,
    this.restSeconds = 60,
  });

  final String id;
  final String name;
  final String level;
  final String equipment;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final int sets;
  final int reps;
  final bool isHold;
  final int holdSeconds;
  final int restSeconds;
}
