import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../models/elder_medication.dart';
import '../services/api_service.dart';
import '../services/medication_time_service.dart';
import '../theme/app_theme.dart';
import '../dialogs/medication_management_bottom_sheet.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/safety_check_dialog.dart';
import 'medication_details_screen.dart';
import 'edit_medication_screen.dart';
import 'add_medication/add_medication_selection_screen.dart';
import '../widgets/medication_image.dart';

class CaregiverMedicationsScreen extends StatefulWidget {
  const CaregiverMedicationsScreen({super.key});

  @override
  State<CaregiverMedicationsScreen> createState() =>
      _CaregiverMedicationsScreenState();
}

class _CaregiverMedicationsScreenState
    extends State<CaregiverMedicationsScreen> {
  String _selectedFilter = 'الكل';
  String _selectedDay = 'الأحد';

  List<ElderMedication> _medications = [];
  bool _isLoading = true;
  String? _errorMessage;
  Elder? _elder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_elder == null) {
      _elder = ModalRoute.of(context)?.settings.arguments as Elder?;
    }

    if (_elder == null || _elder!.id == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل بيانات كبير السن';
      });
      return;
    }

    if (_isLoading) {
      _loadMedications(_elder!.id!);
    }
  }

  Future<void> _loadMedications(int elderId) async {
    try {
      final data = await ApiService.getElderMedications(elderId: elderId);

      if (!mounted) return;

      setState(() {
        _medications = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل الأدوية';
      });
    }
  }

  Future<void> _confirmDeleteMedication(ElderMedication medication) async {
    showDialog(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        medicationName: medication.displayNameForElder?.isNotEmpty == true
            ? medication.displayNameForElder!
            : medication.brandNameAr,
        onConfirm: () async {
          Navigator.pop(context);
          await _deleteMedication(medication.id);
        },
      ),
    );
  }

  Future<void> _deleteMedication(int elderMedicationId) async {
    try {
      await ApiService.deleteElderMedication(
        elderMedicationId: elderMedicationId,
      );

      if (_elder?.id != null) {
        await _loadMedications(_elder!.id!);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف الدواء')),
      );
    }
  }

  Future<void> _showSafetyCheck(BuildContext context) async {
    if (_elder?.id == null) return;

    try {
      final result = await ApiService.getElderDrugInteractions(
        elderId: _elder!.id!,
      );

      final hasAlerts = result['has_interactions'] == true;

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (_) => SafetyCheckDialog(
          hasAlerts: hasAlerts,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فحص التفاعلات الدوائية'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final elder = _elder;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الأدوية',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: elder?.id == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMedicationSelectionScreen(
                          elderId: elder!.id!,
                          elderName: elder.fullName,
                        ),
                      ),
                    );

                    await _loadMedications(elder!.id!);
                  },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final elder = _elder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildElderSummaryCard(elder),
          const SizedBox(height: 20),
          _buildDaySelector(),
          const SizedBox(height: 20),
          _buildFilterTabs(),
          const SizedBox(height: 20),
          _buildSafetyCheckCard(),
          const SizedBox(height: 24),
          ..._buildMedicationList(),
        ],
      ),
    );
  }

  Widget _buildElderSummaryCard(Elder? elder) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                elder?.fullName ?? 'كبير السن',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
              const Text(
                'جدول الأدوية الأسبوعي',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFD4F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF15B4BE), size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          const Spacer(),
          Text(
            _selectedDay,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          _buildFilterTab('المساء'),
          const SizedBox(width: 12),
          _buildFilterTab('الصباح'),
          const SizedBox(width: 12),
          _buildFilterTab('الكل'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedFilter == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? null
                : Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyCheckCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'فحص السلامة للأدوية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    'تحقق من التفاعلات الدوائية',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: Color(0xFF663C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showSafetyCheck(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'عرض',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMedicationList() {
    if (_isLoading) {
      return const [
        SizedBox(height: 40),
        Center(child: CircularProgressIndicator()),
      ];
    }

    if (_errorMessage != null) {
      return [
        const SizedBox(height: 20),
        Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    if (_medications.isEmpty) {
      return const [
        SizedBox(height: 20),
        Center(
          child: Text(
            'لا يوجد لديه أدوية مجدولة بعد',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    final showMorning =
        _selectedFilter == 'الكل' || _selectedFilter == 'الصباح';

    final showEvening =
        _selectedFilter == 'الكل' || _selectedFilter == 'المساء';

    final morning = showMorning
        ? _medications.where(_hasMorningTime).toList()
        : <ElderMedication>[];

    final evening = showEvening
        ? _medications.where(_hasEveningTime).toList()
        : <ElderMedication>[];

    final List<Widget> list = [];

    if (morning.isNotEmpty) {
      list.add(_buildSectionTitle('الصباح'));
      list.addAll(
        morning.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMedicationCard(
              m,
              period: 'الصباح',
            ),
          ),
        ),
      );
    }

    if (evening.isNotEmpty) {
      list.add(_buildSectionTitle('المساء'));
      list.addAll(
        evening.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMedicationCard(
              m,
              period: 'المساء',
            ),
          ),
        ),
      );
    }

    if (list.isEmpty) {
      list.add(
        const Center(
          child: Text(
            'لا يوجد لديه أدوية مجدولة بعد',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return list;
  }

  List<String> _getMedicationTimesForPeriod(
    ElderMedication medication,
    String period,
  ) {
    final allTimes = MedicationTimeService.generateMedicationTimes(
      firstReminderTime: medication.firstReminderTime,
      timesPerDay: medication.timesPerDay,
    );

    return allTimes.where((time) {
      final minutes = MedicationTimeService.parseTimeToMinutes(time);

      if (minutes == null) {
        return period == 'الصباح';
      }

      if (period == 'الصباح') {
        return minutes < 12 * 60;
      }

      if (period == 'المساء') {
        return minutes >= 12 * 60;
      }

      return true;
    }).toList();
  }

  bool _hasMorningTime(ElderMedication medication) {
    return _getMedicationTimesForPeriod(medication, 'الصباح').isNotEmpty;
  }

  bool _hasEveningTime(ElderMedication medication) {
    return _getMedicationTimesForPeriod(medication, 'المساء').isNotEmpty;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 8),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildMedicationCard(
    ElderMedication medication, {
    required String period,
  }) {
    final title = (medication.displayNameForElder != null &&
            medication.displayNameForElder!.trim().isNotEmpty)
        ? medication.displayNameForElder!
        : medication.brandNameAr;

    final subtitle =
        '${medication.dosageForm ?? 'غير محدد'} - ${medication.dosageAmount} ${medication.dosageUnit}';

    final timesForPeriod = _getMedicationTimesForPeriod(medication, period);

    final time = timesForPeriod.isNotEmpty
        ? timesForPeriod.join('، ')
        : MedicationTimeService.generateMedicationTimes(
            firstReminderTime: medication.firstReminderTime,
            timesPerDay: medication.timesPerDay,
          ).join('، ');

    final note = medication.usageInstruction ??
        medication.foodGuideAr ??
        'لا توجد تعليمات';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => MedicationManagementBottomSheet(
                  medicationName: title,
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicationDetailsScreen(
                          medication: medication,
                        ),
                      ),
                    );
                  },
                  onEdit: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMedicationScreen(
                          medication: medication,
                        ),
                      ),
                    );

                    if (result == true && _elder?.id != null) {
                      await _loadMedications(_elder!.id!);
                    }
                  },
                  onDelete: () async {
                    await _confirmDeleteMedication(medication);
                  },
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
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
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.access_time, size: 14),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F7F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MedicationImage(
              gtin: medication.gtin,
            ),
          ),
        ],
      ),
    );
  }
}
