import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/elder.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  List<Elder> elders = [];
  bool isLoading = true;
  String? errorMessage;

  int totalMissedToday = 0;
  List<Map<String, dynamic>> missedDoses = [];
  Map<int, int> missedCountByElderId = {};

  @override
  void initState() {
    super.initState();
    loadElders();
  }

  Future<void> loadElders() async {
    try {
      if (currentCaregiver == null || currentCaregiver!['id'] == null) {
        setState(() {
          errorMessage = 'لا يوجد مقدم رعاية مسجل حاليًا';
          isLoading = false;
        });
        return;
      }

      final caregiverId = currentCaregiver!['id'];

      // 1) جلب كبار السن
      final data = await ApiService.getElders(
        caregiverId: caregiverId,
      );

      // 2) جلب جرعات اليوم الفائتة لمقدم الرعاية
      final missedData = await ApiService.getMissedDoses(
        caregiverId: caregiverId,
      );

      final missedList = (missedData['missed_doses'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // 3) حساب عدد الجرعات الفائتة لكل كبير سن
      final Map<int, int> counts = {};

      for (final item in missedList) {
        final elderId = item['elder_id'];

        if (elderId is int) {
          counts[elderId] = (counts[elderId] ?? 0) + 1;
        }
      }

      setState(() {
        elders = data;
        missedDoses = missedList;
        totalMissedToday =
            missedData['total_missed_today'] as int? ?? missedList.length;
        missedCountByElderId = counts;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'تعذر تحميل كبار السن';
        isLoading = false;
      });
    }
  }

  String _getGreetingText() {
    final hour = DateTime.now().hour;

    final caregiverName =
        currentCaregiver?['full_name']?.toString().trim() ?? '';

    String greeting;

    if (hour < 12) {
      greeting = 'صباح الخير';
    } else {
      greeting = 'مساء الخير';
    }

    if (caregiverName.isEmpty) {
      return greeting;
    }

    return '$greeting $caregiverName';
  }

  void _showMissedDosesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: missedDoses.isEmpty
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 12),
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 40,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد جرعات فائتة اليوم',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'الجرعات الفائتة اليوم',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...missedDoses.map((dose) {
                        final elderName =
                            dose['elder_name']?.toString() ?? 'كبير السن';
                        final medName =
                            dose['medication_name']?.toString() ?? 'دواء';
                        final scheduledTime =
                            dose['scheduled_time']?.toString() ?? '';
                        final status = dose['status']?.toString() ?? '';

                        final statusText =
                            status == 'no_response' ? 'لم يستجب' : 'فائتة';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.warningText.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warningText,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      elderName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      medName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الوقت: $scheduledTime • $statusText',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SizedBox(
          height: 70,
          child: Image.asset(
            'assets/fonts/images/mueenicon.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/add-elder-basic');
                await loadElders();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'إضافة كبير/ة',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _getGreetingText(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'نتابع معك حالة كبار السن اليوم',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // بطاقة التنبيه العلوية
            // بطاقة التنبيه العلوية
            GestureDetector(
              onTap: _showMissedDosesSheet,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      totalMissedToday > 0 ? AppColors.warning : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: totalMissedToday > 0
                        ? AppColors.warningText.withOpacity(0.2)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chevron_left,
                      color: totalMissedToday > 0
                          ? AppColors.warningText
                          : Colors.grey,
                    ),
                    const Spacer(),
                    Text(
                      totalMissedToday > 0
                          ? 'الجرعات الفائتة اليوم: $totalMissedToday'
                          : 'لا توجد جرعات فائتة اليوم',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: totalMissedToday > 0
                            ? AppColors.warningText
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'كبار السن',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              )
            else if (elders.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  'لا يوجد كبار سن مضافون حتى الآن',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
            else
              Column(
                children: elders
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildElderCard(
                          context,
                          entry.value,
                          hasMissedDose:
                              (missedCountByElderId[entry.value.id] ?? 0) > 0,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/caregiver-settings');
          }
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget _buildElderCard(
    BuildContext context,
    Elder elder, {
    bool hasMissedDose = false,
  }) {
    final String displayName =
        elder.fullName.trim().isNotEmpty ? elder.fullName : 'بدون اسم';

    final String timeText = (elder.age != null && elder.age!.trim().isNotEmpty)
        ? '${elder.age} سنة'
        : 'العمر غير محدد';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // النصوص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/elder-profile',
                          arguments: elder,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'اضغط على الاسم لعرض الملف',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    if (hasMissedDose) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warningText.withOpacity(0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'جرعة فائتة',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: AppColors.warningText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // الأيقونة
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الأزرار السفلية
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/weekly-report',
                      arguments: elder,
                    );
                  },
                  icon: const Icon(Icons.show_chart_outlined, size: 18),
                  label: const Text('عرض التقرير'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/caregiver-medications',
                      arguments: elder,
                    );
                  },
                  icon: const Icon(Icons.medication_outlined, size: 18),
                  label: const Text('عرض الأدوية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
