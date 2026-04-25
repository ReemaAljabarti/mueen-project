import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BarcodeNotFoundBottomSheet extends StatelessWidget {
  final VoidCallback onTryAgain;
  final VoidCallback onToggleFlashlight;
  final VoidCallback onManualEntry;

  const BarcodeNotFoundBottomSheet({
    super.key,
    required this.onTryAgain,
    required this.onToggleFlashlight,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning Label/Alert Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warningText, size: 18),
                SizedBox(width: 8),
                Text(
                  'تنبيه', // Alert
                  style: TextStyle(color: AppColors.warningText, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'تعذر قراءة الباركود', // Barcode scan failed
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'لم يتم التعرف على الباركود. يرجى التأكد من وضوح الباركود أو محاولة تشغيل الفلاش.', // Barcode not recognized. Please ensure barcode is clear or try turning on the flash.
            style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Tajawal'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTryAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'حاول مرة أخرى', // Try again
                style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onToggleFlashlight,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'تشغيل الفلاش', // Turn on Flash
                style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onManualEntry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'إدخال يدوي', // Manual Entry
                style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
