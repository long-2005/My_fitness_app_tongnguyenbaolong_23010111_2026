import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/models/bmi_record.dart';
import 'package:flutter_application_1/data/models/vitamin_goal.dart';

void main() {
  group('BmiRecord Unit Tests', () {
    test('Calculate BMI, BMR, and TDEE for Male profile (Sedentary)', () {
      final record = BmiRecord.calculate(
        weight: 70.0,
        height: 175.0,
        age: 25,
        gender: 'Male',
        activityLevel: 1.2,
      );
      expect(record.bmi, 22.9);
      expect(record.bmiStatus, 'Normal');
      expect(record.bmr, 1674);
      expect(record.tdee, 2009);
    });

    test('Calculate BMI, BMR, and TDEE for Female profile (Active)', () {
      final record = BmiRecord.calculate(
        weight: 50.0,
        height: 160.0,
        age: 30,
        gender: 'Female',
        activityLevel: 1.55,
      );
      expect(record.bmi, 19.5);
      expect(record.bmiStatus, 'Normal');
      expect(record.bmr, 1189);
      expect(record.tdee, 1843);
    });

    test('BMI Status Boundaries (WHO Standards)', () {
      expect(BmiRecord.getBmiStatus(0.0), 'Ready to calculate');
      expect(BmiRecord.getBmiStatus(-5.0), 'Ready to calculate');
      expect(BmiRecord.getBmiStatus(18.4), 'Underweight');
      expect(BmiRecord.getBmiStatus(18.5), 'Normal');
      expect(BmiRecord.getBmiStatus(24.9), 'Normal');
      expect(BmiRecord.getBmiStatus(25.0), 'Overweight');
      expect(BmiRecord.getBmiStatus(29.9), 'Overweight');
      expect(BmiRecord.getBmiStatus(30.0), 'Obese');
      expect(BmiRecord.getBmiStatus(40.0), 'Obese');
    });
  });

  group('VitaminGoal Unit Tests', () {
    test('Goal for Young Male (Age 25)', () {
      final goal = VitaminGoal.forProfile(age: 25, gender: 'Male');
      expect(goal.vitaminC, 90.0);
      expect(goal.vitaminA, 900.0);
      expect(goal.vitaminB1, 1.2);
      expect(goal.calcium, 1000.0);
      expect(goal.iron, 8.0);
      expect(goal.fiber, 38.0);
    });

    test('Goal for Older Male (Age 55)', () {
      final goal = VitaminGoal.forProfile(age: 55, gender: 'Male');
      expect(goal.fiber, 30.0); // Older males need less fiber
      expect(goal.vitaminC, 90.0);
    });

    test('Goal for Young Female (Age 25)', () {
      final goal = VitaminGoal.forProfile(age: 25, gender: 'Female');
      expect(goal.vitaminC, 75.0);
      expect(goal.vitaminA, 700.0);
      expect(goal.vitaminB1, 1.1);
      expect(goal.calcium, 1000.0);
      expect(goal.iron, 18.0); // Young females need more iron
      expect(goal.fiber, 25.0);
    });

    test('Goal for Older Female (Age 55)', () {
      final goal = VitaminGoal.forProfile(age: 55, gender: 'Female');
      expect(goal.vitaminC, 75.0);
      expect(goal.calcium, 1200.0); // Older females need more calcium
      expect(goal.iron, 8.0); // Older females need less iron
      expect(goal.fiber, 21.0); // Older females need less fiber
    });
  });
}
