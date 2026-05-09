// lib/screens/elder_today_medications_screen.dart
//
// شاشة أدوية اليوم لكبير السن — مسار: '/elder-today-schedule'
//
// منطق عنوان الدواء:
//   1. displayNameForElder موجود → يُعرض كما هو
//   2. displayNameForElder فارغ + medCategory موجود → "دواء {medCategory}"
//   3. كلاهما فارغان → brandNameAr مباشرة
//
// ملاحظة مهمة:
//   هذه الشاشة تعرض جرعات اليوم الفعلية فقط من medication_doses
//   وليست خطة الأدوية العامة من elder_medications.

import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../models/dose.dart';
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
  List<Dose> _allDoses = [];
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
          '[TodayMeds] 🌐 Fetching today doses for elder id=${_elder!.id}');

      // Ensure today's dose records exist before loading this screen.
      // The backend prevents duplicate doses, so calling this again is safe.
      await ApiService.generateTodayDoses(elderId: _elder!.id!);

      final doses = await ApiService.getTodayDoses(elderId: _elder!.id!);

      doses.sort((a, b) {
        final aMinutes = _parseTimeToMinutes(a.effectiveTime) ?? 0;
        final bMinutes = _parseTimeToMinutes(b.effectiveTime) ?? 0;
        return aMinutes.compareTo(bMinutes);
      });

      debugPrint('[TodayMeds] ✅ Loaded ${doses.length} today doses');
      setState(() {
        _allDoses = doses;
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
  List<Dose> get _filteredDoses {
    switch (_activeFilter) {
      case _FilterTab.morning:
        return _allDoses.where(_isMorning).toList();
      case _FilterTab.evening:
        return _allDoses.where((d) => !_isMorning(d)).toList();
      case _FilterTab.all:
        return _allDoses;
    }
  }

  List<Dose> get _morningDoses => _filteredDoses.where(_isMorning).toList();

  List<Dose> get _eveningDoses =>
      _filteredDoses.where((d) => !_isMorning(d)).toList();

  bool _isMorning(Dose dose) {
    final minutes = _parseTimeToMinutes(dose.effectiveTime);
    if (minutes == null) return true;
    return minutes < 12 * 60;
  }

  int? _parseTimeToMinutes(String timeStr) {
    final arabicMatch =
        RegExp(r'(\d{1,2}):(\d{2})\s*([صم])').firstMatch(timeStr);
    if (arabicMatch != null) {
      int hour = int.parse(arabicMatch.group(1)!);
      final minute = int.parse(arabicMatch.group(2)!);
      final period = arabicMatch.group(3)!;

      if (period == 'م' && hour != 12) hour += 12;
      if (period == 'ص' && hour == 12) hour = 0;

      return hour * 60 + minute;
    }

    final isoMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(timeStr);
    if (isoMatch != null) {
      final hour = int.parse(isoMatch.group(1)!);
      final minute = int.parse(isoMatch.group(2)!);
      return hour * 60 + minute;
    }

    return null;
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
  String _getMedicationDisplayName(Dose dose) {
    // 1. displayNameForElder / medicationName from backend
    if (dose.medicationName.trim().isNotEmpty) {
      return dose.medicationName.trim();
    }

    // 2. medCategory مع بادئة "دواء"
    final category = dose.medCategory;
    if (category != null && category.trim().isNotEmpty) {
      final cleanCategory = category.trim();
      // تجنب التكرار: إذا كانت الفئة تبدأ بـ "دواء" لا نُضيفها مرة أخرى
      if (cleanCategory.startsWith('دواء')) {
        return cleanCategory;
      }
      return 'دواء $cleanCategory';
    }

    // 3. fallback: brandNameAr مباشرة (بدون "دواء" عام)
    return dose.brandNameAr;
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
      automaticallyImplyLeading: false,

      // Keep the back icon on the left side of the header.
      // In RTL screens, actions appear on the left.
      actions: [
        IconButton(
          // Keep the icon on the left, and force the arrow head to point left.
          icon: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
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

    if (_filteredDoses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadMedications,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          if (_morningDoses.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'أدوية الصباح',
              subtitle: '6:00 ص - 12:00 م',
            ),
            const SizedBox(height: 16),
            ..._morningDoses.map(
              (dose) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MedicationCard(
                  dose: dose,
                  displayName: _getMedicationDisplayName(dose),
                  formattedTime: _formatTime(dose.effectiveTime),
                  medIcon: _buildMedIcon(dose.gtin),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_eveningDoses.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'أدوية المساء',
              subtitle: '12:00 م - 12:00 ص',
            ),
            const SizedBox(height: 16),
            ..._eveningDoses.map(
              (dose) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MedicationCard(
                  dose: dose,
                  displayName: _getMedicationDisplayName(dose),
                  formattedTime: _formatTime(dose.effectiveTime),
                  medIcon: _buildMedIcon(dose.gtin),
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
          Icon(Icons.medication_outlined,
              size: 72, color: Colors.grey.shade300),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
  final Dose dose;
  final String displayName;
  final String formattedTime;
  final Widget medIcon;

  const _MedicationCard({
    required this.dose,
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
            dose.brandNameAr,
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
    final status = _statusInfo(dose.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            color: status.textColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(
              color: status.textColor,
              fontSize: 18,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _DoseStatusInfo _statusInfo(String status) {
    switch (status) {
      case 'taken':
        return const _DoseStatusInfo(
          label: 'تم الأخذ',
          bgColor: Color(0xFFDFF7E8),
          textColor: Color(0xFF166534),
          icon: Icons.check_circle,
        );
      case 'missed':
      case 'no_response':
        return const _DoseStatusInfo(
          label: 'فائتة',
          bgColor: Color(0xFFFFF1E6),
          textColor: Color(0xFFB45309),
          icon: Icons.warning_amber_rounded,
        );
      case 'snoozed':
        return const _DoseStatusInfo(
          label: 'مؤجلة',
          bgColor: Color(0xFFFFE8CC),
          textColor: Color(0xFFB45309),
          icon: Icons.schedule,
        );
      case 'pending':
      default:
        return const _DoseStatusInfo(
          label: 'قيد الانتظار',
          bgColor: Color(0xFFE0F7F8),
          textColor: Color(0xFF0F7C83),
          icon: Icons.access_time,
        );
    }
  }
}

// ── بيانات عرض حالة الجرعة ────────────────────────────────────────────────
class _DoseStatusInfo {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const _DoseStatusInfo({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });
}
