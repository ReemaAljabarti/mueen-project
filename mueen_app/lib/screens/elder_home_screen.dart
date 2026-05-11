// lib/screens/elder_home_screen.dart
//
// التغييرات في هذه النسخة:
//   - استبدال BottomNavigationBar المدمج بـ ElderBottomNavBar الموحّد
//   - تمرير _elder للـ ElderBottomNavBar بشكل صريح
//   - currentIndex: 0 (الرئيسية نشطة)
//   - لا تغيير في منطق تحميل البيانات أو واجهة المستخدم

import 'dart:async';

import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/elder_bottom_nav_bar.dart';
import '../services/current_elder.dart';
import '../services/dose_alert_service.dart';
import '../models/dose.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  // ─── State ───────────────────────────────────────────────────────────────
  Dose? _nextDose;
  List<Dose> _todayDoses = [];
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _countdownTimer;
  bool _isBackgroundRefreshRunning = false;

  Elder? _elder;

  bool _initialized = false;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Refresh the countdown while the elder stays on the home screen.
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;

      final elderId = _elder?.id;

      if (elderId == null) {
        setState(() {});
        return;
      }

      // Refresh the home data so dose status changes appear automatically.
      await _loadHomeData(elderId);
    });

    // Refresh immediately when Dose Alert closes.
    DoseAlertService.homeRefreshSignal.addListener(_refreshHomeAfterDoseAlert);
  }

// This is called when returning from the dose alert screen after taking/snoozing/missing a dose.
// It triggers a background refresh of the home data to reflect any status changes.
  Future<void> _refreshHomeAfterDoseAlert() async {
    if (!mounted) return;

    final elderId = _elder?.id;
    if (elderId == null) return;

    debugPrint('[ElderHome] 🔄 Refreshing immediately after Dose Alert');
    await _loadHomeData(elderId);
  }

//============================
  @override
  void dispose() {
    DoseAlertService.homeRefreshSignal
        .removeListener(_refreshHomeAfterDoseAlert);
    _countdownTimer?.cancel();
    super.dispose();
  }

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
    _loadHomeData(_elder!.id!);
  }

// Checks if there are any due medication doses for the elder.
// Calls the backend API (/reminders/due-now/{elder_id}).
// If there are pending doses (count > 0), it navigates to the dose alert screen.
// The screen receives the list of due doses to display them to the user.
// Note: elder is temporarily set to null and will be replaced with actual user data later.

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadHomeData(
    int elderId, {
    bool showLoading = true,
  }) async {
    final hasExistingData = _nextDose != null || _todayDoses.isNotEmpty;

    if (showLoading && !hasExistingData) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    debugPrint('[ElderHome] 🌐 Loading home data for elderId=$elderId');

    try {
      // Ensure today's dose records exist before loading the home screen.
      // The backend prevents duplicate doses, so calling this again is safe.
      await ApiService.generateTodayDoses(elderId: elderId);

      // Load the closest upcoming dose for the top card.
      final nextDose = await ApiService.getNextDose(elderId: elderId);

      // Load all today's doses for the daily timeline.
      final todayDoses = await ApiService.getTodayDoses(elderId: elderId);

      debugPrint('[ElderHome] ✅ Next dose loaded: ${nextDose?.displayName}');
      debugPrint('[ElderHome] ✅ Today doses loaded: ${todayDoses.length}');

      if (!mounted) return;

      setState(() {
        _nextDose = nextDose;
        _todayDoses = todayDoses;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('[ElderHome] ❌ load home data failed: $e');
      debugPrint('[ElderHome] StackTrace: $stackTrace');

      if (!mounted) return;

      if (showLoading || !hasExistingData) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تحميل بيانات الجرعات، يرجى المحاولة مجدداً';
        });
      }
    }
  }

  Future<void> _refreshHomeDataInBackground(int elderId) async {
    if (_isBackgroundRefreshRunning) return;

    _isBackgroundRefreshRunning = true;

    try {
      // Refresh silently after dose alert actions or medication changes.
      await _loadHomeData(elderId, showLoading: false);
    } finally {
      _isBackgroundRefreshRunning = false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
    if (diffMinutes <= 0) return 'الآن';
    if (diffMinutes < 60) return 'بعد $diffMinutes دقيقة';
    final hours = diffMinutes ~/ 60;
    final mins = diffMinutes % 60;
    if (mins == 0) {
      return 'بعد $hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
    }
    return 'بعد $hours ساعة و$mins دقيقة';
  }

  //=================
  String _formatTime12Hour(String timeStr) {
    final minutes = _parseTimeToMinutes(timeStr);

    if (minutes == null) {
      return timeStr;
    }

    final hour24 = minutes ~/ 60;
    final minute = minutes % 60;

    final period = hour24 < 12 ? 'ص' : 'م';
    var hour12 = hour24 % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }
  //======================

  int? _getDoseEffectiveMinutes(Dose dose) {
    return _parseTimeToMinutes(dose.effectiveTime);
  }

  bool _isUpcomingDose(Dose dose) {
    if (dose.status == 'taken' ||
        dose.status == 'missed' ||
        dose.status == 'no_response') {
      return false;
    }

    final doseMinutes = _getDoseEffectiveMinutes(dose);
    if (doseMinutes == null) return false;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return doseMinutes >= nowMinutes;
  }

  List<Dose> _getNextDoseGroup() {
    final upcomingDoses = _todayDoses.where(_isUpcomingDose).toList();

    if (upcomingDoses.isEmpty) {
      return _nextDose == null ? [] : [_nextDose!];
    }

    upcomingDoses.sort((a, b) {
      final aMinutes = _getDoseEffectiveMinutes(a) ?? 0;
      final bMinutes = _getDoseEffectiveMinutes(b) ?? 0;
      return aMinutes.compareTo(bMinutes);
    });

    final firstDoseMinutes = _getDoseEffectiveMinutes(upcomingDoses.first);
    if (firstDoseMinutes == null) return [];

    // Show doses that are at the same time or very close to the next dose.
    // This helps when the elder has two or more doses within 10 minutes.
    return upcomingDoses.where((dose) {
      final doseMinutes = _getDoseEffectiveMinutes(dose);
      if (doseMinutes == null) return false;

      return (doseMinutes - firstDoseMinutes).abs() <= 10;
    }).toList();
  }

  String _getDoseStatusText(String status) {
    switch (status) {
      case 'taken':
        return 'تم الأخذ';
      case 'missed':
        return 'فائتة';
      case 'snoozed':
        return 'مؤجلة';
      case 'no_response':
        return 'فائتة';
      case 'pending':
      default:
        return 'قادمة';
    }
  }

  IconData _getDoseStatusIcon(String status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle;
      case 'missed':
      case 'no_response':
        return Icons.cancel;
      case 'snoozed':
        return Icons.schedule;
      case 'pending':
      default:
        return Icons.access_time;
    }
  }

  Color _getDoseStatusColor(String status) {
    switch (status) {
      case 'taken':
        return Colors.green;
      case 'missed':
      case 'no_response':
        return Colors.red;
      case 'snoozed':
        return Colors.orange;
      case 'pending':
      default:
        return AppColors.primary;
    }
  }

  Widget _buildDoseStatusChip(String status) {
    final color = _getDoseStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDoseStatusIcon(status),
            color: color,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            _getDoseStatusText(status),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHomeHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (_elder?.id != null) {
                    await _loadHomeData(_elder!.id!);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNextDoseCard(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 72,
        height: 72,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/voice-assistant');
          },
          backgroundColor: AppColors.primary,
          elevation: 6,
          child: const Icon(
            Icons.mic,
            size: 34,
            color: Colors.white,
          ),
        ),
      ),
      // ── شريط التنقل الموحّد ──────────────────────────────────────────────
      bottomNavigationBar: ElderBottomNavBar(
        currentIndex: 0, // الرئيسية نشطة
        elder: _elder,
      ),
    );
  }

  // ─── Sub-Widgets ──────────────────────────────────────────────────────────

  Widget _buildHomeHeader() {
    final elderName = (_elder?.fullName.trim().isNotEmpty ?? false)
        ? _elder!.fullName.trim()
        : '';

    final hour = TimeOfDay.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else {
      greeting = 'مساء الخير';
    }

    final String greetingText =
        elderName.isEmpty ? greeting : '$greeting، $elderName';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      color: Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Image.asset(
              'assets/fonts/images/mueenicon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              greetingText,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildNextDoseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          : _errorMessage != null
              ? _buildErrorContent(_errorMessage!)
              : _buildNextDoseContent(),
    );
  }

  Widget _buildNextDoseContent() {
    final nextDoses = _getNextDoseGroup();

    if (nextDoses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 58,
              color: Colors.green,
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد جرعات قادمة اليوم',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey.shade600,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final firstDose = nextDoses.first;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final nextMinutes = _parseTimeToMinutes(firstDose.effectiveTime) ?? 0;
    final diff = nextMinutes - nowMinutes;

    return Column(
      children: [
        Text(
          'الجرعة القادمة',
          style: TextStyle(
            fontSize: 21,
            color: Colors.grey.shade700,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _formatTime12Hour(firstDose.effectiveTime),
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatTimeDiff(diff < 0 ? 0 : diff),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildNextDoseCardsLayout(nextDoses),
      ],
    );
  }

  Widget _buildNextDoseCardsLayout(List<Dose> doses) {
    if (doses.length == 1) {
      return Center(
        child: SizedBox(
          width: 230,
          child: _buildSimpleDoseCard(
            doses.first,
            isSingleDose: true,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: doses.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          return _buildSimpleDoseCard(doses[index]);
        },
      ),
    );
  }

  Widget _buildSimpleDoseCard(
    Dose dose, {
    bool isSingleDose = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSingleDose ? 16 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5F4F5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: isSingleDose ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSingleDose ? 128 : double.infinity,
            height: isSingleDose ? 128 : 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: _buildMedIcon(dose.gtin),
          ),
          const SizedBox(height: 14),
          Text(
            dose.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSingleDose ? 22 : 19,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              height: 1.25,
            ),
            maxLines: isSingleDose ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

//=================================
  Widget _buildMedIcon(String? gtin) {
    if (gtin == null || gtin.trim().isEmpty) {
      return const Icon(
        Icons.medication,
        size: 64,
        color: AppColors.primary,
      );
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
        return const Icon(
          Icons.medication,
          size: 64,
          color: AppColors.primary,
        );
      }

      return Image.asset(
        paths[index],
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback(index + 1),
      );
    }

    return fallback(0);
  }

  Widget _buildScrollHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primary,
            size: 28,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'مرر للأسفل لرؤية المزيد من جرعات اليوم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
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

    if (_todayDoses.isEmpty) {
      return _buildEmptyContent('لا توجد مواعيد مجدولة لهذا اليوم');
    }

    return Column(
      children: _todayDoses.map((dose) => _buildScheduleItem(dose)).toList(),
    );
  }

  Widget _buildScheduleItem(Dose dose) {
    final statusColor = _getDoseStatusColor(dose.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildDoseStatusChip(dose.status),
          const Spacer(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dose.effectiveTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dose.displayName,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 18,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            _getDoseStatusIcon(dose.status),
            color: statusColor,
            size: 24,
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
              fontSize: 18,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          if (_elder?.id != null)
            TextButton.icon(
              onPressed: () => _loadHomeData(_elder!.id!),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 18),
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
            fontSize: 18,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}
