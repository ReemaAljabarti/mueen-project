// lib/screens/elder_home_screen.dart
//
// التغييرات في هذه النسخة:
//   - استبدال BottomNavigationBar المدمج بـ ElderBottomNavBar الموحّد
//   - تمرير _elder للـ ElderBottomNavBar بشكل صريح
//   - currentIndex: 0 (الرئيسية نشطة)
//   - لا تغيير في منطق تحميل البيانات أو واجهة المستخدم

import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../models/elder_medication.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/elder_bottom_nav_bar.dart';
import '../services/current_elder.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  // ─── State ───────────────────────────────────────────────────────────────
  List<ElderMedication> _medications = [];
  bool _isLoading = true;
  String? _errorMessage;
  Elder? _elder;

  bool _initialized = false;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    debugPrint('[ElderHome] route arguments type: ${args.runtimeType}');
    debugPrint('[ElderHome] route arguments value: $args');

    if (args is Elder) {
      _elder = args;
    } else {
      _elder = currentElder;
    }

    if (_elder == null) {
      debugPrint(
          '[ElderHome] ❌ Elder is null — no argument was passed from login');
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل بيانات كبير السن';
      });
      return;
    }

    if (_elder!.id == null) {
      debugPrint('[ElderHome] ❌ Elder.id is null — elder=${_elder!.fullName}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل بيانات كبير السن';
      });
      return;
    }

    debugPrint(
        '[ElderHome] ✅ Elder loaded → id=${_elder!.id}, name=${_elder!.fullName}');
    _loadMedications(_elder!.id!);
  }

// Checks if there are any due medication doses for the elder.
// Calls the backend API (/reminders/due-now/{elder_id}).
// If there are pending doses (count > 0), it navigates to the dose alert screen.
// The screen receives the list of due doses to display them to the user.
// Note: elder is temporarily set to null and will be replaced with actual user data later.

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadMedications(int elderId) async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final apiUrl = '${ApiService.baseUrl}/elder-medications/$elderId';
    debugPrint('[ElderHome] 🌐 Calling API: $apiUrl');

    try {
      final data = await ApiService.getElderMedications(elderId: elderId);

      debugPrint('[ElderHome] ✅ Medications loaded: ${data.length} items');
      for (final med in data) {
        debugPrint(
            '  → id=${med.id}, name=${med.brandNameAr}, time=${med.firstReminderTime}');
      }

      if (!mounted) return;

      setState(() {
        _medications = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('[ElderHome] ❌ getElderMedications failed: $e');
      debugPrint('[ElderHome] StackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل الأدوية، يرجى المحاولة مجدداً';
      });
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  ElderMedication? _getNextDose() {
    if (_medications.isEmpty) return null;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    ElderMedication? next;
    int minDiff = 1440;

    for (final med in _medications) {
      final parsed = _parseTimeToMinutes(med.firstReminderTime);
      if (parsed == null) continue;

      final diff = (parsed - nowMinutes + 1440) % 1440;
      if (diff < minDiff) {
        minDiff = diff;
        next = med;
      }
    }

    return next;
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

  String _formatTimeDiff(int diffMinutes) {
    if (diffMinutes == 0) return 'الآن';
    if (diffMinutes < 60) return 'بعد $diffMinutes دقيقة';
    final hours = diffMinutes ~/ 60;
    final mins = diffMinutes % 60;
    if (mins == 0) {
      return 'بعد $hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
    }
    return 'بعد $hours ساعة و$mins دقيقة';
  }

  List<String> _getSortedReminderTimes() {
    final times = _medications.map((m) => m.firstReminderTime).toSet().toList();
    times.sort((a, b) {
      final ma = _parseTimeToMinutes(a) ?? 0;
      final mb = _parseTimeToMinutes(b) ?? 0;
      return ma.compareTo(mb);
    });
    return times;
  }

  bool _isTimePast(String timeStr) {
    final parsed = _parseTimeToMinutes(timeStr);
    if (parsed == null) return false;
    final now = TimeOfDay.now();
    return parsed < now.hour * 60 + now.minute;
  }

  String _getMedDisplayName(ElderMedication med) {
    final custom = med.displayNameForElder;
    if (custom != null && custom.trim().isNotEmpty) return custom;
    return med.brandNameAr;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (_elder?.id != null) {
              await _loadMedications(_elder!.id!);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGreeting(),
                const SizedBox(height: 16),
                _buildNextDoseCard(),
                const SizedBox(height: 24),
                const Text(
                  'الأدوية',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 12),
                _buildMedicationsGrid(),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'مرر للأسفل لعرض جدول اليوم',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'الجدول الزمني لأدوية اليوم',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 12),
                _buildSchedule(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.mic),
      ),
      // ── شريط التنقل الموحّد ──────────────────────────────────────────────
      bottomNavigationBar: ElderBottomNavBar(
        currentIndex: 0, // الرئيسية نشطة
        elder: _elder,
      ),
    );
  }

  // ─── Sub-Widgets ──────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    final hour = TimeOfDay.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء النور';
    }

    return Center(
      child: Text(
        greeting,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildNextDoseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          : _errorMessage != null
              ? _buildErrorContent(_errorMessage!)
              : _buildNextDoseContent(),
    );
  }

  Widget _buildNextDoseContent() {
    final nextDose = _getNextDose();

    if (nextDose == null) {
      return Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 40, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            'لا توجد جرعات قادمة اليوم',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final nextMinutes = _parseTimeToMinutes(nextDose.firstReminderTime) ?? 0;
    final diff = (nextMinutes - nowMinutes + 1440) % 1440;
    final medName = _getMedDisplayName(nextDose);

    return Column(
      children: [
        Text(
          'ملخص الجرعة القادمة',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nextDose.firstReminderTime,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatTimeDiff(diff),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          medName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Tajawal',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'لديك ${_medications.length} ${_medications.length == 1 ? 'دواء' : 'أدوية'}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorContent(_errorMessage!);
    }

    if (_medications.isEmpty) {
      return _buildEmptyContent('لا توجد أدوية مضافة بعد');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _medications.length,
      itemBuilder: (_, index) => _buildMedGridItem(_medications[index]),
    );
  }

  Widget _buildMedGridItem(ElderMedication med) {
    final name = _getMedDisplayName(med);

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF3F4F6),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: _buildMedIcon(med.gtin),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  Widget _buildMedIcon(String? gtin) {
    if (gtin == null || gtin.trim().isEmpty) {
      return const Icon(Icons.medication, size: 40, color: AppColors.primary);
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
        return const Icon(Icons.medication, size: 40, color: AppColors.primary);
      }
      return Image.asset(
        paths[index],
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback(index + 1),
      );
    }

    return fallback(0);
  }

  Widget _buildSchedule() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorContent(_errorMessage!);
    }

    final times = _getSortedReminderTimes();

    if (times.isEmpty) {
      return _buildEmptyContent('لا توجد مواعيد مجدولة لهذا اليوم');
    }

    return Column(
      children: times
          .map((time) => _buildScheduleItem(time, _isTimePast(time)))
          .toList(),
    );
  }

  Widget _buildScheduleItem(String time, bool isTaken) {
    final medsAtTime = _medications
        .where((m) => m.firstReminderTime == time)
        .map(_getMedDisplayName)
        .toList();

    final medNames = medsAtTime.isNotEmpty ? medsAtTime.join('، ') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isTaken ? Icons.check_circle : Icons.access_time,
            color: isTaken ? Colors.green : Colors.orange,
            size: 20,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Tajawal',
                ),
              ),
              if (medNames.isNotEmpty)
                Text(
                  medNames,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Shared State Widgets ─────────────────────────────────────────────────

  Widget _buildErrorContent(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          if (_elder?.id != null)
            TextButton.icon(
              onPressed: () => _loadMedications(_elder!.id!),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}
