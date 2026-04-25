import 'package:flutter/material.dart';
import 'scheduling_step3_screen.dart';

class SchedulingStep2Screen extends StatefulWidget {
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

  const SchedulingStep2Screen({
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
  });

  @override
  State<SchedulingStep2Screen> createState() => _SchedulingStep2ScreenState();
}

class _SchedulingStep2ScreenState extends State<SchedulingStep2Screen> {
  int? _timesPerDay;

  void _goNext() {
    if (_timesPerDay == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchedulingStep3Screen(
          elderId: widget.elderId,
          catalogMedicationId: widget.catalogMedicationId,
          medicationName: widget.medicationName,
          friendlyName: widget.friendlyName,
          doseCount: widget.doseCount,
          doseUnit: widget.doseUnit,
          usageInstruction: widget.usageInstruction,
          shortDescription: widget.shortDescription,
          treatmentDurationType: widget.treatmentDurationType,
          startDate: widget.startDate,
          endDate: widget.endDate,
          daysPattern: widget.daysPattern,
          timesPerDay: _timesPerDay!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = <Map<String, dynamic>>[
      {'label': 'مرة واحدة يوميًا', 'value': 1},
      {'label': 'مرتين يوميًا', 'value': 2},
      {'label': '3 مرات يوميًا', 'value': 3},
      {'label': '4 مرات يوميًا', 'value': 4},
    ];

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
          widget.medicationName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
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
                      _buildStepLine(active: false),
                      _buildStepLine(active: true),
                      _buildStepLine(active: true),
                      _buildStepLine(active: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('مراجعة',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        'الجدولة',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('تفاصيل',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('اختيار الدواء',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF4F7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Color(0xFF16B6C8),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'كم مرة يؤخذ هذا الدواء يوميًا؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اختر عدد مرات تناول الدواء خلال اليوم.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...options.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSelectionCard(
                          title: option['label'] as String,
                          value: option['value'] as int,
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
                  onPressed: _timesPerDay == null ? null : _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16B6C8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD6DADB),
                    disabledForegroundColor: const Color(0xFF8A9AA0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'التالي',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required int value,
  }) {
    final isSelected = _timesPerDay == value;

    return InkWell(
      onTap: () {
        setState(() {
          _timesPerDay = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF16B6C8) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF16B6C8) : Colors.grey,
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
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
