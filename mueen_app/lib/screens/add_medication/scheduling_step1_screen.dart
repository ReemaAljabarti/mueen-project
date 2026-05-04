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

  final List<String> _selectedDays = [];

  final List<Map<String, String>> _weekDays = [
    {'label': 'الأحد', 'value': 'sun'},
    {'label': 'الاثنين', 'value': 'mon'},
    {'label': 'الثلاثاء', 'value': 'tue'},
    {'label': 'الأربعاء', 'value': 'wed'},
    {'label': 'الخميس', 'value': 'thu'},
    {'label': 'الجمعة', 'value': 'fri'},
    {'label': 'السبت', 'value': 'sat'},
  ];

  bool get _canGoNext {
    if (_selectedPattern == null) return false;

    if (_selectedPattern == 'daily') return true;

    if (_selectedPattern == 'specific_days') {
      return _selectedDays.isNotEmpty;
    }

    return false;
  }

  String get _daysPatternValue {
    if (_selectedPattern == 'daily') {
      return 'daily';
    }

    return _selectedDays.join(',');
  }

  void _goNext() {
    if (!_canGoNext) return;

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
          daysPattern: _daysPatternValue,
        ),
      ),
    );
  }

  void _selectPattern(String value) {
    setState(() {
      _selectedPattern = value;

      if (value == 'daily') {
        _selectedDays.clear();
      }
    });
  }

  void _toggleDay(String value) {
    setState(() {
      if (_selectedDays.contains(value)) {
        _selectedDays.remove(value);
      } else {
        _selectedDays.add(value);
      }
    });
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
                          Icons.calendar_month_outlined,
                          color: Color(0xFF16B6C8),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'كم مرة تريد تذكيرك بالدواء خلال الأسبوع؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اختر نمط التذكير: يوميًا أو في أيام محددة من الأسبوع.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Tajawal',
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
                    if (_selectedPattern == 'specific_days') ...[
                      const SizedBox(height: 16),
                      _buildWeekDaysSelector(),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canGoNext ? _goNext : null,
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

  Widget _buildSelectionCard({
    required String title,
    required String value,
  }) {
    final isSelected = _selectedPattern == value;

    return InkWell(
      onTap: () => _selectPattern(value),
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
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3ECEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'اختر أيام التذكير',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'يمكنك اختيار يوم واحد أو أكثر من الأسبوع.',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: _weekDays.map((day) {
              final label = day['label']!;
              final value = day['value']!;
              final isSelected = _selectedDays.contains(value);

              return _buildDayChip(
                label: label,
                value: value,
                isSelected: isSelected,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _toggleDay(value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDDF4F7) : const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF16B6C8) : const Color(0xFFE3ECEE),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xFF16B6C8),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF062B38) : Colors.black87,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'Tajawal',
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
