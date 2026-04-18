import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/elder.dart';
import '../services/api_service.dart';

class AddElderHealthInfoScreen extends StatefulWidget {
  const AddElderHealthInfoScreen({super.key});

  @override
  State<AddElderHealthInfoScreen> createState() =>
      _AddElderHealthInfoScreenState();
}

class _AddElderHealthInfoScreenState extends State<AddElderHealthInfoScreen> {
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final List<String> _selectedConditions = [];
  bool _isButtonEnabled = false;
  late Elder _elder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _elder = ModalRoute.of(context)!.settings.arguments as Elder;
  }

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _ageController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إضافة كبير/ة (2/2)',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                      color: AppColors.primary,
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
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'المعلومات الأساسية',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'المعلومات الصحية',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أدخل/أدخلي المعلومات الصحية للكبير/ة لمساعدتنا في تخصيص التذكيرات.',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'العمر *',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'أدخل/أدخلي العمر',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الوزن (اختياري)',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'أدخل/أدخلي الوزن بالكيلو جرام',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الحالات الصحية (اختياري)',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _buildConditionChip('السكري'),
                _buildConditionChip('ضغط الدم'),
                _buildConditionChip('القلب'),
                _buildConditionChip('الربو'),
                _buildConditionChip('أخرى'),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () async {
                      final updatedElder = _elder.copyWith(
                        age: _ageController.text,
                        weight: _weightController.text,
                        healthConditions: _selectedConditions,
                      );

                      await ApiService.addElder(updatedElder);

                      if (!mounted) return;

                      Navigator.pushNamed(
                        context,
                        '/elder-added-success',
                        arguments: updatedElder,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled
                    ? AppColors.primary
                    : const Color(0xFFD6DADB),
                foregroundColor:
                    _isButtonEnabled ? Colors.white : const Color(0xFF8A9AA0),
              ),
              child: const Text('إتمام التسجيل'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChip(String label) {
    final isSelected = _selectedConditions.contains(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedConditions.remove(label);
          } else {
            _selectedConditions.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
