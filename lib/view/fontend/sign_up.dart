import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/Ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Future<void> _handleSignUp() async {
    // 1. Get data from Controllers
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Basic Validation
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Check if passwords match
    if (password != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Create account on Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 3. Get the UID of the newly created user
      String uid = userCredential.user!.uid;

      // 4. Save additional information to Firestore
      // NOTE (Phần thêm lại): Lưu thêm trường 'uid' và 'role' vào cơ sở dữ liệu để tiện quản lý phân quyền sau này!
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid, // NOTE: thêm uid 
        'fullName': name,
        'email': email,
        'createdAt': DateTime.now(),
        'role': 'user', // NOTE: thêm role mặc định là user
      });

      if (!mounted) return;
      debugPrint("Registration and database save successful!");
      
      // Navigate to the main screen or show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Handle Auth Errors
      debugPrint("Auth Error: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Registration failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Handle System Errors
      debugPrint("System Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("System error occurred during registration"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  bool _isObscure = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BackgroundModify(),

          Positioned.fill(
            // fill để chiếm hết không gian giúp căn giữa dễ hơn
            child: SafeArea(
              child: SingleChildScrollView(
                // Quan trọng: Giúp cuộn trang khi hiện bàn phím
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    // Tiêu đề
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2),

                    const SizedBox(height: 30),

                    //card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(16, 218, 218, 218),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(218, 0, 0, 0),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Ô Nhập Tên
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            
                          ),
                          const SizedBox(height: 15),

                          // Ô Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 15),

                          // Ô Password
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Password',
                            isObscure: _isObscure,
                            onToggle: () =>
                                setState(() => _isObscure = !_isObscure),
                          ),
                          const SizedBox(height: 15),

                          // Ô Confirm Password
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            isObscure: _isObscureConfirm,
                            onToggle: () => setState(
                              () => _isObscureConfirm = !_isObscureConfirm,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Nút Sign Up
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      await _handleSignUp();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  133,
                                  20,
                                  20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 30, end: 0),

                    const SizedBox(height: 20),

                    // Nút quay lại Sign In
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color.fromARGB(255, 245, 245, 245),
              ),
              onPressed: () {
                // Lệnh quay về màn hình trước
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'Poppins', color: Color.fromARGB(255, 254, 254, 254)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure, // Dùng để ẩn/hiện chữ
      style: const TextStyle(fontFamily: 'Poppins', color: Color.fromARGB(252, 255, 255, 255)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_outline,
          size: 20,
        ), // Icon ổ khóa ở đầu
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle, // Khi nhấn vào sẽ gọi hàm setState ở trên
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
