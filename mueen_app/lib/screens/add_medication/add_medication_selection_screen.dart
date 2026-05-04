import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../services/api_service.dart';
import 'barcode_scanner_screen.dart';
import 'medication_found_confirmation_screen.dart';
import '../../widgets/medication_image.dart';

class AddMedicationSelectionScreen extends StatefulWidget {
  final int elderId;
  final String elderName;

  const AddMedicationSelectionScreen({
    super.key,
    required this.elderId,
    required this.elderName,
  });

  @override
  State<AddMedicationSelectionScreen> createState() =>
      _AddMedicationSelectionScreenState();
}

class _AddMedicationSelectionScreenState
    extends State<AddMedicationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Medication> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _searchMedications(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.searchMedications(query: query);

      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر البحث عن الدواء';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openMedicationConfirmation(Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationFoundConfirmationScreen(
          elderId: widget.elderId,
          catalogMedicationId: medication.id,
          medicationName: medication.brandNameAr,
          imageUrl: '',
          gtin: medication.gtin,
          details: {
            'طريقة الاستخدام': medication.routeAr ?? 'غير محدد',
            'الشكل الدوائي': medication.dosageForm ?? 'غير محدد',
            'التركيز': medication.dosageStrength ?? 'غير محدد',
            'المادة الفعالة': medication.genericNameEn ?? 'غير محدد',
          },
          usageNote: medication.foodGuideAr,
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إضافة دواء',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStepLine(active: true),
                      _buildStepLine(active: false),
                      _buildStepLine(active: false),
                      _buildStepLine(active: false),
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
                      Text('تفاصيل',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        'اختيار الدواء',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDDF4F7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF16B6C8),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.elderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'إضافة دواء لهذا الكبير/ة',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF4F7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: Color(0xFF16B6C8),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'إضافة دواء',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ابحث عن الدواء بالاسم أو استخدم الباركود لاسترجاعه من قاعدة بيانات الأدوية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      onChanged: _searchMedications,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم الدواء',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'أو',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BarcodeScannerScreen(
                              elderId: widget.elderId,
                              elderName: widget.elderName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('امسح الباركود'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16B6C8),
                        side: const BorderSide(color: Color(0xFF16B6C8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    if (!_isLoading && _results.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'نتائج البحث',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._results.map(
                        (medication) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildMedicationResultCard(medication),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationResultCard(Medication medication) {
    return InkWell(
      onTap: () => _openMedicationConfirmation(medication),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication,
                color: Color(0xFF16B6C8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    medication.brandNameAr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication.genericNameEn ?? '',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication.dosageStrength ?? '',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              color: Colors.grey,
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
