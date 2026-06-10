import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AboutPage(),
  ));
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgBlack = Color(0xFF121212);
    const Color accentRed = Color(0xFFE53935);
    const Color textWhite = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        title: Text(
          'WORLD FITNESS',
          style: GoogleFonts.poppins(
            color: accentRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('GUIDE', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () {},
              child: Text('PROFILE', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    "We're trainers, analysts, and keepers of your body health.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: textWhite,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: const BeveledRectangleBorder(),
                    ),
                    onPressed: () {},
                    child: Text(
                      'CHECK YOUR BMI NOW',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 80),

            // Section "What we believe" - Gắn idea BmiRecord của nhóm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "WHAT WE BELIEVE",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                        color: accentRed,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We believe in data. Precise data. Parameters like:",
                          style: GoogleFonts.poppins(color: textWhite, fontSize: 18, height: 1.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Height. Weight. Age. Gender. Activity Levels. BMR. TDEE. Mifflin-St Jeor. Cloud Syncing. Firebase Firestore. Real-time updates. BMI Status. Underweight. Normal. Overweight. Obese. Your health journey, recorded forever.",
                          style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.white70),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "What are we forgetting?",
                          style: GoogleFonts.poppins(color: textWhite, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Oh! History. Every BmiRecord is more than just a number; it's a step toward a better version of you. No local RAM limits, just pure cloud power with Firebase Firestore.",
                          style: GoogleFonts.poppins(fontSize: 15, height: 1.7, color: Colors.white38),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
