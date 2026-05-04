// lib/screens/elder_settings_screen.dart
//
// التغييرات في هذه النسخة:
//   - قراءة Elder من route arguments في didChangeDependencies
//   - استبدال _buildBottomNav المخصص بـ ElderBottomNavBar الموحّد
//   - تمرير _elder للـ ElderBottomNavBar بشكل صريح
//   - currentIndex: 2 (الإعدادات نشطة)
//   - إزالة pushReplacementNamed (كان يُدمر الـ stack)
//   - تسجيل الخروج يبقى pushNamedAndRemoveUntil (الحالة الوحيدة المسموح بها)

import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../theme/app_theme.dart';
import '../widgets/elder_bottom_nav_bar.dart';

class ElderSettingsScreen extends StatefulWidget {
  const ElderSettingsScreen({super.key});

  @override
  State<ElderSettingsScreen> createState() => _ElderSettingsScreenState();
}

class _ElderSettingsScreenState extends State<ElderSettingsScreen> {
  bool _reminderSound = true;
  bool _readAloud = false;
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
      debugPrint(
          '[ElderSettings] ✅ Elder loaded → id=${_elder!.id}, name=${_elder!.fullName}');
    } else {
      debugPrint(
          '[ElderSettings] ⚠️ No Elder argument received — type: ${args.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // لا سهم رجوع — التنقل عبر الـ nav bar
        title: const Text(
          'الإعدادات',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // قسم التذكيرات
            _buildSectionHeader(
              'التذكيرات',
              const Color(0xFFD4F5F9),
              Icons.notifications_none,
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              'صوت التذكير',
              Icons.volume_up_outlined,
              Switch(
                value: _reminderSound,
                onChanged: (val) => setState(() => _reminderSound = val),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              'قارئ صوتي',
              Icons.record_voice_over_outlined,
              Switch(
                value: _readAloud,
                onChanged: (val) => setState(() => _readAloud = val),
                activeColor: AppColors.primary,
              ),
              subtitle: 'قراءة الإشعار صوتيًا',
            ),
            const SizedBox(height: 32),
            // قسم الحساب والدعم
            _buildSectionHeader(
              'الحساب والدعم',
              const Color(0xFFFFF3D6),
              Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildLogoutCard(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
      // ── شريط التنقل الموحّد ──────────────────────────────────────────────
      bottomNavigationBar: ElderBottomNavBar(
        currentIndex: 2, // الإعدادات نشطة
        elder: _elder,
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color iconBg, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontFamily: 'Tajawal'),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildSettingCard(String title, IconData icon, Widget trailing,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF9FAFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              trailing,
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.black),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 60),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return GestureDetector(
      // تسجيل الخروج: الحالة الوحيدة التي نستخدم فيها pushNamedAndRemoveUntil
      onTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/role-selection',
        (route) => false,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFF9FAFB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.chevron_left, color: Colors.black),
            const Spacer(),
            const Text(
              'تسجيل الخروج',
              style: TextStyle(
                color: Color(0xFFC0392B),
                fontSize: 18,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.logout, color: Color(0xFFC0392B)),
            ),
          ],
        ),
      ),
    );
  }
}
