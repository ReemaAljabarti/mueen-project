import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/elder.dart';
import '../services/current_elder.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  Future<Map<String, dynamic>>? _reportFuture;
  int? _elderId;
  String _elderName = 'كبير السن';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Elder) {
      _elderId = args.id;
      _elderName = args.fullName;
    } else if (args is Map) {
      _elderId = args['elderId'] as int?;
      _elderName = args['elderName']?.toString() ?? 'كبير السن';
    } else {
      _elderId = currentElder?.id;
      _elderName = currentElder?.fullName ?? 'كبير السن';
    }

    if (_elderId != null) {
      _reportFuture = ApiService.getWeeklyReport(elderId: _elderId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'التقرير الأسبوعي',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          actions: [
            IconButton(
              icon: const Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: _elderId == null
            ? const Center(
                child: Text(
                  'لا يوجد كبير سن محدد لعرض التقرير',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              )
            : FutureBuilder<Map<String, dynamic>>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'تعذر تحميل التقرير الأسبوعي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }

                  final report = snapshot.data ?? {};
                  final totalDoses = _asInt(report['total_doses']);

                  if (totalDoses == 0) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildElderInfoCard(_elderName),
                          const SizedBox(height: 24),
                          _buildEmptyReportCard(),
                          const SizedBox(height: 24),
                          _buildWeeklyOverview(report),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildElderInfoCard(_elderName),
                        const SizedBox(height: 24),
                        _buildAdherenceCard(report),
                        const SizedBox(height: 24),
                        _buildWeeklyOverview(report),
                        const SizedBox(height: 24),
                        _buildMostMissedSection(report),
                        const SizedBox(height: 24),
                        _buildMissedDosesSection(report),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildElderInfoCard(String elderName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تقرير عن',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            elderName,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReportCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'لا يوجد تقرير لهذا الأسبوع',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'سيظهر التقرير بعد تسجيل الجرعات خلال الأسبوع.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard(Map<String, dynamic> report) {
    final adherence = _formatPercentage(report['adherence_percentage']);
    final taken = _asInt(report['taken']).toString();
    final missed =
        (_asInt(report['missed']) + _asInt(report['no_response'])).toString();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'الالتزام هذا الأسبوع',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    '$adherence%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF119099)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'جرعة مأخوذة',
                  taken,
                  const Color(0xFFD4F5F9),
                  const Color(0xFF003948),
                  Icons.check,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatBox(
                  'جرعة مفوتة',
                  missed,
                  const Color(0xFFF6E6C8),
                  const Color(0xFF663C00),
                  Icons.close,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    Color bg,
    Color textCol,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: textCol, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: textCol,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: textCol.withOpacity(0.7),
              fontSize: 13,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(Map<String, dynamic> report) {
    final dailyOverview = (report['daily_overview'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final weekDays = _buildSundayToSaturdayWeek(dailyOverview);
    final overviewByDate = <String, Map<String, dynamic>>{};

    for (final day in dailyOverview) {
      final date = (day['date'] ?? '').toString();
      if (date.isNotEmpty) {
        overviewByDate[date] = day;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'نظرة عامة على الأسبوع',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            children: [
              _buildWeekTitle(weekDays),
              const SizedBox(height: 18),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDays.map((date) {
                    final dateKey = _dateKey(date);
                    final dayData = overviewByDate[dateKey];

                    return _buildDayIndicator(
                      day: _arabicDayShort(date),
                      date: date.day.toString().padLeft(2, '0'),
                      state: _getDayState(dayData),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              _buildWeeklyHint(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekTitle(List<DateTime> weekDays) {
    final start = weekDays.first;
    final end = weekDays.last;

    final sameMonth = start.month == end.month && start.year == end.year;

    final monthTitle = sameMonth
        ? '${_arabicMonthName(start.month)} ${start.year}'
        : '${_arabicMonthName(start.month)} - ${_arabicMonthName(end.month)} ${end.year}';

    final rangeTitle = sameMonth
        ? '${start.day} - ${end.day} ${_arabicMonthName(end.month)} ${end.year}'
        : '${start.day} ${_arabicMonthName(start.month)} - ${end.day} ${_arabicMonthName(end.month)} ${end.year}';

    return Column(
      children: [
        Text(
          monthTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'الأسبوع: $rangeTitle',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicator({
    required String day,
    required String date,
    required _DayState state,
  }) {
    final icon = switch (state) {
      _DayState.allTaken => Icons.check,
      _DayState.hasMissed => Icons.close,
      _DayState.noDoses => Icons.remove,
    };

    final bgColor = switch (state) {
      _DayState.allTaken => AppColors.primary,
      _DayState.hasMissed => const Color(0xFFF2D6D3),
      _DayState.noDoses => const Color(0xFFE5E7EB),
    };

    final iconColor = switch (state) {
      _DayState.allTaken => Colors.white,
      _DayState.hasMissed => const Color(0xFF7A1F1F),
      _DayState.noDoses => const Color(0xFF6B7280),
    };

    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyHint() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: const [
        _HintItem(
          label: 'كل الجرعات',
          color: AppColors.primary,
          icon: Icons.check,
          iconColor: Colors.white,
        ),
        _HintItem(
          label: 'مفوتة',
          color: Color(0xFFF2D6D3),
          icon: Icons.close,
          iconColor: Color(0xFF7A1F1F),
        ),
        _HintItem(
          label: 'لا يوجد',
          color: Color(0xFFE5E7EB),
          icon: Icons.remove,
          iconColor: Color(0xFF6B7280),
        ),
      ],
    );
  }

  Widget _buildMostMissedSection(Map<String, dynamic> report) {
    final mostMissed =
        (report['most_missed_medications'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'الأدوية الأكثر تفويتًا',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        if (mostMissed.isEmpty)
          _buildInfoBox('لا توجد أدوية مفوتة هذا الأسبوع')
        else
          ...mostMissed.map((med) {
            final name = (med['brand_name_ar'] ?? 'دواء').toString();
            final category = (med['med_category'] ?? '').toString();
            final count = _asInt(med['miss_count']).toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMissedMedCard(
                name,
                category.isNotEmpty ? category : 'دواء',
                '$count مرات',
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMissedMedCard(String name, String dose, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dose,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF2D6D3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: const TextStyle(
                color: Color(0xFF7A1F1F),
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedDosesSection(Map<String, dynamic> report) {
    final missedDoses = (report['missed_doses'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'الجرعات الفائتة هذا الأسبوع',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        if (missedDoses.isEmpty)
          _buildInfoBox('لا توجد جرعات فائتة هذا الأسبوع')
        else
          ...missedDoses.map((dose) {
            final name = (dose['brand_name_ar'] ?? 'دواء').toString();
            final date = (dose['dose_date'] ?? '').toString();
            final time = (dose['scheduled_time'] ?? '').toString();
            final status = (dose['status'] ?? '').toString();

            final label = status == 'no_response' ? 'لم يستجب' : 'فائتة';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMissedEntryCard(
                name,
                '$date • $time',
                label,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMissedEntryCard(String name, String time, String period) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              period,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  List<DateTime> _buildSundayToSaturdayWeek(
    List<Map<String, dynamic>> dailyOverview,
  ) {
    final parsedDates = dailyOverview
        .map((item) => _parseDate(item['date']?.toString()))
        .whereType<DateTime>()
        .toList();

    final referenceDate =
        parsedDates.isNotEmpty ? parsedDates.first : DateTime.now();

    final daysFromSunday = referenceDate.weekday % 7;
    final sunday = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    ).subtract(Duration(days: daysFromSunday));

    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  _DayState _getDayState(Map<String, dynamic>? dayData) {
    if (dayData == null) return _DayState.noDoses;

    final taken = _asInt(dayData['taken']);
    final missed = _asInt(dayData['missed']);
    final noResponse = _asInt(dayData['no_response']);
    final total = taken + missed + noResponse;

    if (total == 0) return _DayState.noDoses;
    if (taken > 0 && missed == 0 && noResponse == 0) {
      return _DayState.allTaken;
    }

    return _DayState.hasMissed;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _arabicDayShort(DateTime date) {
    switch (date.weekday) {
      case DateTime.sunday:
        return 'ح';
      case DateTime.monday:
        return 'ن';
      case DateTime.tuesday:
        return 'ث';
      case DateTime.wednesday:
        return 'ع';
      case DateTime.thursday:
        return 'خ';
      case DateTime.friday:
        return 'ج';
      case DateTime.saturday:
      default:
        return 'س';
    }
  }

  String _arabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  String _formatPercentage(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '0') ?? 0;

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(1);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

enum _DayState {
  allTaken,
  hasMissed,
  noDoses,
}

class _HintItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _HintItem({
    required this.label,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
