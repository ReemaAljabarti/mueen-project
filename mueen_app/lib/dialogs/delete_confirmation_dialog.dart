import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String medicationName;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.medicationName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF2D6D3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFF7A1F1F), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'حذف الدواء؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 8),
            Text(
              'هل أنت متأكد من رغبتك في حذف $medicationName من جدول أدوية كبير السن؟',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.black, fontFamily: 'Tajawal')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A1F1F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
