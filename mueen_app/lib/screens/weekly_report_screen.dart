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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'التقرير الأسبوعي',
          style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'تعذر تحميل التقرير الأسبوعي',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }

                final report = snapshot.data ?? {};
                final totalDoses = report['total_doses'] ?? 0;

                if (totalDoses == 0) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildElderInfoCard(_elderName),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'لا يوجد تقرير لهذا الأسبوع',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
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
    );
  }

  Widget _buildElderInfoCard(String elderName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'تقرير عن',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: 'Tajawal',
            ),
          ),
          Text(
            elderName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard(Map<String, dynamic> report) {
    final adherence = (report['adherence_percentage'] ?? 0).toString();
    final taken = (report['taken'] ?? 0).toString();
    final missed =
        ((report['missed'] ?? 0) + (report['no_response'] ?? 0)).toString();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'الالتزام هذا الأسبوع',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    '$adherence%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'جرعة مفوتة',
                  missed,
                  const Color(0xFFF6E6C8),
                  const Color(0xFF663C00),
                  Icons.close,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatBox(
                  'جرعة مأخوذة',
                  taken,
                  const Color(0xFFD4F5F9),
                  const Color(0xFF003948),
                  Icons.check,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
      String label, String value, Color bg, Color textCol, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: textCol, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: textCol,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal')),
          Text(label,
              style: TextStyle(
                  color: textCol.withOpacity(0.7),
                  fontSize: 12,
                  fontFamily: 'Tajawal')),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(Map<String, dynamic> report) {
    final dailyOverview = (report['daily_overview'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    const dayLabels = ['س', 'ح', 'ن', 'ث', 'ع', 'خ', 'ج'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'نظرة عامة على الأسبوع',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dailyOverview.length, (index) {
              final dayData = dailyOverview[index];
              final date = (dayData['date'] ?? '').toString();
              final dayNumber = date.length >= 10 ? date.substring(8, 10) : '';
              final taken = dayData['taken'] ?? 0;
              final missed = dayData['missed'] ?? 0;
              final noResponse = dayData['no_response'] ?? 0;

              final isSuccess = taken > 0 && missed == 0 && noResponse == 0;
              final label = index < dayLabels.length ? dayLabels[index] : '';

              return _buildDayIndicator(label, dayNumber, isSuccess);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicator(String day, String date, bool isSuccess) {
    return Column(
      children: [
        Text(day,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal')),
        const SizedBox(height: 4),
        Text(date,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal')),
        const SizedBox(height: 8),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSuccess ? AppColors.primary : const Color(0xFFF2D6D3),
            shape: BoxShape.circle,
          ),
          child: Icon(isSuccess ? Icons.check : Icons.close,
              color: isSuccess ? Colors.black : const Color(0xFF7A1F1F),
              size: 12),
        ),
      ],
    );
  }

  Widget _buildMostMissedSection(Map<String, dynamic> report) {
    final mostMissed =
        (report['most_missed_medications'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'الأدوية الأكثر تفويتًا',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        if (mostMissed.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'لا توجد أدوية مفوتة هذا الأسبوع',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Tajawal',
              ),
            ),
          )
        else
          ...mostMissed.map((med) {
            final name = (med['brand_name_ar'] ?? 'دواء').toString();
            final category = (med['med_category'] ?? '').toString();
            final count = (med['miss_count'] ?? 0).toString();

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
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF2D6D3),
                borderRadius: BorderRadius.circular(12)),
            child: Text(count,
                style: const TextStyle(
                    color: Color(0xFF7A1F1F),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal')),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal')),
              Text(dose,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissedDosesSection(Map<String, dynamic> report) {
    final missedDoses = (report['missed_doses'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'الجرعات الفائتة هذا الأسبوع',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        if (missedDoses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'لا توجد جرعات فائتة هذا الأسبوع',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Tajawal',
              ),
            ),
          )
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
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12)),
            child: Text(period,
                style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal')),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal')),
              Text(time,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal')),
            ],
          ),
        ],
      ),
    );
  }
}
