import 'package:flutter/material.dart';
import '../models/elder_medication.dart';
import '../theme/app_theme.dart';

class MedicationDetailsScreen extends StatelessWidget {
  final ElderMedication? medication;

  const MedicationDetailsScreen({
    super.key,
    this.medication,
  });

  @override
  Widget build(BuildContext context) {
    final med = medication;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تفاصيل الدواء',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('المعلومات الأساسية'),
            _buildDetailCard([
              _buildDetailRow(
                'اسم الدواء',
                med?.brandNameAr ?? 'غير محدد',
              ),
              _buildDetailRow(
                'قوة الجرعة',
                med?.dosageStrength ?? 'غير محدد',
              ),
              _buildDetailRow(
                'الشكل الدوائي',
                med?.dosageForm ?? 'غير محدد',
              ),
              _buildDetailRow(
                'طريقة الاستخدام',
                med?.routeAr ?? 'غير محدد',
              ),
              _buildDetailRow(
                'الاسم الواضح لكبير السن',
                (med?.displayNameForElder != null &&
                        med!.displayNameForElder!.trim().isNotEmpty)
                    ? med.displayNameForElder!
                    : 'غير محدد',
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('الوصف المختصر'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Text(
                med?.shortDescription?.trim().isNotEmpty == true
                    ? med!.shortDescription!
                    : 'لا يوجد وصف مختصر',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF663C00),
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('الجدولة'),
            _buildDetailCard([
              _buildDetailRow(
                'الأيام النشطة',
                med?.daysPattern ?? 'غير محدد',
              ),
              _buildDetailRow(
                'أوقات الدواء',
                med?.firstReminderTime ?? 'غير محدد',
              ),
              _buildDetailRow(
                'التعليمات',
                med?.usageInstruction ?? med?.foodGuideAr ?? 'لا توجد تعليمات',
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('معلومات إضافية'),
            _buildDetailCard([
              _buildDetailRow(
                'تعليمات التخزين',
                'يحفظ في درجة حرارة الغرفة',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}
