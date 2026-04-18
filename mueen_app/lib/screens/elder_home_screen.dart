import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Center(
                child: Text(
                  'صباح الخير',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Next Dose Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('ملخص الجرعة القادمة'),
                    const SizedBox(height: 8),
                    const Text(
                      '2:00 م',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'بعد 3 ساعات',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('لديك 4 أدوية'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Medications Preview
              const Text(
                'الأدوية',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _buildMedItem('دواء ضغط', Icons.medication),
                  _buildMedItem('دواء سكر', Icons.medication),
                  _buildMedItem('دواء كوليسترول', Icons.medication),
                  _buildMedItem('فيتامين', Icons.medication),
                ],
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'مرر للأسفل لعرض جدول اليوم',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 24),

              // Schedule
              const Text(
                'الجدول الزمني لأدوية اليوم',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Column(
                children: [
                  _buildScheduleItem('6:00 ص', true),
                  _buildScheduleItem('9:00 ص', true),
                  _buildScheduleItem('12:00 م', true),
                  _buildScheduleItem('3:00 م', false),
                  _buildScheduleItem('8:00 م', false),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Floating button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.mic),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 2) {
            Navigator.pushNamed(context, '/elder-settings');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'الأدوية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget _buildMedItem(String name, IconData icon) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF3F4F6),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String time, bool isTaken) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(time),
          const Spacer(),
          Icon(
            isTaken ? Icons.check_circle : Icons.access_time,
            color: isTaken ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}
