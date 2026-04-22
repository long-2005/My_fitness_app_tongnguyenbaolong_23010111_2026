import 'package:flutter/material.dart';
import '../../user/bmi_record.dart';
import '../../services/bmi_service.dart';

class BmiView extends StatefulWidget {
  const BmiView({super.key});

  @override
  State<BmiView> createState() => _BmiViewState();
}

class _BmiViewState extends State<BmiView> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl    = TextEditingController();

  String _gender       = 'Male';
  double _activityLevel = 1.2;
  bool _isLoading      = false;
  BmiRecord? _latestRecord;

  final _bmiService = BmiService();

  static const _kRed   = Color.fromARGB(255, 180, 50, 50);
  static const _kDark  = Color(0xFF1E1E1E);
  static const _poppins = TextStyle(fontFamily: 'Poppins');

  static const _activityOptions = [
    ('Sedentary (office job)',          1.2),
    ('Lightly active (1-3 days/week)',  1.375),
    ('Moderately active (3-5 days/week)', 1.55),
    ('Very active (6-7 days/week)',     1.725),
    ('Extra active (twice a day)',      1.9),
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
        age:    int.parse(_ageCtrl.text.trim()),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  Color _getBmiColor(double bmi) {
    if (bmi <= 0)  return const Color(0xFFE16D6D);
    if (bmi < 18.5) return const Color(0xFF64B5F6);
    if (bmi < 25)  return Colors.greenAccent;
    if (bmi < 30)  return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  String _fmt(DateTime d) =>
      '${_p(d.day)}/${_p(d.month)}/${d.year} ${_p(d.hour)}:${_p(d.minute)}';
  String _p(int n) => n.toString().padLeft(2, '0');

  /// InputDecoration tái sử dụng cho dropdown
  InputDecoration _dropdownDecor(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: _poppins.copyWith(color: Colors.grey),
    prefixIcon: Icon(icon, color: _kRed),
    filled: true,
    fillColor: Colors.black26,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24, width: 1.0)),
    contentPadding: const EdgeInsets.symmetric(vertical: 16),
  );

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('BMI & TDEE Tracker',
            style: _poppins.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color.fromARGB(255, 215, 215, 215),
            )),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(children: [_buildHeroSummary(), _buildInputForm()]),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 5),
                child: Row(children: [
                  const Icon(Icons.history, color: _kRed, size: 22),
                  const SizedBox(width: 8),
                  Text('Measurement History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          )),
                ]),
              ),
            ),
            _buildHistoryList(),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────

  Widget _buildHeroSummary() {
    final r = _latestRecord;
    final bmi       = r?.bmi ?? 0.0;
    final tdee      = r?.tdee ?? 0;
    final bmr       = r?.bmr ?? 0;
    final bmiColor  = _getBmiColor(bmi);
    final bmiStatus = r?.bmiStatus ?? 'Ready to calculate';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 2),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF521313), Color(0xFF1B1212), Color(0xFF121212)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10))],
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('Your latest body metrics',
                          style: _poppins.copyWith(
                            color: Colors.white70, fontSize: 12,
                            fontWeight: FontWeight.w600, letterSpacing: 0.2,
                          )),
                    ),
                    const SizedBox(height: 14),
                    Text(r == null ? 'Track your BMI and calories' : bmiStatus,
                        style: _poppins.copyWith(
                          color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.w800, height: 1.2,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      r == null
                          ? 'Enter your information below to calculate, save, and review your health indicators.'
                          : 'BMI ${bmi.toStringAsFixed(1)} • TDEE $tdee kcal/day • BMR $bmr kcal/day',
                      style: _poppins.copyWith(color: Colors.grey.shade300, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 74, height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [bmiColor.withValues(alpha: 0.95), bmiColor.withValues(alpha: 0.35)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: bmiColor.withValues(alpha: 0.25), blurRadius: 18, spreadRadius: 2)],
                ),
                child: Icon(
                  r == null ? Icons.insights_rounded : Icons.favorite_rounded,
                  color: Colors.white, size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _buildHighlightCard(
                title: 'BMI',
                value: r == null ? '--' : bmi.toStringAsFixed(1),
                subtitle: r == null ? 'Waiting for data' : bmiStatus,
                icon: Icons.speed_rounded, accent: bmiColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHighlightCard(
                title: 'TDEE', value: r == null ? '--' : '$tdee',
                subtitle: 'kcal / day',
                icon: Icons.local_fire_department_rounded,
                accent: const Color(0xFFFF9F43),
              ),
            ),
          ]),
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
          BoxShadow(color: Color.fromARGB(100, 0, 0, 0), blurRadius: 15, spreadRadius: 2, offset: Offset(0, 5)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weight & Height
            Row(children: [
              Expanded(child: _buildTextField(_weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_heightCtrl, 'Height (cm)', Icons.height)),
            ]),
            const SizedBox(height: 16),
            // Age & Gender
            Row(children: [
              Expanded(
                flex: 3,
                child: _buildTextField(_ageCtrl, 'Age', Icons.cake_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  dropdownColor: _kDark,
                  style: _poppins.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: _dropdownDecor('Gender', Icons.person_outline),
                  items: ['Male', 'Female']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Activity Level
            DropdownButtonFormField<double>(
              initialValue: _activityLevel,
              isExpanded: true,
              dropdownColor: _kDark,
              style: _poppins.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              decoration: _dropdownDecor('Activity Level', Icons.fitness_center_outlined),
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
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _calculateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.save_outlined, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Calculate & Save Record',
                            style: _poppins.copyWith(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: Colors.white, letterSpacing: 0.5,
                            )),
                      ]),
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
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Please sign in to sync history.',
                  style: _poppins.copyWith(fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ]),
        ),
      );
    }

    return StreamBuilder<List<BmiRecord>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color.fromARGB(255, 180, 50, 50)),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(children: [
                  Icon(Icons.insert_chart_outlined, size: 60, color: Colors.grey.shade700),
                  const SizedBox(height: 12),
                  Text(
                    'No data found.\nPlease enter your info to start tracking.',
                    textAlign: TextAlign.center,
                    style: _poppins.copyWith(color: Colors.grey.shade500, height: 1.5),
                  ),
                ]),
              ),
            ),
          );
        }
        final records = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _buildHistoryCard(records[i]),
            childCount: records.length,
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(BmiRecord record) {
    final bmiColor = _getBmiColor(record.bmi);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(28, 255, 255, 255), Color.fromARGB(18, 255, 255, 255)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
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
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(_fmt(record.timestamp),
                        style: _poppins.copyWith(
                          color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600,
                        )),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: bmiColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(record.bmiStatus,
                        style: _poppins.copyWith(
                          color: bmiColor, fontWeight: FontWeight.w700,
                          fontSize: 12, letterSpacing: 0.3,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Weight', '${record.weight}kg', Icons.monitor_weight_rounded, Colors.tealAccent),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _buildStatItem('BMI', record.bmi.toString(), Icons.speed_rounded, bmiColor),
                    Container(height: 40, width: 1, color: Colors.white24),
                    _buildStatItem('TDEE', '${record.tdee}kcal', Icons.local_fire_department_rounded, Colors.orangeAccent),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: [
                  _buildInfoChip(Icons.height_rounded, '${record.height.toStringAsFixed(0)} cm'),
                  _buildInfoChip(Icons.cake_rounded, '${record.age} yrs'),
                  _buildInfoChip(Icons.person_rounded, record.gender),
                  _buildInfoChip(Icons.directions_run_rounded, 'Activity x${record.activityLevel}'),
                  _buildInfoChip(Icons.bolt_rounded, 'BMR ${record.bmr} kcal'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: _poppins.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _poppins.copyWith(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: _kRed),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24, width: 1.0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromARGB(255, 133, 20, 20), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '!';
        if (double.tryParse(v) == null) return '!';
        return null;
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(children: [
      Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(value, style: _poppins.copyWith(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
      ]),
      const SizedBox(height: 4),
      Text(label, style: _poppins.copyWith(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildHighlightCard({
    required String title, required String value,
    required String subtitle, required IconData icon, required Color accent,
  }) {
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
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const Spacer(),
            Text(title,
                style: _poppins.copyWith(color: Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          Text(value,
              style: _poppins.copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: _poppins.copyWith(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

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
          Icon(icon, size: 16, color: const Color(0xFFE16D6D)),
          const SizedBox(width: 6),
          Text(text,
              style: _poppins.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
