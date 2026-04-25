import 'package:flutter/material.dart';

class AddMedicationSuccessScreen extends StatelessWidget {
  final String medicationName;
  final int doseCount;
  final String doseUnit;
  final List<String> times;
  final String? usageInstruction;

  const AddMedicationSuccessScreen({
    super.key,
    required this.medicationName,
    required this.doseCount,
    required this.doseUnit,
    required this.times,
    this.usageInstruction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF4F7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16B6C8).withOpacity(0.15),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  size: 54,
                  color: Color(0xFF16B6C8),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'تمت إضافة الدواء بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'تمت إضافته إلى جدول الأدوية بنجاح.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medication_outlined,
                          color: Color(0xFF16B6C8),
                        ),
                        const Spacer(),
                        Text(
                          medicationName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$doseCount $doseUnit',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _summaryRow('المواعيد', times.join(' • ')),
                    if (usageInstruction != null &&
                        usageInstruction!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _summaryRow('التعليمات', usageInstruction!),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName('/caregiver-medications'),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16B6C8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('الرجوع إلى الأدوية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
