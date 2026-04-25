import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SafetyCheckDialog extends StatelessWidget {
  final bool hasAlerts;

  const SafetyCheckDialog({super.key, required this.hasAlerts});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAlerts)
              _buildAlertsContent(context)
            else
              _buildNoAlertsContent(context),
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
                  'إغلاق',
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
      ),
    );
  }

  Widget _buildAlertsContent(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFF2D6D3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: Color(0xFF7A1F1F), size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'تنبيهات السلامة',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
        const SizedBox(height: 8),
        const Text(
          'هذه التنبيهات للمراجعة وليست تشخيصاً طبياً نهائياً',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal'),
        ),
        const SizedBox(height: 24),
        _buildAlertCard('مرتفع', 'تفاعل محتمل بين بنادول ودواء الضغط',
            const Color(0xFFF2D6D3), const Color(0xFF7A1F1F)),
        const SizedBox(height: 12),
        _buildAlertCard('متوسط', 'تكرار في فئة الأدوية المسكنة',
            const Color(0xFFFFF3D6), const Color(0xFF663C00)),
      ],
    );
  }

  Widget _buildNoAlertsContent(BuildContext context) {
    return Column(
      children: [
        const Text(
          'فحص السلامة',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
        const SizedBox(height: 8),
        const Text(
          'لم يتم العثور على أي تنبيهات في قائمة الأدوية',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal'),
        ),
        const SizedBox(height: 4),
        const Text(
          'آخر فحص: اليوم ١٠:٣٠ ص',
          style: TextStyle(
              color: Colors.grey, fontSize: 12, fontFamily: 'Tajawal'),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFD4F5F9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF15B4BE), size: 48),
              SizedBox(height: 16),
              Text(
                'لا توجد تنبيهات',
                style: TextStyle(
                    color: Color(0xFF003948),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal'),
              ),
              SizedBox(height: 8),
              Text(
                'قائمة الأدوية خالية حالياً من تنبيهات المراجعة',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF003948),
                    fontSize: 14,
                    fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(
      String severity, String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: textCol),
          const Spacer(),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(8)),
                  child: Text(severity,
                      style: TextStyle(
                          color: textCol,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal')),
                ),
                const SizedBox(height: 4),
                Text(text,
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontSize: 14, fontFamily: 'Tajawal')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
