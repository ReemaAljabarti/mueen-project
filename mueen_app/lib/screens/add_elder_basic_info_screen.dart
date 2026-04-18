import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/elder.dart';
import '../services/current_user.dart';

class AddElderBasicInfoScreen extends StatefulWidget {
  const AddElderBasicInfoScreen({super.key});

  @override
  State<AddElderBasicInfoScreen> createState() =>
      _AddElderBasicInfoScreenState();
}

class _AddElderBasicInfoScreenState extends State<AddElderBasicInfoScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedGender;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _fullNameController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _selectedGender != null;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
      _validateForm();
    });
  }

  void _goNext() {
    final elder = Elder(
      caregiverId: currentCaregiver!['id'],
      fullName: _fullNameController.text,
      phoneNumber: _phoneController.text,
      gender: _selectedGender!,
      password: _passwordController.text,
      age: null,
      weight: null,
      healthConditions: [],
    );

    Navigator.pushNamed(
      context,
      '/add-elder-health',
      arguments: elder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إضافة كبير/ة (1/2)',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6E6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المعلومات الصحية',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'المعلومات الأساسية',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'المعلومات الأساسية',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'لنبدأ بإدخال البيانات الأساسية عن الكبير/ة الذي/التي تضيفه/تضيفينها.',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'الاسم الكامل للكبير/ة *',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'أدخل/أدخلي الاسم الكامل',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الجنس *',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectGender('female'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedGender == 'female'
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
                      side: BorderSide(
                        color: _selectedGender == 'female'
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: const Text('أنثى'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectGender('male'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedGender == 'male'
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
                      side: BorderSide(
                        color: _selectedGender == 'male'
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: const Text('ذكر'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'رقم الجوال *',
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
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'كلمة المرور *',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              textAlign: TextAlign.right,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'أدخل/أدخلي كلمة المرور',
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isButtonEnabled ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled
                    ? AppColors.primary
                    : const Color(0xFFD6DADB),
                foregroundColor:
                    _isButtonEnabled ? Colors.white : const Color(0xFF8A9AA0),
              ),
              child: const Text('التالي'),
            ),
          ],
        ),
      ),
    );
  }
}
