/// ui.dart — Shared UI constants, helpers and micro-widgets.
///
/// Quy tắc: Không chứa bất kỳ business logic hay state nào.
/// Chỉ gồm:
///   • Màu sắc & style constants
///   • Hàm tạo TextStyle tiện lợi
///   • Hàm tạo BoxDecoration/InputDecoration tái sử dụng
///   • Stateless micro-widget dùng nhiều nơi
library;

import 'package:flutter/material.dart';

// ── Màu sắc chủ đạo ─────────────────────────────────────────────────────────

/// Đỏ nhấn chính (BMI view + Calo view).
const kAccentRed = Color(0xFFE16D6D);

/// Đỏ đậm cho gradient button / dropdown background.
const kAccentDeep = Color(0xFF8D1A1A);

/// Nền tối của panel/surface.
const kSurface = Color(0xFF171717);

/// Viền panel mờ dùng chung.
const kPanelBorder = Colors.white10;

/// Shadow panel mặc định.
const kPanelShadow = [
  BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
];

// ── Typography helpers ───────────────────────────────────────────────────────

/// Trả về [TextStyle] Poppins với các tham số tuỳ chọn.
///
/// Dùng thay cho `TextStyle(fontFamily: 'Poppins', ...)` lặp khắp nơi.
TextStyle poppins({
  Color color = Colors.white,
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.normal,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Poppins',
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );
}

// ── BoxDecoration helpers ────────────────────────────────────────────────────

/// Panel nền mờ dùng chung (glassmorphism nhẹ).
///
/// [alpha] – độ mờ của nền trắng (0.0 – 1.0).
/// [radius] – bo góc.
/// [hasShadow] – thêm [kPanelShadow] nếu true.
BoxDecoration panelDecoration({
  double alpha = 0.06,
  double radius = 18,
  bool hasShadow = false,
}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: alpha),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kPanelBorder),
    boxShadow: hasShadow ? kPanelShadow : null,
  );
}

/// Panel nền đặc (màu #121212) dùng cho bottom sheet / gợi ý tìm kiếm.
BoxDecoration solidPanelDecoration({bool hasShadow = false}) {
  return BoxDecoration(
    color: const Color(0xFF121212),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: kPanelBorder),
    boxShadow:
        hasShadow
            ? const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ]
            : null,
  );
}

// ── InputDecoration helpers ──────────────────────────────────────────────────

/// InputDecoration kiểu filled bo góc 16 dùng trong text field / dropdown.
///
/// Dùng trong calo_tracking_view cho [TextField] và [TextFormField].
InputDecoration inputDecoration(
  String label,
  IconData icon, {
  String? hintText,
  Color accentColor = kAccentRed,
  double radius = 16,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
    hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Poppins'),
    prefixIcon: Icon(icon, color: accentColor),
    filled: true,
    fillColor: Colors.black26,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: accentColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}

/// InputDecoration bo góc 12 dùng trong BMI view (text field + dropdown).
InputDecoration inputDecorationSmall(
  String label,
  IconData icon, {
  Color accentColor = kAccentRed,
  double radius = 12,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Poppins'),
    prefixIcon: Icon(icon, color: accentColor),
    filled: true,
    fillColor: Colors.black26,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: Colors.white24, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(
        color: Color.fromARGB(255, 133, 20, 20),
        width: 1.5,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16),
  );
}

// ── ButtonStyle helpers ──────────────────────────────────────────────────────

/// [ButtonStyle] cho [OutlinedButton] với viền trắng mờ.
ButtonStyle outlineButtonStyle({
  double radius = 14,
  EdgeInsetsGeometry? padding,
}) {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white24),
    padding: padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}

// ── Micro-widgets ────────────────────────────────────────────────────────────

/// Chip thông tin macro (calories, protein, fat, carbs…).
class MacroChip extends StatelessWidget {
  const MacroChip(this.title, this.value, {super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$title  $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

/// Chip thông tin nhỏ có icon — dùng trong history card của bmi_view.
class InfoChip extends StatelessWidget {
  const InfoChip(this.icon, this.text, {super.key, this.iconColor = kAccentRed});

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 16, color: iconColor),
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
}

/// Loading indicator căn giữa với màu accent.
class CenteredLoader extends StatelessWidget {
  const CenteredLoader({super.key, this.color = kAccentRed, this.padding = 40});

  final Color color;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: CircularProgressIndicator(color: color),
      ),
    );
  }
}

/// Row thông báo lỗi / cảnh báo có icon + text dùng chung.
class AlertRow extends StatelessWidget {
  const AlertRow({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.iconColor,
  });

  final String message;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? Colors.orange.shade300),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

/// Label tiêu đề section (dùng trong dialog / form).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey.shade300,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    );
  }
}
