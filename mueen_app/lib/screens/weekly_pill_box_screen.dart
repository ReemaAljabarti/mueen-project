// lib/screens/weekly_pill_box_screen.dart
//
// التغييرات في هذه النسخة:
//   - تحويل من StatelessWidget إلى StatefulWidget لقراءة Elder من route arguments
//   - استبدال _buildBottomNav + _NavItem المخصص بـ ElderBottomNavBar الموحّد
//   - تمرير elder المقروء من ModalRoute للـ ElderBottomNavBar
//   - currentIndex: 1 (الأدوية نشطة)
//   - لا تغيير في التصميم أو منطق عرض الأيام

import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../theme/app_theme.dart';
import '../widgets/elder_bottom_nav_bar.dart';

class WeeklyPillBoxScreen extends StatefulWidget {
  const WeeklyPillBoxScreen({super.key});

  @override
  State<WeeklyPillBoxScreen> createState() => _WeeklyPillBoxScreenState();
}

class _WeeklyPillBoxScreenState extends State<WeeklyPillBoxScreen> {
  // ── خريطة weekday → اسم عربي ─────────────────────────────────────────────
  // Dart: Monday=1, Tuesday=2, ..., Saturday=6, Sunday=7
  static const Map<int, String> _dayNames = {
    1: 'الاثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };

  // ترتيب العرض: السبت أولاً كما في التصميم
  static const List<int> _displayOrder = [6, 7, 1, 2, 3, 4, 5];

  Elder? _elder;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    // قراءة Elder من route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Elder) {
      _elder = args;
      debugPrint('[WeeklyPillBox] ✅ Elder loaded → id=${_elder!.id}, name=${_elder!.fullName}');
    } else {
      debugPrint('[WeeklyPillBox] ⚠️ No Elder argument received — type: ${args.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // اليوم الحالي من الجهاز — لا يُعدَّل يدوياً
    final int todayWeekday = DateTime.now().weekday;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FBFC),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    children: _displayOrder.map((weekday) {
                      final bool isToday = weekday == todayWeekday;
                      final String dayName = _dayNames[weekday]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DayCard(
                          dayName: dayName,
                          isToday: isToday,
                          onTap: isToday ? () => _onTodayTapped(context) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── شريط التنقل الموحّد ────────────────────────────────────────────
        bottomNavigationBar: ElderBottomNavBar(
          currentIndex: 1, // الأدوية نشطة
          elder: _elder,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'جدول الأدوية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 36,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر اليوم لعرض مواعيد الأدوية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.normal,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _onTodayTapped(BuildContext context) {
    // الانتقال لشاشة جدول اليوم مع تمرير elder
    Navigator.pushNamed(
      context,
      '/elder-today-schedule',
      arguments: _elder,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// بطاقة اليوم الواحد
// ════════════════════════════════════════════════════════════════════════════

class _DayCard extends StatelessWidget {
  final String dayName;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayCard({
    required this.dayName,
    required this.isToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: isToday ? 132 : 88,
        decoration: BoxDecoration(
          color: isToday ? Colors.white : const Color(0xFFD6DADB),
          borderRadius: BorderRadius.circular(16),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isToday
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: isToday ? _buildTodayContent() : _buildNormalContent(),
        ),
      ),
    );
  }

  Widget _buildTodayContent() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 28,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'اليوم',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _CalendarCheckIcon(
          color: AppColors.primary,
          size: 30,
          opacity: 1.0,
        ),
      ],
    );
  }

  Widget _buildNormalContent() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Text(
            dayName,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: Color(0xFF8A9AA0),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const _CalendarCheckIcon(
          color: Color(0xFF8A9AA0),
          size: 24,
          opacity: 0.5,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// أيقونة التقويم المرسومة بـ CustomPainter
// ════════════════════════════════════════════════════════════════════════════

class _CalendarCheckIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _CalendarCheckIcon({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CalendarIconPainter(color: color),
        ),
      ),
    );
  }
}

class _CalendarIconPainter extends CustomPainter {
  final Color color;

  const _CalendarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // جسم التقويم
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.15, w * 0.90, h * 0.80),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(bodyRect, strokePaint);

    // الخط الأفقي الفاصل
    canvas.drawLine(
      Offset(w * 0.05, h * 0.38),
      Offset(w * 0.95, h * 0.38),
      strokePaint,
    );

    // مقابض التقويم
    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.30, h * 0.05),
      Offset(w * 0.30, h * 0.25),
      handlePaint,
    );
    canvas.drawLine(
      Offset(w * 0.70, h * 0.05),
      Offset(w * 0.70, h * 0.25),
      handlePaint,
    );

    // علامة الصح
    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(w * 0.28, h * 0.62)
      ..lineTo(w * 0.45, h * 0.78)
      ..lineTo(w * 0.72, h * 0.52);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(_CalendarIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
