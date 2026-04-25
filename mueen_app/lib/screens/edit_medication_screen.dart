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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, color: AppColors.primary),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final controller = TextEditingController(text: _selectedTime);
              final result = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('تعديل الوقت'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'مثال: ٩:٠٠ ص',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        controller.text.trim(),
                      ),
                      child: const Text('حفظ'),
                    ),
                  ],
                ),
              );

              if (result != null && result.isNotEmpty) {
                setState(() {
                  _selectedTime = result;
                });
              }
            },
            child: Text(
              _selectedTime,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
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
