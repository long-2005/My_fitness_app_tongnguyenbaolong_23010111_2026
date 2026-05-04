import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/bmi_service.dart';
import '../../services/nutrition_service.dart';
import '../../user/bmi_record.dart';
import '../../user/meal_entry.dart';
import 'bmi_view.dart';
import 'calo_tracking_view.dart';
import 'exercise_library_view.dart';
import 'schedule_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _accent = Color(0xFFE16D6D);
  static const _surface = Color.fromARGB(16, 218, 218, 218);
  static const _navSelected = Color.fromARGB(255, 133, 20, 20);
  static const _cardShadow = [
    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
  ];

  int _selectedIndex = 0;
  final NutritionService _nutritionService = NutritionService.instance;
  final BmiService _bmiService = BmiService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages(user, photoUrl),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF121212),
          indicatorColor: _navSelected,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Poppins',
              );
            }
            return const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontFamily: 'Poppins',
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_weight_outlined),
              selectedIcon: Icon(Icons.monitor_weight),
              label: 'BMI & TDEE',
            ),
            NavigationDestination(
              icon: Icon(Icons.track_changes_outlined),
              selectedIcon: Icon(Icons.track_changes),
              label: 'Calo Track',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }

  // Main tabs rendered by the bottom navigation bar.
  List<Widget> _pages(User? user, String? photoUrl) => [
    CustomScrollView(
      slivers: [
        _buildHomeAppBar(user, photoUrl),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildLatestHealthSection(user),
                const SizedBox(height: 18),
                _buildTodayNutritionSection(user),
              ],
            ),
          ),
        ),
      ],
    ),
    const BmiView(),
    const CaloTrackingView(),
    const ScheduleView(),
    const ExerciseLibraryView(),
  ];

  // Home app bar: greeting, logo, and user avatar.
  Widget _buildHomeAppBar(User? user, String? photoUrl) {
    final username = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final avatar = _avatarImage(photoUrl);

    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      titleSpacing: 20,
      title: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (context) => SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: Text(
                  'Welcome back, $username',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 215, 215, 215),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/image/Gemini_Generated_Image_rym0ohrym0ohrym0.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade900,
              backgroundImage: avatar,
              child: avatar == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // Latest BMI/TDEE summary card from the newest health record.
  Widget _buildLatestHealthSection(User? user) {
    if (user == null) {
      return _buildMessageCard(
        icon: Icons.lock_outline_rounded,
        title: 'Not signed in',
        message:
            'Sign in to display your BMI, TDEE, and latest health records on the Home page.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('health_records')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 180, 50, 50),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyHealthCard();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final double bmi = (data['bmi'] ?? 0).toDouble();
        final int tdee = (data['tdee'] ?? 0).toInt();
        final int bmr = (data['bmr'] ?? 0).toInt();
        final double weight = (data['weight'] ?? 0).toDouble();
        final double height = (data['height'] ?? 0).toDouble();
        final int age = (data['age'] ?? 0).toInt();
        final String gender = data['gender'] ?? 'Unknown';
        final double activityLevel = (data['activity_level'] ?? 0).toDouble();
        final String bmiStatus = data['bmi_status'] ?? _getBmiStatus(bmi);
        final Color bmiColor = _getBmiColor(bmi);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: _accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Latest metrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bmiStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Updated from your most recent health record.',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                height: 1.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: bmiColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: bmiColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          'BMI ${bmi.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: bmiColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOverviewStat(
                          title: 'TDEE',
                          value: '$tdee',
                          unit: 'kcal/day',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF9F43),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOverviewStat(
                          title: 'BMR',
                          value: '$bmr',
                          unit: 'kcal/day',
                          icon: Icons.bolt_rounded,
                          color: const Color(0xFF64B5F6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildInfoChip(
                        Icons.monitor_weight_rounded,
                        '${weight.toStringAsFixed(1)} kg',
                      ),
                      _buildInfoChip(
                        Icons.height_rounded,
                        '${height.toStringAsFixed(0)} cm',
                      ),
                      _buildInfoChip(Icons.cake_rounded, '$age yrs'),
                      _buildInfoChip(Icons.person_rounded, gender),
                      _buildInfoChip(
                        Icons.directions_run_rounded,
                        'Activity x$activityLevel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navSelected,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Update BMI & TDEE',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Daily nutrition summary and comparison with TDEE.
  Widget _buildTodayNutritionSection(User? user) {
    if (user == null) {
      return _buildMessageCard(
        icon: Icons.restaurant_menu_rounded,
        title: 'Daily meal dashboard locked',
        message:
            'Sign in to display today\'s meals, calories, and quick nutrition overview.',
      );
    }

    final mealStream = _nutritionService.getTodayMealEntriesStream();
    final bmiStream = _bmiService.getLatestRecordStream();
    if (mealStream == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<BmiRecord?>(
      stream: bmiStream,
      builder: (context, snapshot) {
        final latestRecord = snapshot.data;

        return StreamBuilder<List<MealEntry>>(
          stream: mealStream,
          builder: (context, mealSnapshot) {
            if (mealSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: _cardDecoration(hasShadow: false),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 180, 50, 50),
                  ),
                ),
              );
            }

            final entries = mealSnapshot.data ?? const <MealEntry>[];
            final calories = entries.fold<double>(
              0,
              (total, item) => total + item.calories,
            );
            final protein = entries.fold<double>(
              0,
              (total, item) => total + item.protein,
            );
            final fat = entries.fold<double>(
              0,
              (total, item) => total + item.fat,
            );
            final carbs = entries.fold<double>(
              0,
              (total, item) => total + item.carbs,
            );
            final balance = latestRecord == null
                ? null
                : calories - latestRecord.tdee;
            final weeklyKgChange = balance == null
                ? null
                : (balance * 7) / 7700;
            final balanceColor = _balanceColor(balance);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu_rounded,
                        color: _accent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s menu',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                        },
                        child: const Text(
                          'Open tracker',
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    Text(
                      'No foods logged today. Use Calo Track to build your plan and show it here.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewStat(
                            title: 'Calories',
                            value: calories.toStringAsFixed(0),
                            unit: 'kcal',
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF9F43),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverviewStat(
                            title: 'Protein',
                            value: protein.toStringAsFixed(1),
                            unit: 'g',
                            icon: Icons.egg_alt_rounded,
                            color: const Color(0xFF64B5F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewStat(
                            title: 'Fat',
                            value: fat.toStringAsFixed(1),
                            unit: 'g',
                            icon: Icons.opacity_rounded,
                            color: const Color(0xFFFFB74D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverviewStat(
                            title: 'Carbs',
                            value: carbs.toStringAsFixed(1),
                            unit: 'g',
                            icon: Icons.grain_rounded,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (latestRecord == null)
                      Text(
                        'Open BMI & TDEE to calculate your maintenance calories before comparing your meal plan.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          height: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildOverviewStat(
                              title: 'Balance',
                              value: balance!.abs().toStringAsFixed(0),
                              unit: 'kcal',
                              icon: balance < 0
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                              color: balanceColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildOverviewStat(
                              title: 'Est. weight',
                              value: _formatKgChange(weeklyKgChange!),
                              unit: 'per week',
                              icon: Icons.monitor_weight_rounded,
                              color: balanceColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _goalSummary(balance, weeklyKgChange),
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                          height: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ...entries.take(4).map(_buildMealPreviewChip),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyHealthCard() {
    return _buildMessageCard(
      icon: Icons.monitor_weight_outlined,
      title: 'No BMI data yet',
      message:
          'Open the BMI & TDEE tab to calculate and save your first record. Your latest metrics will appear here afterward.',
      actionLabel: 'Open BMI tab',
      onAction: () {
        setState(() {
          _selectedIndex = 1;
        });
      },
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(hasShadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _accent, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Reusable stat tile for calories, protein, BMI, TDEE, etc.
  Widget _buildOverviewStat({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$title • $unit',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // Small info chip for weight, gender, age, and similar data.
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // Quick preview for foods logged today.
  Widget _buildMealPreviewChip(MealEntry entry) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: _accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.mealType} • ${entry.grams.toStringAsFixed(0)}g',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              color: Color(0xFFFF9F43),
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // Shared card style to keep the UI consistent and the code shorter.
  BoxDecoration _cardDecoration({bool hasShadow = true}) => BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white10),
    boxShadow: hasShadow ? _cardShadow : null,
  );

  ImageProvider? _avatarImage(String? photoUrl) =>
      photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null;

  Color _balanceColor(double? balance) {
    if (balance == null) {
      return Colors.grey;
    }
    if (balance <= -150) {
      return Colors.greenAccent;
    }
    if (balance >= 150) {
      return const Color(0xFFFFB74D);
    }
    return const Color(0xFF64B5F6);
  }

  String _formatKgChange(double weeklyKgChange) {
    if (weeklyKgChange.abs() < 0.01) {
      return '~0.00';
    }
    final sign = weeklyKgChange > 0 ? '+' : '-';
    return '$sign${weeklyKgChange.abs().toStringAsFixed(2)}';
  }

  String _goalSummary(double balance, double weeklyKgChange) {
    if (balance <= -150) {
      return 'You are under TDEE by about ${balance.abs().toStringAsFixed(0)} kcal today, roughly ${weeklyKgChange.abs().toStringAsFixed(2)} kg loss/week if maintained.';
    }
    if (balance >= 150) {
      return 'You are above TDEE by about ${balance.abs().toStringAsFixed(0)} kcal today, roughly ${weeklyKgChange.abs().toStringAsFixed(2)} kg gain/week if maintained.';
    }
    return 'Your intake is close to maintenance today, so your body weight should stay relatively stable if this pattern continues.';
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    }
    if (bmi < 25) {
      return 'Normal';
    }
    if (bmi < 30) {
      return 'Overweight';
    }
    return 'Obese';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) {
      return const Color(0xFF64B5F6);
    }
    if (bmi < 25) {
      return Colors.greenAccent;
    }
    if (bmi < 30) {
      return const Color(0xFFFFB74D);
    }
    return const Color(0xFFEF5350);
  }
}
