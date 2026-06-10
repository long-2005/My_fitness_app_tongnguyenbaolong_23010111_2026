class VitaminGoal {
  final double vitaminC;   // mg
  final double vitaminA;   // mcg
  final double vitaminB1;  // mg
  final double calcium;    // mg
  final double iron;       // mg
  final double fiber;      // g

  const VitaminGoal({
    required this.vitaminC,
    required this.vitaminA,
    required this.vitaminB1,
    required this.calcium,
    required this.iron,
    required this.fiber,
  });

  factory VitaminGoal.forProfile({required int age, required String gender}) {
    // Defaults based on adult male
    double vitC = 90.0;
    double vitA = 900.0;
    double vitB1 = 1.2;
    double calc = 1000.0;
    double iron = 8.0;
    double fiber = 38.0;

    if (gender.toLowerCase() == 'female') {
      vitC = 75.0;
      vitA = 700.0;
      vitB1 = 1.1;
      
      if (age >= 51) {
        calc = 1200.0;
        iron = 8.0;
        fiber = 21.0;
      } else {
        calc = 1000.0;
        iron = 18.0;
        fiber = 25.0;
      }
    } else {
      // Male
      if (age >= 51) {
        fiber = 30.0;
      }
    }

    return VitaminGoal(
      vitaminC: vitC,
      vitaminA: vitA,
      vitaminB1: vitB1,
      calcium: calc,
      iron: iron,
      fiber: fiber,
    );
  }
}
