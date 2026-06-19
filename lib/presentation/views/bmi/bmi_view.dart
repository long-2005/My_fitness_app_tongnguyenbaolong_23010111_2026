import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data/models/bmi_record.dart';
import 'package:flutter_application_1/data/repositories/bmi_repository.dart';
import 'package:flutter_application_1/presentation/widgets/ui.dart' as ui;

class BmiView extends StatefulWidget {
  const BmiView({super.key});

  @override
  State<BmiView> createState() => _BmiViewState();
}

class _BmiViewState extends State<BmiView> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  String _gender = 'Male';
  double _activityLevel = 1.2;
  bool _isLoading = false;
  BmiRecord? _latestRecord;

  final _bmiService = BmiService();

  static const _kRed = Color.fromARGB(255, 180, 50, 50);
  static const _kDark = Color(0xFF1E1E1E);
  static const _poppins = TextStyle(fontFamily: 'Poppins');

  static const _activityOptions = [
    ('Sedentary (office job)', 1.2),
    ('Lightly active (1-3 days/week)', 1.375),
    ('Moderately active (3-5 days/week)', 1.55),
    ('Very active (6-7 days/week)', 1.725),
    ('Extra active (twice a day)', 1.9),
  ];

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _calculateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final record = BmiRecord.calculate(
        weight: double.parse(_weightCtrl.text.trim()),
        height: double.parse(_heightCtrl.text.trim()),
        age: int.parse(_ageCtrl.text.trim()),
        gender: _gender,
        activityLevel: _activityLevel,
      );
      setState(() => _latestRecord = record);
      await _bmiService.saveRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record saved successfully!')),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('permission-denied')
            ? 'Database permission denied. Deploy Firestore rules, then try again.'
            : 'An error occurred: $e';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    try {
      await _bmiService.deleteRecord(recordId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete record: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(String recordId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Delete Record',
          style: _poppins.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this BMI calculation record? This action cannot be undone.',
          style: _poppins.copyWith(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: _poppins.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteRecord(recordId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: _poppins.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Color _getBmiColor(double bmi) {
    if (bmi <= 0) return const Color(0xFFE16D6D);
    if (bmi < 18.5) return const Color(0xFF64B5F6);
    if (bmi < 25) return Colors.greenAccent;
    if (bmi < 30) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  String _fmt(DateTime d) =>
      '${_p(d.day)}/${_p(d.month)}/${d.year} ${_p(d.hour)}:${_p(d.minute)}';
  String _p(int n) => n.toString().padLeft(2, '0');

  /// InputDecoration tái sử dụng cho dropdown — delegate sang ui.dart
  InputDecoration _dropdownDecor(String label, IconData icon) =>
      ui.inputDecorationSmall(label, icon).copyWith(
        labelStyle: _poppins.copyWith(color: Colors.grey),
      );

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'BMI & TDEE Tracker',
          style: _poppins.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color.fromARGB(255, 215, 215, 215),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openEndDrawer(),
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade900,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kRed,
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              setState(() {});
            }
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(children: [_buildHeroSummary(), _buildInputForm()]),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 10,
                  bottom: 5,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: _kRed, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Measurement History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildHistoryList(),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
     ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _buildHeroSummary() {
    final r = _latestRecord;
    final bmi = r?.bmi ?? 0.0;
    final tdee = r?.tdee ?? 0;
    final bmr = r?.bmr ?? 0;
    final bmiColor = _getBmiColor(bmi);
    final bmiStatus = r?.bmiStatus ?? 'Ready to calculate';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 2),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF521313), Color(0xFF1B1212), Color(0xFF121212)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Your latest body metrics',
                        style: _poppins.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      r == null ? 'Track your BMI and calories' : bmiStatus,
                      style: _poppins.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r == null
                          ? 'Enter your information below to calculate, save, and review your health indicators.'
                          : 'BMI ${bmi.toStringAsFixed(1)} • TDEE $tdee kcal/day • BMR $bmr kcal/day',
                      style: _poppins.copyWith(
                        color: Colors.grey.shade300,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                // _BmiHighlightCard: StatelessWidget → không rebuild khi state ngoài thay đổi.
                child: _BmiHighlightCard(
                  title: 'BMI',
                  value: r == null ? '--' : bmi.toStringAsFixed(1),
                  subtitle: r == null ? 'Waiting for data' : bmiStatus,
                  icon: Icons.speed_rounded,
                  accent: bmiColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BmiHighlightCard(
                  title: 'TDEE',
                  value: r == null ? '--' : '$tdee',
                  subtitle: 'kcal / day',
                  icon: Icons.local_fire_department_rounded,
                  accent: const Color(0xFFFF9F43),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(16, 218, 218, 218),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(100, 0, 0, 0),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: _kRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Body details',
                    style: _poppins.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your latest measurements to calculate BMI, BMR and TDEE.',
              style: _poppins.copyWith(
                color: Colors.grey.shade400,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;
                final gap = isNarrow
                    ? const SizedBox(height: 14)
                    : const SizedBox(width: 14);
                final weight = _buildTextField(
                  _weightCtrl,
                  'Weight',
                  Icons.monitor_weight_outlined,
                  suffix: 'kg',
                );
                final height = _buildTextField(
                  _heightCtrl,
                  'Height',
                  Icons.height,
                  suffix: 'cm',
                );
                final age = _buildTextField(
                  _ageCtrl,
                  'Age',
                  Icons.cake_outlined,
                  suffix: 'yrs',
                  allowDecimal: false,
                );
                final gender = DropdownButtonFormField<String>(
                  initialValue: _gender,
                  dropdownColor: _kDark,
                  style: _poppins.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _dropdownDecor('Gender', Icons.person_outline),
                  items: ['Male', 'Female']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                );

                return Column(
                  children: [
                    isNarrow
                        ? Column(children: [weight, gap, height])
                        : Row(
                            children: [
                              Expanded(child: weight),
                              gap,
                              Expanded(child: height),
                            ],
                          ),
                    const SizedBox(height: 14),
                    isNarrow
                        ? Column(children: [age, gap, gender])
                        : Row(
                            children: [
                              Expanded(flex: 3, child: age),
                              gap,
                              Expanded(flex: 4, child: gender),
                            ],
                          ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              initialValue: _activityLevel,
              isExpanded: true,
              dropdownColor: _kDark,
              style: _poppins.copyWith(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: _dropdownDecor(
                'Activity Level',
                Icons.fitness_center_outlined,
              ),
              items: _activityOptions
                  .map((o) => DropdownMenuItem(value: o.$2, child: Text(o.$1)))
                  .toList(),
              onChanged: (v) => setState(() => _activityLevel = v!),
            ),
            const SizedBox(height: 28),
            // Submit button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 133, 20, 20), Color(0xFFB41414)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _calculateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_outlined, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Calculate & Save Record',
                            style: _poppins.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final stream = _bmiService.getRecordsStream();

    if (stream == null) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(20, 218, 218, 218),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: const ui.AlertRow(message: 'Please sign in to sync history.'),
        ),
      );
    }

    return StreamBuilder<List<BmiRecord>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: ui.CenteredLoader(color: Color.fromARGB(255, 180, 50, 50)),
          );
        }
        if (snapshot.hasError) {
          final permissionDenied = snapshot.error.toString().contains(
            'permission-denied',
          );
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(20, 218, 218, 218),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ui.AlertRow(
                  icon: Icons.cloud_off_rounded,
                  message: permissionDenied
                      ? 'Database permission denied. Deploy Firestore rules to sync history.'
                      : 'Could not load measurement history.',
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.insert_chart_outlined,
                      size: 60,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No data found.\nPlease enter your info to start tracking.',
                      textAlign: TextAlign.center,
                      style: _poppins.copyWith(
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final records = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            // Dùng StatelessWidget _BmiHistoryCard để tránh rebuild toàn bộ list.
            (context, i) => _BmiHistoryCard(
              record: records[i],
              onDelete: _showDeleteConfirmation,
            ),
            childCount: records.length,
          ),
        );
      },
    );
  }

  // _buildHistoryCard → đã tách thành _BmiHistoryCard (StatelessWidget) ở cuối file.

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    required String suffix,
    bool allowDecimal = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      style: _poppins.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: ui.inputDecorationSmall(label, icon).copyWith(
        fillColor: Colors.white.withValues(alpha: 0.06),
        suffixText: suffix,
        suffixStyle: _poppins.copyWith(
          color: Colors.grey.shade400,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        helperText: ' ',
        helperStyle: const TextStyle(height: 0.5),
        errorMaxLines: 2,
      ),
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return 'Required';
        final number = double.tryParse(value);
        if (number == null) return 'Enter a valid number';
        if (number <= 0) return 'Must be greater than 0';
        return null;
      },
    );
  }

  // _buildStatItem → đã tách thành _BmiStatItem (StatelessWidget) ở cuối file.

  // _buildHighlightCard → đã tách thành _BmiHighlightCard (StatelessWidget) ở cuối file.

  // _buildInfoChip đã được thay bằng ui.InfoChip — xem ui.dart
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIVATE STATELESS WIDGETS
// Tách ra khỏi _BmiViewState để tránh rebuild không cần thiết khi state thay
// đổi ở nơi khác trong cây widget. Mỗi widget chỉ rebuild khi đúng prop
// của nó thay đổi.
// ═══════════════════════════════════════════════════════════════════════════

// Helper dùng trong _BmiHistoryCard.
String _bmiP(int n) => n.toString().padLeft(2, '0');
String _bmiFormatDate(DateTime d) =>
    '${_bmiP(d.day)}/${_bmiP(d.month)}/${d.year} ${_bmiP(d.hour)}:${_bmiP(d.minute)}';

Color _bmiGetColor(double bmi) {
  if (bmi <= 0) return const Color(0xFFE16D6D);
  if (bmi < 18.5) return const Color(0xFF64B5F6);
  if (bmi < 25) return Colors.greenAccent;
  if (bmi < 30) return const Color(0xFFFFB74D);
  return const Color(0xFFEF5350);
}

const _kBmiPoppins = TextStyle(fontFamily: 'Poppins');

/// Card lịch sử một lần đo BMI — StatelessWidget để tránh rebuild thừa.
class _BmiHistoryCard extends StatelessWidget {
  const _BmiHistoryCard({required this.record, this.onDelete});

  final BmiRecord record;
  final Function(String)? onDelete;

  @override
  Widget build(BuildContext context) {
    final bmiColor = _bmiGetColor(record.bmi);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(28, 255, 255, 255),
            Color.fromARGB(18, 255, 255, 255),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _bmiFormatDate(record.timestamp),
                        style: _kBmiPoppins.copyWith(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: bmiColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: bmiColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          record.bmiStatus,
                          style: _kBmiPoppins.copyWith(
                            color: bmiColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (onDelete != null && record.id != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          tooltip: 'Delete record',
                          onPressed: () => onDelete!(record.id!),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BmiStatItem(
                      label: 'Weight',
                      value: '${record.weight}kg',
                      icon: Icons.monitor_weight_rounded,
                      color: Colors.tealAccent,
                    ),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _BmiStatItem(
                      label: 'BMI',
                      value: record.bmi.toString(),
                      icon: Icons.speed_rounded,
                      color: bmiColor,
                    ),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _BmiStatItem(
                      label: 'TDEE',
                      value: '${record.tdee}kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ui.InfoChip(
                    Icons.height_rounded,
                    '${record.height.toStringAsFixed(0)} cm',
                  ),
                  ui.InfoChip(Icons.cake_rounded, '${record.age} yrs'),
                  ui.InfoChip(Icons.person_rounded, record.gender),
                  ui.InfoChip(
                    Icons.directions_run_rounded,
                    'Activity x${record.activityLevel}',
                  ),
                  ui.InfoChip(Icons.bolt_rounded, 'BMR ${record.bmr} kcal'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat item trong history card — StatelessWidget để tránh rebuild thừa.
class _BmiStatItem extends StatelessWidget {
  const _BmiStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: _kBmiPoppins.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: _kBmiPoppins.copyWith(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Highlight card (BMI / TDEE) trong hero summary — StatelessWidget.
class _BmiHighlightCard extends StatelessWidget {
  const _BmiHighlightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: _kBmiPoppins.copyWith(
                  color: Colors.grey.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: _kBmiPoppins.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: _kBmiPoppins.copyWith(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
