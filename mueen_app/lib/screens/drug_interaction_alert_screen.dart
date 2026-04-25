import 'package:flutter/material.dart';

class DrugInteractionAlertScreen extends StatelessWidget {
  final String severity;
  final String currentMedicationName;
  final String existingMedicationName;
  final String noteAr;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  const DrugInteractionAlertScreen({
    super.key,
    required this.severity,
    required this.currentMedicationName,
    required this.existingMedicationName,
    required this.noteAr,
    required this.onContinue,
    required this.onCancel,
  });

  bool get _isHigh => severity.toUpperCase() == 'HIGH';
  bool get _isModerate => severity.toUpperCase() == 'MODERATE';
  bool get _isLow => severity.toUpperCase() == 'LOW';

  Color get _badgeBgColor {
    if (_isHigh) return const Color(0xFFFFE7E7);
    if (_isModerate) return const Color(0xFFFFF3D6);
    return const Color(0xFFE4F7E7);
  }

  Color get _badgeTextColor {
    if (_isHigh) return const Color(0xFFC62828);
    if (_isModerate) return const Color(0xFF8A5A00);
    return const Color(0xFF2E7D32);
  }

  Color get _iconCircleColor {
    if (_isHigh) return const Color(0xFFFFD9D9);
    if (_isModerate) return const Color(0xFFFFE8B3);
    return const Color(0xFFCDEFD4);
  }

  Color get _noteCardColor {
    if (_isHigh) return const Color(0xFFFFF1F1);
    if (_isModerate) return const Color(0xFFFFF8E7);
    return const Color(0xFFF1FAF2);
  }

  String get _severityLabel {
    if (_isHigh) return 'مرتفع';
    if (_isModerate) return 'متوسط';
    return 'منخفض';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'تنبيه تفاعل دوائي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: _badgeBgColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _iconCircleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: _badgeTextColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'شدة التفاعل: $_severityLabel',
                      style: TextStyle(
                        color: _badgeTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'يوجد تفاعل دوائي محتمل بين:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    Text(
                      currentMedicationName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'الدواء الحالي',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _iconCircleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sync_alt_rounded,
                        color: _badgeTextColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      existingMedicationName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'دواء موجود في الجدول',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: _noteCardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _iconCircleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: _badgeTextColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        noteAr,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: _badgeTextColor,
                          fontSize: 14,
                          height: 1.5,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  Row(
                    children: [
                      _buildArrowButton(Icons.arrow_back_ios_new_rounded),
                      const Spacer(),
                      Row(
                        children: [
                          _buildDot(true),
                          _buildDot(false),
                          _buildDot(false),
                        ],
                      ),
                      const Spacer(),
                      _buildArrowButton(Icons.arrow_forward_ios_rounded),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'يمكنكم استعراض التفاعلات الأخرى',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16B6C8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'متابعة الإضافة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onCancel,
                child: const Text(
                  'إلغاء الإضافة',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: active ? 18 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF16B6C8) : const Color(0xFFD0D7DA),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildArrowButton(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5ECEE)),
      ),
      child: Icon(
        icon,
        size: 18,
        color: Colors.black87,
      ),
    );
  }
}
