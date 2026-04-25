import 'package:flutter/material.dart';
import 'reminder_review_screen.dart';

class SchedulingStep3Screen extends StatefulWidget {
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

  const SchedulingStep3Screen({
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
  });

  @override
  State<SchedulingStep3Screen> createState() => _SchedulingStep3ScreenState();
}

class _SchedulingStep3ScreenState extends State<SchedulingStep3Screen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: false,
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  void _goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderReviewScreen(
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
          timesPerDay: widget.timesPerDay,
          firstReminderTime: _formatTimeOfDay(_selectedTime),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTimeOfDay(_selectedTime);

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
                      Text(
                        'مراجعة',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      Text(
                        'الجدولة',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF4F7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Color(0xFF16B6C8),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'اختر وقت الجرعة الأولى',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.timesPerDay == 1
                          ? 'سيتم اعتماد هذا الوقت كموعد الجرعة اليومية.'
                          : 'بناءً على هذا الوقت سيقوم النظام بحساب بقية الجرعات تلقائيًا حسب عدد مرات الاستخدام في اليوم.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'الوقت الأساسي',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFB),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE3ECEE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Color(0xFF16B6C8),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'اضغط لاختيار الوقت من الساعة',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPreviewCard(formattedTime),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16B6C8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'التالي',
                    style: TextStyle(
                      fontSize: 16,
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

  Widget _buildPreviewCard(String formattedTime) {
    final intervalHours = 24 ~/ widget.timesPerDay;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'معاينة الجدولة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          if (widget.timesPerDay == 1)
            Text(
              'سيتم تذكير المستخدم يوميًا عند $formattedTime',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Tajawal',
              ),
            )
          else
            Text(
              'سيتم احتساب الجرعات التالية كل $intervalHours ساعة بدءًا من $formattedTime',
              textAlign: TextAlign.right,
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
