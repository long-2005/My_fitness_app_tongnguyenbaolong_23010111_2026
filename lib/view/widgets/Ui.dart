import 'package:flutter/material.dart';
import 'dart:ui'; // Bắt buộc phải import thư viện này để dùng ImageFilter

class BackgroundModify extends StatelessWidget {
  const BackgroundModify({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Dùng Stack để xếp chồng các lớp hiệu ứng
    return Stack(
      children: [
        // Lớp 1 (Ngoài cùng): Ảnh gốc
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/image/wallhaven-x136yd_1920x1080.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        Positioned.fill(
          child: ColorFiltered(
            // Dùng Ma trận màu Grayscale để loại bỏ mọi màu sắc
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: Container(color: Colors.black.withValues(alpha: 0)), // Bắt buộc phải có Container
          ),
        ),

        // Lớp 3: CHỪA MÀU ĐỎ RA - DÙNG SHADERMASK
        ShaderMask(
          // Đây là bộ lọc màu sắc "thoáng" chỉ cho màu đỏ đi qua
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [Colors.red, Colors.red.withValues(alpha: 0)],
              stops: [0.0, 1.0], // Toàn bộ màn hình đều 'nhìn thấy' màu đỏ
              tileMode: TileMode.mirror,
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstATop, // 'vẽ' màu đỏ lên tấm ảnh
          child: Container(color: Colors.black.withValues(alpha: 0)), // Bắt buộc
        ),

        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Chỉnh độ mờ nhẹ
            child: Container(color: Colors.black.withValues(alpha: 0)),
          ),
        ),
      ],
    );
  }
}
class CardModify extends StatelessWidget {
  const CardModify({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
    );
  }
}
