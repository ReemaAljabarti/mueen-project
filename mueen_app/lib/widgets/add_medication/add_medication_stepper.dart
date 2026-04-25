import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AddMedicationStepper extends StatelessWidget {
  final int currentStep; // 1 to 4

  const AddMedicationStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(4, 'مراجعة'),
          _buildStep(3, 'الجدولة'),
          _buildStep(2, 'تفاصيل'),
          _buildStep(1, 'اختيار الدواء'),
        ],
      ),
    );
  }

  Widget _buildStep(int stepNumber, String label) {
    bool isActive = currentStep >= stepNumber;
    bool isCurrent = currentStep == stepNumber;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }
}
