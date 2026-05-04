// ============================================================
// lib/screens/dose_alert/dose_alert_flow.dart
//
// تدفق تذكير الجرعات — تطبيق مُعين
// Dose Alert Flow — Mu'een App
//
// الحالات المغطاة:
//  • الشاشة الرئيسية مع مؤقت حقيقي
//  • تأكيد الأخذ / نجاح الأخذ
//  • خيارات التأجيل / نجاح التأجيل
//  • تأكيد عدم الأخذ / نجاح عدم الأخذ
//  • انتهاء الوقت
//  • ملخص نهائي (كل مأخوذ / تأجيل / فائت / مختلط)
//
// نقاط التكامل المستقبلي:
//  ابحث عن تعليقات "TODO(api):" في الكود
// ============================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/elder.dart';
import '../services/current_elder.dart';

// ---------------------------------------------------------------------------
// نظام الألوان — مستخرج من Figma
// ---------------------------------------------------------------------------
class _C {
  static const Color bg = Color(0xFFF5FBFC);
  static const Color primary = Color(0xFF15B4BE);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF8A9AA0);
  static const Color white = Colors.white;
  static const Color warning = Color(0xFFE6A817);
  static const Color warningBg = Color(0xFFFFF3CD);
  static const Color danger = Color(0xFFE57373);
  static const Color dangerBg = Color(0xFFFFF0F0);
  static const Color successBg = Color(0xFFE0F7F8);
  static const Color snoozeBg = Color(0xFFFFF8E1);
}

// ---------------------------------------------------------------------------
// نظام الخطوط
// ---------------------------------------------------------------------------
class _T {
  static const String font = 'Tajawal';

  static const TextStyle pageTitle = TextStyle(
    fontFamily: font,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: _C.black,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: font,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: _C.black,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: font,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: _C.black,
  );

  static const TextStyle body = TextStyle(
    fontFamily: font,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: _C.black,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: font,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: _C.grey,
  );

  static const TextStyle timer = TextStyle(
    fontFamily: font,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: _C.black,
  );

  static const TextStyle btnPrimary = TextStyle(
    fontFamily: font,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: _C.white,
  );

  static const TextStyle btnSecondary = TextStyle(
    fontFamily: font,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: _C.black,
  );
}

// ---------------------------------------------------------------------------
// نماذج البيانات
// ---------------------------------------------------------------------------
enum DoseStatus { pending, taken, missed, snoozed, noResponse }

class MedicationDose {
  final String id;
  final String? optionalDisplayName;
  final String brandNameAr;
  final String medCategory;
  final String genericName;
  final String strength;
  final String quantity;
  final String route;
  final String usageInstruction;
  final String foodInstruction;
  final String? gtin;
  final int? elderMedicationId;

  DoseStatus status;
  bool hasBeenSnoozed;
  int? snoozeMinutes;

  MedicationDose({
    required this.id,
    this.elderMedicationId,
    this.optionalDisplayName,
    required this.brandNameAr,
    required this.medCategory,
    required this.genericName,
    required this.strength,
    required this.quantity,
    required this.route,
    required this.usageInstruction,
    required this.foodInstruction,
    this.gtin,
    this.status = DoseStatus.pending,
    this.hasBeenSnoozed = false,
    this.snoozeMinutes,
  });

  String get displayTitle {
    if (optionalDisplayName != null && optionalDisplayName!.trim().isNotEmpty) {
      return optionalDisplayName!.trim();
    }

    if (medCategory.trim().isNotEmpty) {
      return 'دواء $medCategory';
    }

    return brandNameAr.trim().isNotEmpty ? brandNameAr : 'دواء';
  }

  String get displaySubtitle {
    final parts = [
      brandNameAr,
      genericName,
      strength,
    ].where((value) => value.trim().isNotEmpty).toList();

    return parts.join(' • ');
  }
}

class AdherenceLog {
  final String doseId;
  final String medicationId;
  final DoseStatus status;
  final DateTime timestamp;
  final int? snoozeMinutes;
  final bool caregiverAlertSent;
  final String? alertReason;

  const AdherenceLog({
    required this.doseId,
    required this.medicationId,
    required this.status,
    required this.timestamp,
    this.snoozeMinutes,
    this.caregiverAlertSent = false,
    this.alertReason,
  });
}

// ---------------------------------------------------------------------------
// Mock Data
// ---------------------------------------------------------------------------
List<MedicationDose> _buildMockDoses() {
  return [
    MedicationDose(
      id: 'dose_1',
      optionalDisplayName: 'دواء سكر',
      brandNameAr: 'فيتامين د',
      medCategory: 'سكري',
      genericName: 'ميتفورمين',
      strength: '500 ملغ',
      quantity: 'قرص واحد',
      route: 'فموي',
      usageInstruction: 'بعد الأكل',
      foodInstruction: 'مع كوب كامل من الماء',
    ),
    MedicationDose(
      id: 'dose_2',
      optionalDisplayName: '',
      brandNameAr: 'أملوديبين',
      medCategory: 'ضغط الدم',
      genericName: 'أملوديبين',
      strength: '10 ملغ',
      quantity: 'قرص واحد',
      route: 'فموي',
      usageInstruction: 'قبل الأكل',
      foodInstruction: 'مع نصف كوب ماء',
    ),
    MedicationDose(
      id: 'dose_3',
      optionalDisplayName: 'فيتامين د',
      brandNameAr: 'كوليكالسيفيرول',
      medCategory: 'فيتامينات',
      genericName: 'كوليكالسيفيرول',
      strength: '1000 وحدة',
      quantity: 'كبسولة واحدة',
      route: 'فموي',
      usageInstruction: 'مع وجبة دسمة',
      foodInstruction: 'مع قليل من الماء',
    ),
    MedicationDose(
      id: 'dose_4',
      optionalDisplayName: null,
      brandNameAr: 'باراسيتامول',
      medCategory: 'مسكن ألم',
      genericName: 'باراسيتامول',
      strength: '500 ملغ',
      quantity: 'قرصان',
      route: 'فموي',
      usageInstruction: 'عند اللزوم',
      foodInstruction: 'مع كوب ماء',
    ),
  ];
}

// ---------------------------------------------------------------------------
// الشاشة الرئيسية للتدفق
// ---------------------------------------------------------------------------
class DoseAlertFlowScreen extends StatefulWidget {
  const DoseAlertFlowScreen({Key? key}) : super(key: key);

  @override
  State<DoseAlertFlowScreen> createState() => _DoseAlertFlowScreenState();
}

class _DoseAlertFlowScreenState extends State<DoseAlertFlowScreen> {
  late List<MedicationDose> _doses;
  int _currentIndex = 0;

  // Timer
  Timer? _timer;
  int _remainingSeconds = 600;
  bool _isTimerExpired = false;

  // Flow
  bool _showSummary = false;

  // Elder reference (passed as route argument)
  Elder? _elder;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // _doses must be initialised before build runs
    _doses = [];
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // Read route arguments: either {doses, elder} Map or a raw List
    final args = ModalRoute.of(context)?.settings.arguments;
    debugPrint('[DoseAlert] route args type: ${args.runtimeType}');
    if (args is Map) {
      final elderArg = args['elder'];
      if (elderArg is Elder) {
        _elder = elderArg;
      } else {
        _elder = currentElder;
      }
      final rawDoses = args['doses'] as List<dynamic>? ?? [];
      final doses = rawDoses.cast<Map<String, dynamic>>();
      if (doses.isNotEmpty) {
        setState(() => _doses = doses.map(_doseFromMap).toList());
        return;
      }
    }
    // Fallback: fetch from API using elder id
    if (_elder?.id != null) {
      _fetchDueDosesFromApi(_elder!.id!);
    } else {
      debugPrint(
          '[DoseAlert] ⚠️ No elder or doses provided — using empty list');
      setState(() => _doses = []);
    }
  }

  /// Convert a raw Map (from backend) to MedicationDose
  MedicationDose _doseFromMap(Map<String, dynamic> m) {
    final displayName = m['display_name_for_elder']?.toString();
    final brandNameAr = m['brand_name_ar']?.toString() ??
        m['medication_name']?.toString() ??
        '';
    final medCategory = m['med_category']?.toString() ?? '';

    final dosageAmount = m['dosage_amount']?.toString() ?? '';
    final dosageUnit = m['dosage_unit']?.toString() ?? '';
    final quantity = '$dosageAmount $dosageUnit'.trim();

    return MedicationDose(
      id: m['dose_id']?.toString() ??
          m['id']?.toString() ??
          UniqueKey().toString(),
      elderMedicationId: int.tryParse(
        m['elder_medication_id']?.toString() ?? '',
      ),
      optionalDisplayName: displayName,
      brandNameAr: brandNameAr,
      medCategory: medCategory,
      genericName: m['generic_name_en']?.toString() ?? '',
      strength: m['dosage_strength']?.toString() ?? '',
      quantity: quantity,
      route: m['route_ar']?.toString() ?? 'عن طريق الفم',
      usageInstruction: m['usage_instruction']?.toString() ?? '',
      foodInstruction: m['food_guide_ar']?.toString() ?? '',
      gtin: m['gtin']?.toString(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Real API Methods
  // -------------------------------------------------------------------------

  /// Fetch due doses from backend (fallback when not passed via arguments)
  Future<void> _fetchDueDosesFromApi(int elderId) async {
    try {
      debugPrint('[DoseAlert] 🌐 Fetching due doses for elder $elderId');
      final result = await ApiService.getDueDoses(elderId: elderId);
      final rawDoses = (result['due_doses'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      debugPrint('[DoseAlert] ✅ Got ${rawDoses.length} due doses');
      if (mounted) setState(() => _doses = rawDoses.map(_doseFromMap).toList());
    } catch (e) {
      debugPrint('[DoseAlert] ❌ getDueDoses failed: $e');
      if (mounted) setState(() => _doses = []);
    }
  }

  /// POST /adherence/taken
  void _apiConfirmTaken(MedicationDose dose) {
    final doseId = int.tryParse(dose.id);
    if (doseId != null) {
      ApiService.markDoseTaken(
        doseId: doseId,
        elderId: _elder?.id ?? 0,
        elderMedicationId: dose.elderMedicationId ?? 0,
      ).then((_) {
        debugPrint('[DoseAlert] ✅ Marked taken: dose $doseId');
      }).catchError((e) {
        debugPrint('[DoseAlert] ⚠️ markDoseTaken failed (non-fatal): $e');
      });
    } else {
      debugPrint(
          '[DoseAlert] ⚠️ Cannot mark taken — dose.id is not numeric: ${dose.id}');
    }
  }

  /// POST /adherence/missed
  void _apiConfirmMissed(MedicationDose dose, {String? reason}) {
    final doseId = int.tryParse(dose.id);
    if (doseId != null) {
      ApiService.markDoseMissed(
        doseId: doseId,
        elderId: _elder?.id ?? 0,
        elderMedicationId: dose.elderMedicationId ?? 0,
        note: reason ?? 'missed_dose',
      ).then((_) {
        debugPrint('[DoseAlert] ✅ Marked missed: dose $doseId');
      }).catchError((e) {
        debugPrint('[DoseAlert] ⚠️ markDoseMissed failed (non-fatal): $e');
      });
    } else {
      debugPrint(
          '[DoseAlert] ⚠️ Cannot mark missed — dose.id is not numeric: ${dose.id}');
    }
  }

  /// POST /reminders/snooze
  void _apiConfirmSnooze(MedicationDose dose, int minutes) {
    final doseId = int.tryParse(dose.id);
    if (doseId != null) {
      ApiService.snoozeDose(
        doseId: doseId,
        elderId: _elder?.id ?? 0,
        elderMedicationId: dose.elderMedicationId ?? 0,
        snoozeMinutes: minutes,
      ).then((_) {
        debugPrint('[DoseAlert] ✅ Snoozed dose $doseId for $minutes min');
      }).catchError((e) {
        debugPrint('[DoseAlert] ⚠️ snoozeDose failed (non-fatal): $e');
      });
    } else {
      debugPrint(
          '[DoseAlert] ⚠️ Cannot snooze — dose.id is not numeric: ${dose.id}');
    }
  }

  /// POST /adherence/no-response
  void _apiNoResponse(MedicationDose dose) {
    final doseId = int.tryParse(dose.id);
    if (doseId != null) {
      ApiService.markDoseNoResponse(
        doseId: doseId,
        elderId: _elder?.id ?? 0,
        elderMedicationId: dose.elderMedicationId ?? 0,
      ).then((_) {
        debugPrint('[DoseAlert] ✅ No-response recorded: dose $doseId');
      }).catchError((e) {
        debugPrint('[DoseAlert] ⚠️ markDoseNoResponse failed (non-fatal): $e');
      });
    } else {
      debugPrint(
          '[DoseAlert] ⚠️ Cannot mark no-response — dose.id is not numeric: ${dose.id}');
    }
  }

  // -------------------------------------------------------------------------
  // Timer
  // -------------------------------------------------------------------------
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _handleTimerExpiration();
      }
    });
  }

  void _handleTimerExpiration() {
    setState(() {
      _isTimerExpired = true;
      _showSummary = true;
      for (final dose in _doses) {
        if (dose.status == DoseStatus.pending) {
          dose.status = DoseStatus.noResponse;
          _apiNoResponse(dose);
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  /// Returns true only when every dose has a final status
  /// (taken, missed, snoozed, or noResponse).
  bool _allDosesCompleted() {
    return _doses.every((d) => d.status != DoseStatus.pending);
  }

  /// Returns the index of the first dose that is still pending,
  /// or null if none remain.
  int? _findNextPendingDoseIndex() {
    for (int i = 0; i < _doses.length; i++) {
      if (_doses[i].status == DoseStatus.pending) return i;
    }
    return null;
  }

  /// Called after the user responds to the current dose.
  /// Moves to the next pending dose, or shows the summary when all are done.
  void _moveToNextDose() {
    if (_allDosesCompleted()) {
      setState(() => _showSummary = true);
      return;
    }

    final nextPending = _findNextPendingDoseIndex();
    if (nextPending != null) {
      setState(() => _currentIndex = nextPending);
    } else {
      // Defensive fallback — should not be reached
      setState(() => _showSummary = true);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: _showSummary
              ? _SummaryScreen(
                  doses: _doses,
                  isTimerExpired: _isTimerExpired,
                  onGoHome: () => Navigator.maybePop(context),
                )
              : _ActiveScreen(
                  doses: _doses,
                  currentIndex: _currentIndex,
                  remainingSeconds: _remainingSeconds,
                  formatTime: _formatTime,
                  onIndexChanged: (i) => setState(() => _currentIndex = i),
                  onTaken: () => _showConfirmTakenDialog(),
                  onMissed: () => _showConfirmMissedDialog(),
                  onSnooze: () => _showSnoozeOptionsSheet(),
                  onVoiceTap: () => _showVoiceAssistantSheet(),
                ),
        ),
        // floatingActionButton removed as requested
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Dialogs & Bottom Sheets
  // -------------------------------------------------------------------------
  void _showConfirmTakenDialog() {
    _showConfirmDialog(
      title: 'هل أخذت الجرعة؟',
      subtitle: 'يرجى تأكيد أنك تناولت الدواء',
      icon: Icons.check_circle_outline_rounded,
      iconBgColor: _C.successBg,
      iconColor: _C.primary,
      onConfirm: () {
        final dose = _doses[_currentIndex];
        dose.status = DoseStatus.taken;
        _apiConfirmTaken(dose);
        _showResultCard(
          title: 'تم تأكيد أخذ الجرعة',
          subtitle: 'سيتم الانتقال إلى الدواء التالي',
          icon: Icons.check_circle_rounded,
          iconBgColor: _C.successBg,
          iconColor: _C.primary,
          onDismiss: _moveToNextDose,
        );
      },
    );
  }

  void _showConfirmMissedDialog() {
    _showConfirmDialog(
      title: 'هل أنت متأكد أنك لم تتناول الجرعة؟',
      subtitle: 'سيتم تسجيل الجرعة على أنها غير مأخوذة',
      icon: Icons.warning_amber_rounded,
      iconBgColor: _C.dangerBg,
      iconColor: _C.danger,
      onConfirm: () {
        final dose = _doses[_currentIndex];
        dose.status = DoseStatus.missed;
        _apiConfirmMissed(dose);
        _showResultCard(
          title: 'تم تسجيل عدم تناول الجرعة',
          subtitle: 'سيتم الانتقال إلى الدواء التالي',
          icon: Icons.warning_amber_rounded,
          iconBgColor: _C.warningBg,
          iconColor: _C.warning,
          onDismiss: _moveToNextDose,
        );
      },
    );
  }

  void _showSnoozeOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance for center alignment
                  Text('اختر وقت التذكير', style: _T.sectionTitle),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, size: 24, color: _C.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('متى تريد أن نذكرك مرة أخرى؟', style: _T.subtitle),
              const SizedBox(height: 24),
              for (final minutes in [15, 20, 30]) ...[
                _SnoozeOptionButton(
                  minutes: minutes,
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleSnoozeSelected(minutes);
                  },
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSnoozeSelected(int minutes) {
    final dose = _doses[_currentIndex];

    if (dose.hasBeenSnoozed) {
      // Snooze not allowed again
      dose.status = DoseStatus.missed;
      _apiConfirmMissed(dose, reason: 'repeated_snooze_attempt');
      _showResultCard(
        title: 'تم تأجيل هذه الجرعة مسبقًا',
        subtitle:
            'لا يمكن تأجيل نفس الجرعة مرة أخرى\nتم تسجيل الجرعة كغير مأخوذة وسيتم إشعار مقدم الرعاية',
        icon: Icons.block_rounded,
        iconBgColor: _C.dangerBg,
        iconColor: _C.danger,
        onDismiss: _moveToNextDose,
      );
    } else {
      dose.status = DoseStatus.snoozed;
      dose.hasBeenSnoozed = true;
      dose.snoozeMinutes = minutes;
      _apiConfirmSnooze(dose, minutes);
      _showResultCard(
        title: 'تم تأجيل التذكير',
        subtitle: 'سيتم تذكيرك في الوقت المحدد',
        icon: Icons.access_time_filled_rounded,
        iconBgColor: _C.snoozeBg,
        iconColor: _C.warning,
        onDismiss: _moveToNextDose,
      );
    }
  }

  void _showConfirmDialog({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: _T.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(subtitle, style: _T.subtitle, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: _C.black, width: 1.5),
                        ),
                        child: const Text('لا', style: _T.btnSecondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('نعم', style: _T.btnPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResultCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 56, color: iconColor),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: _T.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(subtitle, style: _T.subtitle, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onDismiss();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                    elevation: 0,
                  ),
                  child: const Text('متابعة', style: _T.btnPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceAssistantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Use a StatefulWidget so the looping state machine lives inside the sheet
      builder: (ctx) => const _VoiceAssistantBottomSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// الشاشة النشطة (Active Screen)
// ---------------------------------------------------------------------------
class _ActiveScreen extends StatelessWidget {
  final List<MedicationDose> doses;
  final int currentIndex;
  final int remainingSeconds;
  final String Function(int) formatTime;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onTaken;
  final VoidCallback onMissed;
  final VoidCallback onSnooze;
  final VoidCallback onVoiceTap;

  const _ActiveScreen({
    required this.doses,
    required this.currentIndex,
    required this.remainingSeconds,
    required this.formatTime,
    required this.onIndexChanged,
    required this.onTaken,
    required this.onMissed,
    required this.onSnooze,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final dose = doses[currentIndex];

    return Column(
      children: [
        // ---- Header ----
        Container(
          width: double.infinity,
          color: _C.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Text('خذ دواءك الآن', style: _T.pageTitle),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: remainingSeconds < 60 ? _C.danger : _C.black,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'متبقي ${formatTime(remainingSeconds)}',
                        style: _T.timer.copyWith(
                          color: remainingSeconds < 60 ? _C.danger : _C.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Microphone Button in Header
              Positioned(
                left: 0, // RTL left = physical left
                child: GestureDetector(
                  onTap: onVoiceTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _C.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _C.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.mic, color: _C.primary, size: 32),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ---- Progress ----
        // RTL: السابق = previous dose (right side), التالي = next dose (left side)
        Container(
          color: _C.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // السابق — previous dose, disabled on first dose
              _DoseNavButton(
                label: 'السابق',
                enabled: currentIndex > 0,
                onTap: () => onIndexChanged(currentIndex - 1),
              ),
              // Center: progress text always perfectly centered
              Expanded(
                child: Text(
                  '${currentIndex + 1} من ${doses.length}',
                  style: _T.body,
                  textAlign: TextAlign.center,
                ),
              ),
              // التالي — next dose, disabled on last dose
              _DoseNavButton(
                label: 'التالي',
                enabled: currentIndex < doses.length - 1,
                onTap: () => onIndexChanged(currentIndex + 1),
              ),
            ],
          ),
        ),

        // ---- Medication Card ----
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    children: [
                      Text(
                        'مرر لأسفل لرؤية المزيد',
                        style: _T.subtitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _C.black.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _AnimatedScrollArrow(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _MedicationCard(dose: dose),
              ],
            ),
          ),
        ),

        // ---- Action Buttons ----
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: _C.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: onTaken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: _C.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text('تم', style: _T.btnPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMissed,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: _C.black, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close, color: _C.black, size: 20),
                          const SizedBox(width: 6),
                          const Text(
                            'لم أتناول الدواء',
                            style: _T.btnSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSnooze,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: _C.black, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: _C.black,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text('تأجيل', style: _T.btnSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// بطاقة الدواء
// ---------------------------------------------------------------------------
class _MedicationCard extends StatelessWidget {
  final MedicationDose dose;

  const _MedicationCard({required this.dose});

  Widget _buildDrugImage(String? gtin) {
    if (gtin == null || gtin.trim().isEmpty) {
      return const Icon(Icons.medication, size: 80, color: Colors.grey);
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
        return const Icon(Icons.medication, size: 80, color: Colors.grey);
      }

      return Image.asset(
        paths[index],
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback(index + 1),
      );
    }

    return fallback(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              width: double.infinity,
              height: 180,
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: _buildDrugImage(dose.gtin),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name + Audio Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _C.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: _C.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dose.displayTitle, style: _T.cardTitle),
                          const SizedBox(height: 4),
                          Text(dose.displaySubtitle, style: _T.subtitle),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 20),

                // Details
                // Details
                _DetailRow(
                  icon: Icons.medication_liquid_rounded,
                  text: '${dose.quantity}  •  ${dose.route}',
                ),
                if (dose.usageInstruction.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.assignment_rounded,
                    text: dose.usageInstruction,
                  ),
                ],
                if (dose.foodInstruction.trim().isNotEmpty &&
                    dose.foodInstruction.trim() !=
                        dose.usageInstruction.trim()) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.restaurant_rounded,
                    text: dose.foodInstruction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _C.black, size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: _T.body.copyWith(fontSize: 18),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// شاشة الملخص النهائي
// ---------------------------------------------------------------------------
class _SummaryScreen extends StatelessWidget {
  final List<MedicationDose> doses;
  final bool isTimerExpired;
  final VoidCallback onGoHome;

  const _SummaryScreen({
    required this.doses,
    required this.isTimerExpired,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    final missed = doses
        .where(
          (d) =>
              d.status == DoseStatus.missed ||
              d.status == DoseStatus.noResponse,
        )
        .length;
    final snoozed = doses.where((d) => d.status == DoseStatus.snoozed).length;

    final IconData icon;
    final Color iconBgColor;
    final Color iconColor;
    final String title;
    final String subtitle;
    final List<_SummaryStatusCard> statusCards = [];

    if (isTimerExpired) {
      icon = Icons.hourglass_disabled_rounded;
      iconBgColor = _C.warningBg;
      iconColor = _C.warning;
      title = 'انتهى وقت الجرعة';
      subtitle = 'تم تسجيل الجرعة كجرعة فائتة\nتم إشعار مقدم الرعاية';
      statusCards.add(
        _SummaryStatusCard(
          icon: Icons.notifications_active_rounded,
          iconBgColor: _C.successBg,
          iconColor: _C.primary,
          line1: 'تم الإشعار',
          line2: 'مقدم الرعاية على اطلاع',
        ),
      );
    } else if (taken == doses.length) {
      icon = Icons.check_circle_rounded;
      iconBgColor = _C.successBg;
      iconColor = _C.primary;
      title = 'أحسنت!';
      subtitle = 'تم تسجيل جميع جرعاتك لليوم بنجاح\nاستمر في الاهتمام بصحتك';
      statusCards.add(
        _SummaryStatusCard(
          icon: Icons.task_alt_rounded,
          iconBgColor: _C.successBg,
          iconColor: _C.primary,
          line1: 'تم الإنجاز',
          line2: 'أكملت جرعات اليوم بنجاح',
        ),
      );
    } else {
      icon = Icons.medical_services_rounded;
      iconBgColor = _C.successBg;
      iconColor = _C.primary;
      title = 'كل خطوة لصحتك لها قيمة';
      subtitle = 'تم تحديث حالة الجرعة وإشعار مقدم الرعاية';

      if (taken > 0) {
        statusCards.add(
          _SummaryStatusCard(
            icon: Icons.task_alt_rounded,
            iconBgColor: _C.successBg,
            iconColor: _C.primary,
            line1: 'تم أخذ $taken جرعة',
            line2: 'تم تسجيل الحالة',
          ),
        );
      }
      if (snoozed > 0) {
        statusCards.add(
          _SummaryStatusCard(
            icon: Icons.access_time_filled_rounded,
            iconBgColor: _C.snoozeBg,
            iconColor: _C.warning,
            line1: 'تم التأجيل',
            line2: 'التذكير مضبوط',
          ),
        );
      }
      if (missed > 0) {
        statusCards.add(
          _SummaryStatusCard(
            icon: Icons.notifications_active_rounded,
            iconBgColor: _C.successBg,
            iconColor: _C.primary,
            line1: 'تم الإشعار',
            line2: 'مقدم الرعاية على اطلاع',
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text('تم التحديث', style: _T.pageTitle),
          const SizedBox(height: 48),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: iconColor),
          ),
          const SizedBox(height: 28),
          Text(title, style: _T.sectionTitle, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: _T.subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ...statusCards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onGoHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 0),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_rounded, color: _C.white),
                const SizedBox(width: 8),
                const Text('العودة للرئيسية', style: _T.btnPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String line1;
  final String line2;

  const _SummaryStatusCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: iconBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line1, style: _T.body),
                const SizedBox(height: 4),
                Text(line2, style: _T.subtitle),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// مكوّنات مساعدة
// ---------------------------------------------------------------------------
/// Text-only labeled navigation button for the dose progress row.
/// Large touch target, elderly-friendly, greyed out when disabled.
class _DoseNavButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _DoseNavButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = enabled ? _C.black : Colors.grey[400]!;
    final Color borderColor = enabled ? _C.black : Colors.grey[300]!;
    final Color bgColor = enabled ? _C.white : Colors.grey[100]!;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: _T.font,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _SnoozeOptionButton extends StatelessWidget {
  final int minutes;
  final VoidCallback onTap;

  const _SnoozeOptionButton({required this.minutes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: _C.black, width: 1.5),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: Text('$minutes دقيقة', style: _T.btnSecondary),
    );
  }
}

// ---------------------------------------------------------------------------
// حالات المساعد الصوتي
// ---------------------------------------------------------------------------
enum _VoiceState { listening, processing, responding }

// ---------------------------------------------------------------------------
// Bottom Sheet المساعد الصوتي الكامل
// دورة تلقائية: listening(4s) → processing(2s) → responding(2s) → listening ...
// ---------------------------------------------------------------------------
class _VoiceAssistantBottomSheet extends StatefulWidget {
  const _VoiceAssistantBottomSheet();

  @override
  State<_VoiceAssistantBottomSheet> createState() =>
      _VoiceAssistantBottomSheetState();
}

class _VoiceAssistantBottomSheetState extends State<_VoiceAssistantBottomSheet>
    with TickerProviderStateMixin {
  // Current voice state
  _VoiceState _voiceState = _VoiceState.listening;

  // Timer that drives the automatic state cycle
  Timer? _cycleTimer;

  // Pulse animation (listening & responding)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Waveform animation (processing)
  late AnimationController _waveController;

  // Durations for each state
  static const _listeningDuration = Duration(seconds: 4);
  static const _processingDuration = Duration(seconds: 2);
  static const _respondingDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _enterState(_VoiceState.listening);
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _enterState(_VoiceState state) {
    _cycleTimer?.cancel();
    setState(() => _voiceState = state);

    // Manage animations
    _pulseController.stop();
    _waveController.stop();
    switch (state) {
      case _VoiceState.listening:
        _pulseController.repeat(reverse: true);
        _cycleTimer = Timer(
            _listeningDuration, () => _enterState(_VoiceState.processing));
        break;
      case _VoiceState.processing:
        _waveController.repeat();
        _cycleTimer = Timer(
            _processingDuration, () => _enterState(_VoiceState.responding));
        break;
      case _VoiceState.responding:
        _pulseController.repeat(reverse: true);
        _cycleTimer = Timer(
            _respondingDuration, () => _enterState(_VoiceState.listening));
        break;
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ---- State labels ----
  String get _stateTitle {
    switch (_voiceState) {
      case _VoiceState.listening:
        return 'يستمع الآن';
      case _VoiceState.processing:
        return 'جارِ معالجة طلبك';
      case _VoiceState.responding:
        return 'جاري الرد';
    }
  }

  String get _stateSubtitle {
    switch (_voiceState) {
      case _VoiceState.listening:
        return 'تحدث الآن أو اطرح سؤالك';
      case _VoiceState.processing:
        return 'يرجى الانتظار قليلاً';
      case _VoiceState.responding:
        return 'يتم الآن تشغيل الرد الصوتي';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title row with large X close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 56), // balance spacer
                    Text('المساعد الصوتي', style: _T.sectionTitle),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.grey[300]!, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 28,
                          color: _C.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Animated icon area
                _buildIconArea(),
                const SizedBox(height: 20),

                // State title & subtitle with animated transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Column(
                    key: ValueKey(_voiceState),
                    children: [
                      Text(
                        _stateTitle,
                        style: TextStyle(
                          fontFamily: _T.font,
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: _C.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stateSubtitle,
                        style: TextStyle(
                          fontFamily: _T.font,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: _C.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Non-interactive suggestion phrases
                // TODO(api): Replace with STT → NLU → Intent detection
                // Supported intents:
                //   • MarkDoseTaken   → Taken flow
                //   • MarkDoseMissed  → Missed flow
                //   • SnoozeMedication → Snooze flow (allowed: 15, 20, 30 min)
                //   • Repeat          → repeat last prompt
                //   • Confirm         → confirm current pending action
                // If snooze duration is unsupported, respond with:
                //   "مدة التأجيل المتاحة هي 15 أو 20 أو 30 دقيقة"
                _buildSuggestions(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconArea() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _voiceState != _VoiceState.processing
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.primary.withOpacity(
                    _voiceState == _VoiceState.responding ? 0.10 : 0.20,
                  ),
                ),
              ),
            ),
          ),
          // Middle ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _voiceState != _VoiceState.processing
                  ? _pulseAnimation.value * 0.9
                  : 1.0,
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.primary.withOpacity(0.15),
                ),
              ),
            ),
          ),
          // Main circle
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _C.primary, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(child: _buildStateIcon()),
          ),
        ],
      ),
    );
  }

  Widget _buildStateIcon() {
    switch (_voiceState) {
      case _VoiceState.listening:
        return const Icon(Icons.mic_rounded, size: 56, color: _C.primary);
      case _VoiceState.processing:
        return _VoiceWaveform(controller: _waveController);
      case _VoiceState.responding:
        return const Icon(Icons.volume_up_rounded, size: 56, color: _C.primary);
    }
  }

  Widget _buildSuggestions() {
    // These are display-only hint phrases — NOT interactive buttons.
    // TODO(api): These will be replaced by real STT transcription results.
    const phrases = [
      'أخذت الجرعة',
      'ما أخذت الدواء',
      'أجل التذكير',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مثال على ما يمكن قوله:',
          style: TextStyle(
            fontFamily: _T.font,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: _C.grey,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: phrases.map((phrase) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: _C.primary.withOpacity(0.25), width: 1.5),
              ),
              child: Text(
                phrase,
                style: TextStyle(
                  fontFamily: _T.font,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _C.primary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// مكوّن: موجة صوتية متحركة (حالة المعالجة)
// ---------------------------------------------------------------------------
class _VoiceWaveform extends StatelessWidget {
  final AnimationController controller;
  const _VoiceWaveform({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(7, (index) {
            final phase = controller.value * 2 * math.pi;
            final offset = index * (math.pi / 3.5);
            final rawHeight = math.sin(phase + offset);
            final barHeight = 10.0 + (rawHeight * 0.5 + 0.5) * 36.0;
            final opacity = 0.55 + (index / 7) * 0.45;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 6,
              height: barHeight,
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(opacity),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AnimatedScrollArrow extends StatefulWidget {
  const _AnimatedScrollArrow();

  @override
  State<_AnimatedScrollArrow> createState() => _AnimatedScrollArrowState();
}

class _AnimatedScrollArrowState extends State<_AnimatedScrollArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: _C.primary,
            size: 32,
          ),
        );
      },
    );
  }
}
