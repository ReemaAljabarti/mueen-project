// lib/services/dose_alert_service.dart
//
// خدمة التحقق الدوري من الجرعات المستحقة.
//
// المسؤوليات:
//  • تشغيل Timer كل 30 ثانية (للعرض التجريبي)
//  • استدعاء GET /reminders/due-now/{elder_id}
//  • فتح شاشة Dose Alert تلقائياً فوق أي شاشة حالية
//  • منع فتح الشاشة أكثر من مرة في نفس الوقت (isDoseAlertOpen)
//
// الاستخدام:
//  // في main.dart (مرة واحدة عند بدء التطبيق):
//  DoseAlertService.registerNavigatorKey(navigatorKey);
//
//  // عند تسجيل دخول كبير السن:
//  DoseAlertService.start(navigatorKey);
//
//  // عند تسجيل الخروج:
//  DoseAlertService.stop();

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/current_elder.dart';

class DoseAlertService {
  // ─── الثوابت ──────────────────────────────────────────────────────────────
  static const Duration _pollInterval = Duration(seconds: 30);

  // ─── الحالة الداخلية ──────────────────────────────────────────────────────
  static Timer? _timer;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// true إذا كانت شاشة Dose Alert مفتوحة حالياً — يمنع التكرار.
  static bool isDoseAlertOpen = false;

  // ─── واجهة عامة ───────────────────────────────────────────────────────────

  /// يُسجّل navigatorKey العالمي من main.dart.
  /// يجب استدعاؤه مرة واحدة في main() قبل runApp.
  static void registerNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// يبدأ التحقق الدوري باستخدام navigatorKey المُسجَّل مسبقاً.
  /// يجب استدعاؤه بعد تسجيل دخول كبير السن ناجح.
  static void start(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _startPolling();
  }

  /// بديل لـ start() عند عدم توفر navigatorKey مباشرةً.
  /// يستخدم navigatorKey المُسجَّل مسبقاً من main.dart.
  static void startWithContext(BuildContext context) {
    // navigatorKey مُسجَّل من main.dart — لا حاجة لـ context
    _startPolling();
  }

  /// يوقف التحقق الدوري.
  /// يجب استدعاؤه عند تسجيل الخروج.
  static void stop() {
    _timer?.cancel();
    _timer = null;
    isDoseAlertOpen = false;
    debugPrint('[DoseAlertService] Stopped');
  }

  // ─── منطق داخلي ──────────────────────────────────────────────────────────

  static void _startPolling() {
    _timer?.cancel();

    // تحقق فوري عند البدء
    _checkNow();

    // ثم كل 30 ثانية
    _timer = Timer.periodic(_pollInterval, (_) => _checkNow());
    debugPrint(
        '[DoseAlertService] Started — polling every ${_pollInterval.inSeconds}s');
  }

  static Future<void> _checkNow() async {
    // لا تتحقق إذا لم يكن هناك كبير سن مسجّل
    final elder = currentElder;
    if (elder == null || elder.id == null) {
      debugPrint('[DoseAlertService] No logged-in elder — skipping check');
      return;
    }

    // لا تفتح شاشة جديدة إذا كانت مفتوحة بالفعل
    if (isDoseAlertOpen) {
      debugPrint('[DoseAlertService] Alert screen already open — skipping');
      return;
    }

    try {
      debugPrint(
        '[DoseAlertService] checking due doses for elderId=${elder.id}',
      );

      final res = await ApiService.getDueDoses(elderId: elder.id!);

      debugPrint('[DoseAlertService] response = $res');

      final count = res['count'] as int? ?? 0;
      final doses = res['due_doses'] as List<dynamic>? ?? [];

      debugPrint('[DoseAlertService] Due doses for elder ${elder.id}: $count');

      if (count > 0) {
        _openAlertScreen(elder, doses);
      }
    } catch (e) {
      // خطأ في الشبكة — غير قاطع، سيُعاد المحاولة في الدورة القادمة
      debugPrint('[DoseAlertService] API error (non-fatal): $e');
    }
  }

  static void _openAlertScreen(dynamic elder, List<dynamic> doses) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('[DoseAlertService] Navigator not ready');
      return;
    }

    isDoseAlertOpen = true;
    debugPrint('[DoseAlertService] Opening Dose Alert screen');

    navigator.pushNamed(
      '/dose-alert',
      arguments: {
        'elder': elder,
        'doses': doses,
      },
    ).then((_) {
      // عند إغلاق الشاشة، نسمح بفتحها مرة أخرى في الدورة القادمة
      isDoseAlertOpen = false;
      debugPrint('[DoseAlertService] Alert screen closed — flag reset');
    });
  }
}
