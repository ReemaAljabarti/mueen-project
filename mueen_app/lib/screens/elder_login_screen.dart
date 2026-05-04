// lib/screens/elder_login_screen.dart
//
// التغييرات عن النسخة الأصلية:
//   1. بعد نجاح تسجيل الدخول، يُحوَّل result['data'] إلى Elder بأمان
//   2. يُمرَّر كائن Elder كـ argument عند الانتقال إلى /elder-home
//   3. أُضيف debugPrint لتشخيص استجابة الـ API
//   4. واجهة المستخدم لم تتغير

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/elder.dart';
import '../services/current_elder.dart';
import '../services/dose_alert_service.dart';
import '../main.dart';

class ElderLoginScreen extends StatefulWidget {
  const ElderLoginScreen({super.key});

  @override
  State<ElderLoginScreen> createState() => _ElderLoginScreenState();
}

class _ElderLoginScreenState extends State<ElderLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _phoneController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.elderLogin(
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
      );

      // ─── تشخيص: طباعة الاستجابة الكاملة ─────────────────────────────
      debugPrint('[ElderLogin] API result: $result');

      if (!mounted) return;

      if (result['success'] == true) {
        // ─── تحويل data إلى Elder بأمان ──────────────────────────────
        Elder? elder;

        try {
          final data = result['data'];
          debugPrint(
              '[ElderLogin] raw data field: $data (type: ${data.runtimeType})');

          if (data is Map<String, dynamic>) {
            elder = Elder.fromJson(data);
          } else if (data is Map) {
            // بعض إصدارات Dart تُعيد Map<dynamic, dynamic>
            elder = Elder.fromJson(Map<String, dynamic>.from(data));
          }

          debugPrint(
              '[ElderLogin] elder parsed → id=${elder?.id}, name=${elder?.fullName}');
          currentElder = elder;
          DoseAlertService.start(navigatorKey);
        } catch (parseError) {
          // لا نكسر تسجيل الدخول إذا فشل الـ parsing
          debugPrint('[ElderLogin] ⚠️ Elder.fromJson failed: $parseError');
          elder = null;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/elder-home',
          (route) => false,
          // نُمرر Elder كـ argument — ElderHomeScreen يقرأه عبر ModalRoute
          arguments: elder,
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'فشل تسجيل الدخول';
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('[ElderLogin] ❌ catch error: $e');

      setState(() {
        _errorMessage = 'تعذر الاتصال بالخادم';
      });
    }

    // نُعيد ضبط حالة التحميل بعد انتهاء العملية
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Center(
              child: Icon(
                Icons.person,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'تسجيل دخول كبير السن',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'أدخل بياناتك للمتابعة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'رقم الهاتف',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '05XXXXXXX',
                prefixIcon: Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'كلمة المرور',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              textAlign: TextAlign.right,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed:
                  (_isButtonEnabled && !_isLoading) ? _handleLogin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isButtonEnabled && !_isLoading)
                    ? AppColors.primary
                    : const Color(0xFFD6DADB),
                foregroundColor: (_isButtonEnabled && !_isLoading)
                    ? Colors.white
                    : const Color(0xFF8A9AA0),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('تسجيل الدخول'),
            ),
            const SizedBox(height: 16),
            const Text(
              'يتم إنشاء حسابات كبار السن من خلال مقدم الرعاية.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
