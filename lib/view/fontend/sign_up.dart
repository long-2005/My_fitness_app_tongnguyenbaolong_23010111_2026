import 'dart:ui';
import 'package:flutter/material.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          // 1. NỀN: Giữ ảnh Deku nét (hoặc mờ cực nhẹ 1-2 đơn vị)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/image/wallhaven-x136yd_1920x1080.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              // --- ĐÂY LÀ CHỖ CHỈNH ĐỘ MỜ NHẸ ---
              // Bạn hãy thử thay đổi số 3.0 này để tìm độ mờ ưng ý
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0), 
              
              child: Container(
                color: const Color.fromARGB(6, 254, 254, 254), 
              ),
            ),
          ),
          // 2. NỘI DUNG CHÍNH
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ClipRRect(
                // Bo góc cho cả hiệu ứng mờ bên trong
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  // ĐỘ MỜ ĐỤC: Chỉnh sigma từ 10-15 để thấy rõ độ đục của kính
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      // MÀU TRẮNG ĐỤC: Tăng opacity lên 0.2 - 0.4 để card nhìn "đặc" hơn
                      color:  Color.fromARGB(4, 247, 209, 209),
                      borderRadius: BorderRadius.circular(25),
                      // Viền trắng giúp định hình tấm thẻ rõ ràng hơn
                      border: Border.all(
                        color: const Color.fromARGB(202, 114, 14, 14),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "SIGN UP",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Các ô nhập liệu
                        _buildInput("Email", Icons.email_outlined),
                        const SizedBox(height: 15),
                        _buildInput("Password", Icons.lock_outline, isPass: true),
                        
                        const SizedBox(height: 30),
                        
                        // Nút bấm đặc hơn để nổi bật trên nền mờ
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 215, 213, 213),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: () {},
                          child: const Text("REGISTER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget phụ cho ô nhập liệu kiểu mờ đục
  Widget _buildInput(String label, IconData icon, {bool isPass = false}) {
    return TextField(
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color.fromARGB(24, 0, 0, 0), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}