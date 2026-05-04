import 'package:flutter/material.dart';
import '../models/elder_medication.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EditMedicationScreen extends StatefulWidget {
  final ElderMedication medication;

  const EditMedicationScreen({
    super.key,
    required this.medication,
  });

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  late final TextEditingController _friendlyNameController;
  late int _doseCount;
  late String _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _friendlyNameController = TextEditingController(
      text: widget.medication.displayNameForElder ?? '',
    );
    _doseCount = widget.medication.dosageAmount;
    _selectedTime = widget.medication.firstReminderTime;
  }

  @override
  void dispose() {
    _friendlyNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.updateElderMedication(
        elderMedicationId: widget.medication.id,
        displayNameForElder: _friendlyNameController.text.trim().isEmpty
            ? null
            : _friendlyNameController.text.trim(),
        dosageAmount: _doseCount,
        dosageUnit: widget.medication.dosageUnit,
        firstReminderTime: _selectedTime,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ التعديلات'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickTime() async {
    final initialTime = _parseSelectedTime(_selectedTime) ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
        _selectedTime = _formatTimeOfDay(picked);
      });
    }
  }

  TimeOfDay? _parseSelectedTime(String value) {
    final trimmed = value.trim();

    final arabicMatch =
        RegExp(r'(\d{1,2}):(\d{2})\s*([صم])').firstMatch(trimmed);

    if (arabicMatch != null) {
      int hour = int.parse(arabicMatch.group(1)!);
      final minute = int.parse(arabicMatch.group(2)!);
      final period = arabicMatch.group(3)!;

      if (period == 'م' && hour != 12) hour += 12;
      if (period == 'ص' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    final englishMatch =
        RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?').firstMatch(trimmed);

    if (englishMatch != null) {
      int hour = int.parse(englishMatch.group(1)!);
      final minute = int.parse(englishMatch.group(2)!);
      final period = englishMatch.group(3);

      if (period != null) {
        final upperPeriod = period.toUpperCase();
        if (upperPeriod == 'PM' && hour != 12) hour += 12;
        if (upperPeriod == 'AM' && hour == 12) hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final medication = widget.medication;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'تعديل الدواء',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              'اسم الدواء',
              medication.brandNameAr,
            ),
            const SizedBox(height: 16),
            _buildEditableNameCard(),
            const SizedBox(height: 32),
            const Text(
              'الجرعة',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDoseButton(
                    Icons.add,
                    () => setState(() => _doseCount++),
                  ),
                  Text(
                    '$_doseCount ${medication.dosageUnit}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  _buildDoseButton(
                    Icons.remove,
                    () => setState(() {
                      _doseCount = _doseCount > 1 ? _doseCount - 1 : 1;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'الوقت',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeCard(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isSaving ? 'جارٍ الحفظ...' : 'حفظ التعديلات',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableNameCard() {
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
            'اسم كبير السن',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _friendlyNameController,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'اسم واضح لكبير السن',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return GestureDetector(
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
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  Text(
                    _selectedTime,
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
    );
  }

  Widget _buildDoseButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
