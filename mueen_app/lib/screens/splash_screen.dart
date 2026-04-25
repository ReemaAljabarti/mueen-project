import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/role-selection');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F9),
      body: Stack(
        children: [
          // 🔵 الشكل السفلي
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFFBFD7ED),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 🟢 الشكل العلوي
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFFCDE7DB),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 🔥 المحتوى الرئيسي
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 اللوجو (بدل الأيقونة)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/fonts/images/mueenicon.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Mu'een",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: Color(0xFF2F3E46),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "معين",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF16B6C8),
                    fontFamily: 'Tajawal',
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "يساعدك في إدارة وتذكير الأدوية",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: 'Tajawal',
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "v1.0.0 (Beta)",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
