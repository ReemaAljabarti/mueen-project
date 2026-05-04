import 'package:flutter/material.dart';
import 'medication_details_step1_screen.dart';
import '../../widgets/medication_image.dart';

class MedicationFoundConfirmationScreen extends StatelessWidget {
  final int elderId;
  final int catalogMedicationId;
  final String medicationName;
  final String imageUrl;
  final Map<String, String> details;
  final String? usageNote;
  final String? gtin;

  const MedicationFoundConfirmationScreen({
    super.key,
    required this.elderId,
    required this.catalogMedicationId,
    required this.medicationName,
    required this.imageUrl,
    required this.details,
    this.usageNote,
    this.gtin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF4F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تم العثور على الدواء',
                            style: TextStyle(
                              color: Color(0xFF062B38),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF0EAFC0),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    medicationName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: (gtin != null && gtin!.trim().isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Center(
                              child: MedicationImage(
                                gtin: gtin,
                                size: 120,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.medication,
                              size: 60,
                              color: Color(0xFF0EAFC0),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoGrid(details),
                  const SizedBox(height: 20),
                  if (usageNote != null && usageNote!.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EFCF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9D48E)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF9B7B1E),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              usageNote!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF6F5613),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MedicationDetailsStep1Screen(
                            elderId: elderId,
                            catalogMedicationId: catalogMedicationId,
                            medicationName: medicationName,
                          ),
                        ),
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
                    child: const Text(
                      'تأكيد الإضافة',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF062B38),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFD7E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('مسح مرة أخرى'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Map<String, String> details) {
    final entries = details.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = entries[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.key,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
