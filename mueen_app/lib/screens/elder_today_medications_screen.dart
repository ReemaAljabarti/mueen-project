// lib/screens/elder_today_medications_screen.dart
//
// شاشة أدوية اليوم لكبير السن — مسار: '/elder-today-schedule'
//
// منطق عنوان الدواء:
//   1. displayNameForElder موجود → يُعرض كما هو
//   2. displayNameForElder فارغ + medCategory موجود → "دواء {medCategory}"
//   3. كلاهما فارغان → brandNameAr مباشرة

import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../models/elder_medication.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// تعريف حالات الفلتر
// ════════════════════════════════════════════════════════════════════════════
enum _FilterTab { all, morning, evening }

class ElderTodayMedicationsScreen extends StatefulWidget {
  const ElderTodayMedicationsScreen({super.key});

  @override
  State<ElderTodayMedicationsScreen> createState() =>
      _ElderTodayMedicationsScreenState();
}

class _ElderTodayMedicationsScreenState
    extends State<ElderTodayMedicationsScreen> {
  // ── الحالة ────────────────────────────────────────────────────────────────
  Elder? _elder;
  bool _initialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<ElderMedication> _allMedications = [];
  _FilterTab _activeFilter = _FilterTab.all;

  // ── دورة الحياة ───────────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Elder) {
      _elder = args;
      debugPrint(
          '[TodayMeds] ✅ Elder loaded → id=${_elder!.id}, name=${_elder!.fullName}');
      _loadMedications();
    } else {
      debugPrint(
          '[TodayMeds] ⚠️ No Elder argument — type: ${args.runtimeType}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل بيانات كبير السن';
      });
    }
  }

  // ── جلب البيانات ──────────────────────────────────────────────────────────
  Future<void> _loadMedications() async {
    if (_elder?.id == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل بيانات كبير السن';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
          '[TodayMeds] 🌐 Fetching medications for elder id=${_elder!.id}');
      final meds =
          await ApiService.getElderMedications(elderId: _elder!.id!);

      meds.sort((a, b) => a.firstReminderTime.compareTo(b.firstReminderTime));

      debugPrint('[TodayMeds] ✅ Loaded ${meds.length} medications');
      setState(() {
        _allMedications = meds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[TodayMeds] ❌ Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل أدوية اليوم، يرجى المحاولة مجدداً';
      });
    }
  }

  // ── منطق التصفية ──────────────────────────────────────────────────────────
  List<ElderMedication> get _filteredMedications {
    switch (_activeFilter) {
      case _FilterTab.morning:
        return _allMedications.where(_isMorning).toList();
      case _FilterTab.evening:
        return _allMedications.where((m) => !_isMorning(m)).toList();
      case _FilterTab.all:
        return _allMedications;
    }
  }

  List<ElderMedication> get _morningMedications =>
      _filteredMedications.where(_isMorning).toList();

  List<ElderMedication> get _eveningMedications =>
      _filteredMedications.where((m) => !_isMorning(m)).toList();

  bool _isMorning(ElderMedication med) {
    try {
      final t = med.firstReminderTime;
      if (t.contains('م')) return false;
      if (t.contains('ص')) return true;
      final parts = t.split(':');
      final hour = int.parse(parts[0]);
      return hour < 12;
    } catch (_) {
      return true;
    }
  }

  // ── تنسيق الوقت — لا يُضاف ص/م مرتين ─────────────────────────────────────
  String _formatTime(String time) {
    if (time.contains('ص') || time.contains('م')) return time;
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      final period = hour < 12 ? 'ص' : 'م';
      final displayHour = hour == 0
          ? 12
          : hour > 12
              ? hour - 12
              : hour;
      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }

  // ── منطق عنوان الدواء ─────────────────────────────────────────────────────
  // الأولوية:
  // 1. displayNameForElder موجود → يُعرض كما هو
  // 2. displayNameForElder فارغ + medCategory موجود → "دواء {medCategory}"
  //    (إذا كانت medCategory تبدأ بـ "دواء" لا يُضاف مرة أخرى)
  // 3. كلاهما فارغان → brandNameAr مباشرة (بدون "دواء" عام)
  String _getMedicationDisplayName(ElderMedication med) {
    // 1. displayNameForElder
    final custom = med.displayNameForElder;
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }

    // 2. medCategory مع بادئة "دواء"
    final category = med.medCategory;
    if (category != null && category.trim().isNotEmpty) {
      final cleanCategory = category.trim();
      // تجنب التكرار: إذا كانت الفئة تبدأ بـ "دواء" لا نُضيفها مرة أخرى
      if (cleanCategory.startsWith('دواء')) {
        return cleanCategory;
      }
      return 'دواء $cleanCategory';
    }

    // 3. fallback: brandNameAr مباشرة (بدون "دواء" عام)
    return med.brandNameAr;
  }

  // ── صورة الدواء — نفس منطق ElderHomeScreen ────────────────────────────────
  Widget _buildMedIcon(String? gtin) {
    if (gtin == null || gtin.trim().isEmpty) {
      return const Icon(Icons.medication, size: 56, color: AppColors.primary);
    }
    final cleanGtin = gtin.replaceAll(RegExp(r'[^0-9]'), '');
    final padded14 = cleanGtin.padLeft(14, '0');
    final paths = [
      'assets/drug_images/$cleanGtin.jpg',
      'assets/drug_images/$cleanGtin.png',
      'assets/drug_images/$padded14.jpg',
      'assets/drug_images/$padded14.png',
    ];

    Widget fallback(int index) {
      if (index >= paths.length) {
        return const Icon(Icons.medication, size: 56, color: AppColors.primary);
      }
      return Image.asset(
        paths[index],
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback(index + 1),
      );
    }

    return fallback(0);
  }

  // ── بناء الواجهة ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FBFC),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'الأدوية',
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.normal,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: Divider(height: 2, thickness: 2, color: Color(0xFFE5E7EB)),
      ),
    );
  }

  // ── شريط التصفية — الكل | صباح | مساء (يمين → يسار في RTL) ──────────────
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'تصفية حسب الفترة',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 18,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: _FilterButton(
                  label: 'الكـل',
                  isActive: _activeFilter == _FilterTab.all,
                  onTap: () => setState(() => _activeFilter = _FilterTab.all),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterButton(
                  label: 'صباح',
                  isActive: _activeFilter == _FilterTab.morning,
                  onTap: () =>
                      setState(() => _activeFilter = _FilterTab.morning),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterButton(
                  label: 'مساء',
                  isActive: _activeFilter == _FilterTab.evening,
                  onTap: () =>
                      setState(() => _activeFilter = _FilterTab.evening),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── جسم الشاشة ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_filteredMedications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMedications,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          if (_morningMedications.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'أدوية الصباح',
              subtitle: '6:00 ص - 12:00 م',
            ),
            const SizedBox(height: 16),
            ..._morningMedications.map(
              (med) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MedicationCard(
                  medication: med,
                  displayName: _getMedicationDisplayName(med),
                  formattedTime: _formatTime(med.firstReminderTime),
                  medIcon: _buildMedIcon(med.gtin),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_eveningMedications.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'أدوية المساء',
              subtitle: '12:00 م - 12:00 ص',
            ),
            const SizedBox(height: 16),
            ..._eveningMedications.map(
              (med) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MedicationCard(
                  medication: med,
                  displayName: _getMedicationDisplayName(med),
                  formattedTime: _formatTime(med.firstReminderTime),
                  medIcon: _buildMedIcon(med.gtin),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── رأس القسم — محاذاة يمين دائماً ──────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 18,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  // ── حالة فارغة ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أدوية مجدولة لهذا اليوم',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 20,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  // ── حالة خطأ ──────────────────────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 72, color: Color(0xFFC0392B)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC0392B),
              fontSize: 20,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMedications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// زر التصفية
// ════════════════════════════════════════════════════════════════════════════
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? null
              : Border.all(color: const Color(0xFFD1D5DB), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontSize: 18,
            fontFamily: 'Tajawal',
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// بطاقة الدواء
// ════════════════════════════════════════════════════════════════════════════
class _MedicationCard extends StatelessWidget {
  final ElderMedication medication;
  final String displayName;
  final String formattedTime;
  final Widget medIcon;

  const _MedicationCard({
    required this.medication,
    required this.displayName,
    required this.formattedTime,
    required this.medIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: Column(
        children: [
          // ── صورة/أيقونة الدواء ──────────────────────────────────────────
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFE8F8FA),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: medIcon,
          ),
          const SizedBox(height: 16),
          // ── العنوان الرئيسي: displayNameForElder أو "دواء {medCategory}" ──
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          // ── brandNameAr دائماً كعنوان فرعي ──────────────────────────────
          Text(
            medication.brandNameAr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 18,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 10),
          // ── وقت التذكير ─────────────────────────────────────────────────
          Text(
            formattedTime,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 16),
          // ── شارة الحالة ─────────────────────────────────────────────────
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = _computeStatus();

    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case _DoseStatus.taken:
        bgColor = const Color(0xFFD4F5F9);
        textColor = const Color(0xFF003948);
        label = 'تم تناوله';
        break;
      case _DoseStatus.missed:
        bgColor = const Color(0xFFF6E6C8);
        textColor = const Color(0xFF663C00);
        label = 'فائت';
        break;
      case _DoseStatus.pending:
        bgColor = const Color(0xFFFFF3D6);
        textColor = const Color(0xFF4A3200);
        label = 'قيد الانتظار';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  _DoseStatus _computeStatus() {
    try {
      final now = DateTime.now();
      var timeStr = medication.firstReminderTime
          .replaceAll('ص', '')
          .replaceAll('م', '')
          .trim();
      final parts = timeStr.split(':');
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts.length > 1 ? parts[1] : '0');

      if (medication.firstReminderTime.contains('م') && hour < 12) {
        hour += 12;
      }

      final doseTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (now.isAfter(doseTime.add(const Duration(hours: 2)))) {
        return _DoseStatus.missed;
      }
      return _DoseStatus.pending;
    } catch (_) {
      return _DoseStatus.pending;
    }
  }
}

// ── تعداد حالات الجرعة ────────────────────────────────────────────────────
enum _DoseStatus { taken, missed, pending }
