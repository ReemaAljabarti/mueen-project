import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';

class CaregiverLoginScreen extends StatefulWidget {
  const CaregiverLoginScreen({super.key});

  @override
  State<CaregiverLoginScreen> createState() => _CaregiverLoginScreenState();
}

class _CaregiverLoginScreenState extends State<CaregiverLoginScreen> {
  bool _isPhoneLogin = true;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      if (_isPhoneLogin) {
        _isButtonEnabled = _phoneController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty;
      } else {
        _isButtonEnabled = _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty;
      }

      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.caregiverLogin(
        email: _isPhoneLogin ? null : _emailController.text,
        phoneNumber: _isPhoneLogin ? _phoneController.text : null,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        currentCaregiver = result['data'];

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/caregiver-home',
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'فشل تسجيل الدخول';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'تعذر الاتصال بالخادم';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
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
              child: Image(
                image: AssetImage('assets/fonts/images/mueenicon.png'),
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'تسجيل دخول مقدم الرعاية',
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
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPhoneLogin = true;
                          _errorMessage = null;
                          _validateForm();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isPhoneLogin
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'رقم الهاتف',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isPhoneLogin ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPhoneLogin = false;
                          _errorMessage = null;
                          _validateForm();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isPhoneLogin
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'البريد الإلكتروني',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isPhoneLogin ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_isPhoneLogin) ...[
              const Text(
                'رقم الهاتف',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            ] else ...[
              const Text(
                'البريد الإلكتروني',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'كلمة المرور',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/caregiver-signup'),
                  child: const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text('ليس لديك حساب؟'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
