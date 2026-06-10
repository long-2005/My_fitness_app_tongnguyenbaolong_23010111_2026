import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/l10n/app_strings.dart';
import 'package:flutter_application_1/data/repositories/auth_session_repository.dart';
import 'package:flutter_application_1/data/repositories/bmi_repository.dart';
import 'package:flutter_application_1/data/repositories/nutrition_repository.dart';
import 'package:flutter_application_1/data/models/bmi_record.dart';
import 'package:flutter_application_1/data/models/meal_entry.dart';
import '../../../main.dart';
import 'package:flutter_application_1/presentation/views/bmi/bmi_view.dart';
import 'package:flutter_application_1/presentation/views/nutrition/calo_tracking_view.dart';
import 'package:flutter_application_1/presentation/views/workout/schedule_view.dart';
import 'package:flutter_application_1/presentation/views/settings/settings_view.dart';
import 'package:flutter_application_1/presentation/views/progress/progress_view.dart';

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  final NutritionService _nutritionService = NutritionService.instance;
  final BmiService _bmiService = BmiService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final s = AppStrings.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      endDrawer: _buildProfileDrawer(user),
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: s.homeTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.monitor_weight_outlined),
              selectedIcon: const Icon(Icons.monitor_weight),
              label: s.bmiTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.track_changes_outlined),
              selectedIcon: const Icon(Icons.track_changes),
              label: s.caloTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: s.scheduleTab,
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
                const SizedBox(height: 18),
                const ProgressView(embedded: true),
              ],
            ),
          ),
        ),
      ],
    ),
    const BmiView(),
    const CaloTrackingView(),
    const ScheduleView(),
  ];

  // Home app bar: greeting, logo, and user avatar.
  Widget _buildHomeAppBar(User? user, String? photoUrl) {
    final s = AppStrings.of(context);
    final username = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final avatar = _avatarImage(photoUrl);

    return SliverAppBar(
      automaticallyImplyLeading: false,
      actions: const [SizedBox.shrink()],
      pinned: true,
      backgroundColor: const Color(0xFF0F0F0F),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
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
                  '${s.welcomeBack} $username',
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
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade900,
                backgroundImage: avatar,
                child: avatar == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Right side profile drawer ───────────────────────────────────────────
  Widget _buildProfileDrawer(User? user) {
    final s = AppStrings.of(context);
    final photoUrl = user?.photoURL;
    final avatar = _avatarImage(photoUrl);
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final email = user?.email ?? '';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF851414).withValues(alpha: 0.85),
                    const Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: avatar,
                    child: avatar == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 36,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Menu items ──
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              label: s.settings,
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.help_outline_rounded,
              label: s.helpSupport,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.helpComingSoon),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF333333),
                  ),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withValues(alpha: 0.1)),
            ),

            // ── Sign Out ──
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              label: 'log out',
              color: _accent,
              onTap: () => _showSignOutDialog(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFFD7D7D7),
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    final s = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.signOutConfirmTitle,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          s.signOutConfirmMessage,
          style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.cancel,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close drawer
              await AuthSessionRepository.signOut();
              if (mounted) {
                await Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF851414),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              s.signOut,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Latest BMI/TDEE summary card from the newest health record.
  Widget _buildLatestHealthSection(User? user) {
    final s = AppStrings.of(context);
    if (user == null) {
      return _buildMessageCard(
        icon: Icons.lock_outline_rounded,
        title: s.notSignedIn,
        message: s.signInToSeeMetrics,
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
                  s.latestMetrics,
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
    final s = AppStrings.of(context);
    if (user == null) {
      return _buildMessageCard(
        icon: Icons.restaurant_menu_rounded,
        title: s.dailyMealLocked,
        message: s.signInToSeeMeals,
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
            final calorieGoal = latestRecord?.tdee.toDouble() ?? 2930.0;
            final caloriesLeft = calorieGoal - calories;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(hasShadow: false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today',
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
                      s.noFoodsLogged,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    )
                  else ...[
                    _homeCaloriesPanel(calories, calorieGoal, caloriesLeft),
                    const SizedBox(height: 10),
                    _homeMacrosPanel(carbs: carbs, fat: fat, protein: protein),
                    if (latestRecord == null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Add BMI & TDEE to compare against your calorie goal.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          height: 1.5,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ...entries.take(3).map(_buildMealPreviewChip),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _homeCaloriesPanel(
    double calories,
    double calorieGoal,
    double caloriesLeft,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calories',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${calories.toStringAsFixed(0)} cal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${calorieGoal.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Text(
                caloriesLeft >= 0
                    ? '${caloriesLeft.toStringAsFixed(0)} left'
                    : '${caloriesLeft.abs().toStringAsFixed(0)} over',
                style: TextStyle(
                  color: caloriesLeft >= 0 ? Colors.white70 : _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HomeCyberpunkProgressBar(
            value: (calories / calorieGoal).clamp(0.0, 1.0),
            color: _accent,
            trackColor: Colors.white.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }

  Widget _homeMacrosPanel({
    required double carbs,
    required double fat,
    required double protein,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _homeMacroMeter(
              label: 'Carbs',
              value: carbs,
              goal: 366,
              color: const Color(0xFF37D5C8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _homeMacroMeter(
              label: 'Fat',
              value: fat,
              goal: 98,
              color: const Color(0xFF8E24AA),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _homeMacroMeter(
              label: 'Protein',
              value: protein,
              goal: 146,
              color: const Color(0xFFFFB74D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeMacroMeter({
    required String label,
    required double value,
    required double goal,
    required Color color,
  }) {
    final safeGoal = goal <= 0 ? 1.0 : goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${value.toStringAsFixed(0)} g',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
                TextSpan(
                  text: ' / ${safeGoal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _HomeCyberpunkProgressBar(
          value: (value / safeGoal).clamp(0.0, 1.0),
          color: color,
          height: 7,
          trackColor: Colors.white.withValues(alpha: 0.12),
        ),
      ],
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

class _HomeCyberpunkProgressBar extends StatelessWidget {
  const _HomeCyberpunkProgressBar({
    required this.value,
    required this.color,
    required this.trackColor,
    this.height = 8,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _HomeCyberpunkProgressPainter(
          value: value.clamp(0.0, 1.0),
          color: color,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _HomeCyberpunkProgressPainter extends CustomPainter {
  const _HomeCyberpunkProgressPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.75), color],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final track = Path()
      ..moveTo(5, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - 5, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(track, trackPaint);

    final fillWidth = (size.width * value).clamp(0.0, size.width);
    if (fillWidth <= 0) return;

    final fill = Path()
      ..moveTo(5, 0)
      ..lineTo(fillWidth, 0)
      ..lineTo((fillWidth - 5).clamp(0.0, size.width), size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _HomeCyberpunkProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
