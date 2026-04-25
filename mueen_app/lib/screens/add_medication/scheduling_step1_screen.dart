import 'package:flutter/material.dart';
import 'scheduling_step2_screen.dart';

class SchedulingStep1Screen extends StatefulWidget {
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

  const SchedulingStep1Screen({
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
  });

  @override
  State<SchedulingStep1Screen> createState() => _SchedulingStep1ScreenState();
}

class _SchedulingStep1ScreenState extends State<SchedulingStep1Screen> {
  String? _selectedPattern;

  void _goNext() {
    if (_selectedPattern == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchedulingStep2Screen(
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
          daysPattern: _selectedPattern!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          Icons.calendar_month_outlined,
                          color: Color(0xFF16B6C8),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'كم مرة تريد تذكير بالدواء خلال الأسبوع؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اختر نمط التذكير: يوميًا أو في أيام محددة من الأسبوع.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSelectionCard(
                      title: 'كل يوم',
                      value: 'daily',
                    ),
                    const SizedBox(height: 12),
                    _buildSelectionCard(
                      title: 'أيام محددة من الأسبوع',
                      value: 'specific_days',
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
                  onPressed: _selectedPattern == null ? null : _goNext,
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
    required String value,
  }) {
    final isSelected = _selectedPattern == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPattern = value;
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
