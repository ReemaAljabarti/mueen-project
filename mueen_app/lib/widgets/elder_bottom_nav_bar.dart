// lib/widgets/elder_bottom_nav_bar.dart
//
// شريط التنقل السفلي الموحّد لجميع شاشات كبير السن.
//
// الاستخدام:
//   bottomNavigationBar: ElderBottomNavBar(
//     currentIndex: 0,   // 0=الرئيسية، 1=الأدوية، 2=الإعدادات
//     elder: _elder,     // كائن Elder الحالي (يُمرَّر في كل انتقال)
//   ),
//
// منطق التنقل (مُصلَح):
//   - كل زر يستخدم pushNamedAndRemoveUntil لضمان الوصول للشاشة الصحيحة
//     بغض النظر عن تاريخ الـ navigation stack.
//   - هذا يمنع مشكلة: Home → Settings → Weekly → pop → يرجع للـ Settings
//   - النقر على الزر النشط حالياً لا يفعل شيئاً (تجنب إعادة بناء الشاشة)
//
// سيناريوهات مضمونة:
//   Home → Settings → Weekly → اضغط Home  → يذهب لـ ElderHomeScreen ✅
//   Home → Weekly  → Settings → اضغط Meds → يذهب لـ WeeklyPillBoxScreen ✅
//   Home → Settings → اضغط Home            → يذهب لـ ElderHomeScreen ✅

import 'package:flutter/material.dart';
import '../models/elder.dart';
import '../theme/app_theme.dart';

class ElderBottomNavBar extends StatelessWidget {
  /// الفهرس النشط: 0=الرئيسية، 1=الأدوية، 2=الإعدادات
  final int currentIndex;

  /// كائن Elder الحالي — يُمرَّر كـ argument في كل انتقال
  final Elder? elder;

  const ElderBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.elder,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // Keep the bottom navigation order the same on all elder screens.
      textDirection: TextDirection.ltr,
      child: Container(
        height: 92,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E7EB), width: 2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 17,
          unselectedFontSize: 16,
          iconSize: 32,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => _onItemTapped(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home),
              ),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.medication_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.medication),
              ),
              label: 'الأدوية',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.settings_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.settings),
              ),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }

//====================================
  void _onItemTapped(BuildContext context, int index) {
    // النقر على الزر النشط لا يفعل شيئاً — تجنب إعادة بناء الشاشة
    if (index == currentIndex) return;

    // تحديد المسار المستهدف
    final String targetRoute;
    switch (index) {
      case 0:
        targetRoute = '/elder-home';
        break;
      case 1:
        targetRoute = '/weekly-pill-box';
        break;
      case 2:
        targetRoute = '/elder-settings';
        break;
      default:
        return;
    }

    debugPrint(
        '[ElderBottomNav] Navigating to $targetRoute (elder.id=${elder?.id})');

    // pushNamedAndRemoveUntil: يمسح الـ stack ويذهب للشاشة المستهدفة مباشرةً
    // هذا يضمن السلوك الصحيح بغض النظر عن تاريخ التنقل
    Navigator.pushNamedAndRemoveUntil(
      context,
      targetRoute,
      // نحتفظ فقط بالشاشات التي تسبق شاشات كبير السن (مثل login/role-selection)
      // أي شاشة اسمها يبدأ بـ /elder- أو /weekly- تُحذف من الـ stack
      (route) =>
          route.settings.name != null &&
          !route.settings.name!.startsWith('/elder') &&
          !route.settings.name!.startsWith('/weekly'),
      arguments: elder,
    );
  }
}
