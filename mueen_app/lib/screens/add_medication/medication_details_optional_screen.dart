import 'package:flutter/material.dart';
import 'scheduling_step1_screen.dart';

class MedicationDetailsOptionalScreen extends StatefulWidget {
  final int elderId;
  final int catalogMedicationId;
  final String medicationName;
  final String friendlyName;
  final int doseCount;
  final String doseUnit;

  const MedicationDetailsOptionalScreen({
    super.key,
    required this.elderId,
    required this.catalogMedicationId,
    required this.medicationName,
    required this.friendlyName,
    required this.doseCount,
    required this.doseUnit,
  });

  @override
  State<MedicationDetailsOptionalScreen> createState() =>
      _MedicationDetailsOptionalScreenState();
}

class _MedicationDetailsOptionalScreenState
    extends State<MedicationDetailsOptionalScreen> {
  String? usageInstruction;
  String? shortDescription;
  String? treatmentDurationType;
  String? startDate;
  String? endDate;

  void _goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchedulingStep1Screen(
          elderId: widget.elderId,
          catalogMedicationId: widget.catalogMedicationId,
          medicationName: widget.medicationName,
          friendlyName: widget.friendlyName,
          doseCount: widget.doseCount,
          doseUnit: widget.doseUnit,
          usageInstruction: usageInstruction,
          shortDescription: shortDescription,
          treatmentDurationType: treatmentDurationType,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );
  }

  void _selectUsageInstruction() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UsageInstructionSheet(
        initialValue: usageInstruction,
      ),
    );

    if (result != null) {
      setState(() {
        usageInstruction = result;
      });
    }
  }

  void _writeShortDescription() async {
    final controller = TextEditingController(text: shortDescription ?? '');

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    const Spacer(),
                    const Text(
                      'الوصف المختصر',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'أضف وصفًا مختصرًا (اختياري)',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'مثال: دواء للصداع والحمى',
                    filled: true,
                    fillColor: const Color(0xFFF7FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16B6C8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        shortDescription = result;
      });
    }
  }

  void _selectTreatmentDuration() async {
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TreatmentDurationSheet(
        initialType: treatmentDurationType,
        initialStartDate: startDate,
        initialEndDate: endDate,
      ),
    );

    if (result != null) {
      setState(() {
        treatmentDurationType = result['type'];
        startDate = result['startDate'];
        endDate = result['endDate'];
      });
    }
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
                      _buildStepLine(active: false),
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
                      Text('الجدولة',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        'تفاصيل',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          Icons.tune,
                          color: Color(0xFF16B6C8),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'إعدادات إضافية (اختياري)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'يمكنك إضافة مدة العلاج وتعليمات الاستخدام والوصف المختصر.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildOptionTile(
                      title: 'مدة العلاج',
                      value: treatmentDurationType ?? '',
                      icon: Icons.calendar_today_outlined,
                      onTap: _selectTreatmentDuration,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      title: 'تعليمات الاستخدام',
                      value: usageInstruction ?? '',
                      icon: Icons.restaurant_menu_outlined,
                      onTap: _selectUsageInstruction,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      title: 'الوصف المختصر',
                      value: shortDescription ?? '',
                      icon: Icons.notes_outlined,
                      onTap: _writeShortDescription,
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

  Widget _buildOptionTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.chevron_left, color: Color(0xFF16B6C8)),
            const Spacer(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (value.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF16B6C8)),
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

class _UsageInstructionSheet extends StatefulWidget {
  final String? initialValue;

  const _UsageInstructionSheet({this.initialValue});

  @override
  State<_UsageInstructionSheet> createState() => _UsageInstructionSheetState();
}

class _UsageInstructionSheetState extends State<_UsageInstructionSheet> {
  String? selected;

  final List<String> options = const [
    'قبل الأكل',
    'بعد الأكل',
    'مع الأكل',
    'على معدة فارغة',
    'قبل النوم',
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
              const Spacer(),
              const Text(
                'تعليمات الاستخدام',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selected = option;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected == option
                          ? const Color(0xFF16B6C8)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected == option
                            ? const Color(0xFF16B6C8)
                            : Colors.grey,
                      ),
                      const Spacer(),
                      Text(
                        option,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16B6C8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('حفظ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatmentDurationSheet extends StatefulWidget {
  final String? initialType;
  final String? initialStartDate;
  final String? initialEndDate;

  const _TreatmentDurationSheet({
    this.initialType,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_TreatmentDurationSheet> createState() =>
      _TreatmentDurationSheetState();
}

class _TreatmentDurationSheetState extends State<_TreatmentDurationSheet> {
  String selectedType = 'continuous';
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType ?? 'continuous';
    startDateController.text = widget.initialStartDate ?? '';
    endDateController.text = widget.initialEndDate ?? '';
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, {
      'type': selectedType,
      'startDate': startDateController.text.trim(),
      'endDate': endDateController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const Spacer(),
                const Text(
                  'مدة العلاج',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: startDateController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'تاريخ البداية',
                filled: true,
                fillColor: const Color(0xFFF7FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildDurationOption('لمدة (عدد أيام)', 'days'),
            const SizedBox(height: 10),
            _buildDurationOption('حتى تاريخ', 'until_date'),
            const SizedBox(height: 10),
            _buildDurationOption('مستمر', 'continuous'),
            if (selectedType == 'until_date') ...[
              const SizedBox(height: 14),
              TextField(
                controller: endDateController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'تاريخ الانتهاء',
                  filled: true,
                  fillColor: const Color(0xFFF7FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16B6C8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(String title, String value) {
    final selected = selectedType == value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedType = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF16B6C8) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF16B6C8) : Colors.grey,
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
