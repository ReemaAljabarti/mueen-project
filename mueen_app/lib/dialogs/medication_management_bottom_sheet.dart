import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicationManagementBottomSheet extends StatelessWidget {
  final String medicationName;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationManagementBottomSheet({
    super.key,
    required this.medicationName,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'إدارة الدواء',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            'عرض التفاصيل',
            Icons.info_outline,
            const Color(0xFFD4F5F9),
            const Color(0xFF15B4BE),
            onViewDetails,
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            'تعديل الدواء',
            Icons.edit_outlined,
            const Color(0xFFFFF3D6),
            const Color(0xFF663C00),
            onEdit,
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            'حذف الدواء',
            Icons.delete_outline,
            const Color(0xFFF2D6D3),
            const Color(0xFF7A1F1F),
            onDelete,
            isDestructive: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    Color iconBg,
    Color iconColor,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.chevron_left, color: Colors.black),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? const Color(0xFF7A1F1F) : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}
