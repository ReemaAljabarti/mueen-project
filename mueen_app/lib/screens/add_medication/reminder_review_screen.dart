import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_medication_success_screen.dart';
import '../drug_interaction_alert_screen.dart';
import '../../services/medication_time_service.dart';
import '../../services/medication_time_service.dart';

class ReminderReviewScreen extends StatelessWidget {
  final int elderId;
  final int catalogMedicationId;
  final String medicationName;
  final String friendlyName;
  final int doseCount;
  final String doseUnit;
  final String? usageInstruction;
  final String? shortDescription;
  final String? treatmentDurationType;
  final String? startDate;
  final String? endDate;
  final String daysPattern;
  final int timesPerDay;
  final String firstReminderTime;

  const ReminderReviewScreen({
    super.key,
    required this.elderId,
    required this.catalogMedicationId,
    required this.medicationName,
    required this.friendlyName,
    required this.doseCount,
    required this.doseUnit,
    this.usageInstruction,
    this.shortDescription,
    this.treatmentDurationType,
    this.startDate,
    this.endDate,
    required this.daysPattern,
    required this.timesPerDay,
    required this.firstReminderTime,
  });

  List<String> _generateTimes() {
    return MedicationTimeService.generateMedicationTimes(
      firstReminderTime: firstReminderTime,
      timesPerDay: timesPerDay,
    );
  }

  Future<void> _saveMedication(BuildContext context) async {
    await ApiService.createElderMedication(
      elderId: elderId,
      catalogMedicationId: catalogMedicationId,
      displayNameForElder: friendlyName.trim().isEmpty ? null : friendlyName,
      dosageAmount: doseCount,
      dosageUnit: doseUnit,
      usageInstruction: usageInstruction,
      shortDescription: shortDescription,
      treatmentDurationType: treatmentDurationType,
      startDate: startDate,
      endDate: endDate,
      timesPerDay: timesPerDay,
      firstReminderTime: firstReminderTime,
      daysPattern: daysPattern,
    );

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationSuccessScreen(
          medicationName: medicationName,
          doseCount: doseCount,
          doseUnit: doseUnit,
          times: _generateTimes(),
          usageInstruction: usageInstruction,
        ),
      ),
    );
  }

  Future<void> _checkInteractionThenContinue(BuildContext context) async {
    try {
      final result = await ApiService.checkDrugInteraction(
        elderId: elderId,
        catalogMedicationId: catalogMedicationId,
      );

      final hasInteraction = result['has_interaction'] == true;

      if (!hasInteraction) {
        await _saveMedication(context);
        return;
      }

      final severity = (result['severity'] ?? '').toString().toUpperCase();
      final existingMedicationName =
          (result['existing_medication_name'] ?? '').toString();
      final noteAr = (result['note_ar'] ?? '').toString();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DrugInteractionAlertScreen(
            severity: severity,
            currentMedicationName: medicationName,
            existingMedicationName: existingMedicationName,
            noteAr: noteAr,
            onContinue: () async {
              await _saveMedication(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر التحقق من التفاعل الدوائي'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final times = _generateTimes();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          medicationName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.popUntil(
              context,
              ModalRoute.withName('/caregiver-medications'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStepLine(active: true),
                      _buildStepLine(active: true),
                      _buildStepLine(active: true),
                      _buildStepLine(active: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مراجعة',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      Text(
                        'الجدولة',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      Text(
                        'تفاصيل',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      Text(
                        'اختيار الدواء',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'راجع التذكيرات قبل الحفظ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'يمكنك تعديل الأوقات لاحقًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...times.map(
                      (time) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chevron_left,
                              color: Color(0xFF16B6C8),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                Text(
                                  '$doseCount $doseUnit',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (usageInstruction != null &&
                        usageInstruction!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          usageInstruction!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _checkInteractionThenContinue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16B6C8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLine({required bool active}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 6,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF16B6C8) : const Color(0xFFE4E8EA),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
