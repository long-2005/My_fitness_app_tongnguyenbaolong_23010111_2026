import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/view/fontend/sign_in.dart';
import 'package:flutter_application_1/view/fontend/sign_up.dart';
import 'package:flutter_application_1/view/fontend/Home_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HealthApp()); 
}

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String bmi = '/bmi';
  static const String practice = '/practice'; // Thêm route cho bài thực hành
}

class PracticeExerciseView extends StatelessWidget {
  const PracticeExerciseView({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Sử dụng các biến (Yêu cầu 1)
    String traineeName = "Long";
    String workoutGoal = "Tăng cơ & Giảm mỡ";
    int sessionsPerWeek = 3;

    // 2. Sử dụng Collections (List & Map) (Yêu cầu 2)
    List<Map<String, String>> workoutSchedule = [
      {"day": "Thứ 2", "activity": "Chạy bộ & Cardio", "time": "30p"},
      {"day": "Thứ 4", "activity": "Tập Gym (Cơ ngực)", "time": "45p"},
      {"day": "Thứ 6", "activity": "Yoga phục hồi", "time": "60p"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lí: Lịch Tập"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị biến cơ bản yêu cầu 3
            Text("Người tập: $traineeName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Mục tiêu: $workoutGoal"),
            Text("Tần suất: $sessionsPerWeek buổi/tuần"),
            
            const Divider(height: 40),
            const Text("DANH SÁCH BÀI TẬP:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 15),

          //yêu cầu 4
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.fitness_center, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text("${workoutSchedule[0]['day']}: ${workoutSchedule[0]['activity']}"),
                ]),
                Text("TG: ${workoutSchedule[0]['time']}"),
              ],
            ),
            const SizedBox(height: 15),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.fitness_center, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text("${workoutSchedule[1]['day']}: ${workoutSchedule[1]['activity']}"),
                ]),
                Text("TG: ${workoutSchedule[1]['time']}"),
              ],
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.fitness_center, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text("${workoutSchedule[2]['day']}: ${workoutSchedule[2]['activity']}"),
                ]),
                Text("TG: ${workoutSchedule[2]['time']}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ---------------------------------------------------------

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins', 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // Đặt Practice làm trang khởi đầu để thầy cô dễ thấy bài tập
      initialRoute: AppRoutes.practice, 
      routes: {
        AppRoutes.practice: (context) => const PracticeExerciseView(),
        AppRoutes.login: (context) => const SignInView(),
        AppRoutes.signup: (context) => const SignUpView(),
        AppRoutes.home: (context) => const HomeView(),
      },
    );
  }
}