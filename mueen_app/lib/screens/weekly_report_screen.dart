import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

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
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Elder Info
            _buildElderInfoCard(),
            const SizedBox(height: 24),
            // Adherence Summary
            _buildAdherenceCard(),
            const SizedBox(height: 24),
            // Weekly Overview
            _buildWeeklyOverview(),
            const SizedBox(height: 24),
            // Most Missed Medications
            _buildMostMissedSection(),
            const SizedBox(height: 24),
            // Missed Doses List
            _buildMissedDosesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildElderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('تقرير عن', style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal')),
          Text('أحمد عبدالله', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard() {
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
                child: const Icon(Icons.trending_up, color: Colors.white, size: 32),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('الالتزام هذا الأسبوع', style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal')),
                  Text('87%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatBox('جرعة مفوتة', '4', const Color(0xFFF6E6C8), const Color(0xFF663C00), Icons.close)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBox('جرعة مأخوذة', '26', const Color(0xFFD4F5F9), const Color(0xFF003948), Icons.check)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color bg, Color textCol, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: textCol, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: textCol, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          Text(label, style: TextStyle(color: textCol.withOpacity(0.7), fontSize: 12, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('نظرة عامة على الأسبوع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayIndicator('ج', '23', false),
              _buildDayIndicator('خ', '22', true),
              _buildDayIndicator('ع', '21', true),
              _buildDayIndicator('ث', '20', false),
              _buildDayIndicator('ن', '19', true),
              _buildDayIndicator('ح', '18', true),
              _buildDayIndicator('س', '17', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicator(String day, String date, bool isSuccess) {
    return Column(
      children: [
        Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 4),
        Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 8),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSuccess ? AppColors.primary : const Color(0xFFF2D6D3),
            shape: BoxShape.circle,
          ),
          child: Icon(isSuccess ? Icons.check : Icons.close, color: isSuccess ? Colors.black : const Color(0xFF7A1F1F), size: 12),
        ),
      ],
    );
  }

  Widget _buildMostMissedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('الأدوية الأكثر تفويتًا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 16),
        _buildMissedMedCard('دواء السكر', '١ قرص', '٣ مرات'),
      ],
    );
  }

  Widget _buildMissedMedCard(String name, String dose, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF2D6D3), borderRadius: BorderRadius.circular(12)),
            child: Text(count, style: const TextStyle(color: Color(0xFF7A1F1F), fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              Text(dose, style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissedDosesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('الجرعات الفائتة هذا الأسبوع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        const SizedBox(height: 16),
        _buildMissedEntryCard('بنادول إكسترا', 'الأحد • ٩:٠٠ ص', 'صباحًا'),
      ],
    );
  }

  Widget _buildMissedEntryCard(String name, String time, String period) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Text(period, style: const TextStyle(fontSize: 12, fontFamily: 'Tajawal')),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Tajawal')),
            ],
          ),
        ],
      ),
    );
  }
}
