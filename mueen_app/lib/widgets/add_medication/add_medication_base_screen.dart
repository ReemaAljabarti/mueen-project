import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'add_medication_stepper.dart';

class AddMedicationBaseScreen extends StatelessWidget {
  final int currentStep;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? bottomButton;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final String? medicationName;

  const AddMedicationBaseScreen({
    super.key,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.body,
    this.bottomButton,
    this.onBack,
    this.onClose,
    this.medicationName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: onClose != null
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: onClose,
              )
            : (onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: onBack,
                  )
                : null),
        title: Text(
          medicationName ?? 'إضافة دواء',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          AddMedicationStepper(currentStep: currentStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 32),
                  body,
                ],
              ),
            ),
          ),
          if (bottomButton != null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: bottomButton!,
            ),
        ],
      ),
    );
  }
}
