import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
// Role
import 'screens/role_selection_screen.dart';

// Caregiver
import 'screens/caregiver_login_screen.dart';
import 'screens/caregiver_signup_screen.dart';
import 'screens/caregiver_home_screen.dart';
import 'screens/caregiver_settings_screen.dart';

// Elder
import 'screens/elder_login_screen.dart';
import 'screens/elder_home_screen.dart';
import 'screens/elder_settings_screen.dart';

// Add Elder Flow
import 'screens/add_elder_basic_info_screen.dart';
import 'screens/add_elder_health_info_screen.dart';
import 'screens/elder_added_success_screen.dart';

// Profile
import 'screens/elder_profile_screen.dart';

// Medication Management
import 'screens/caregiver_medications_screen.dart';
import 'screens/weekly_report_screen.dart';
import 'screens/edit_medication_screen.dart';
import 'screens/medication_details_screen.dart';

// Add Medication Flow
import 'screens/add_medication/add_medication_selection_screen.dart';
import 'screens/add_medication/add_medication_success_screen.dart';
import 'screens/add_medication/barcode_scanner_screen.dart';
import 'screens/add_medication/medication_details_optional_screen.dart';
import 'screens/add_medication/medication_details_step1_screen.dart';
import 'screens/add_medication/medication_details_step2_screen.dart';
import 'screens/add_medication/reminder_review_screen.dart';
import 'screens/add_medication/scheduling_step1_screen.dart';
import 'screens/add_medication/scheduling_step2_screen.dart';
import 'screens/add_medication/scheduling_step3_screen.dart';

void main() {
  runApp(const MueenApp());
}

class MueenApp extends StatelessWidget {
  const MueenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        // =============================
        // Role
        // =============================
        '/splash': (context) => const SplashScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),

        // =============================
        // Caregiver
        // =============================
        '/caregiver-login': (context) => const CaregiverLoginScreen(),
        '/caregiver-signup': (context) => const CaregiverSignupScreen(),
        '/caregiver-home': (context) => const CaregiverHomeScreen(),
        '/caregiver-settings': (context) => const CaregiverSettingsScreen(),

        // =============================
        // Elder
        // =============================
        '/elder-login': (context) => const ElderLoginScreen(),
        '/elder-home': (context) => const ElderHomeScreen(),
        '/elder-settings': (context) => const ElderSettingsScreen(),

        // =============================
        // Add Elder Flow
        // =============================
        '/add-elder-basic': (context) => const AddElderBasicInfoScreen(),
        '/add-elder-health': (context) => const AddElderHealthInfoScreen(),
        '/elder-added-success': (context) => const ElderAddedSuccessScreen(),

        // =============================
        // Profile
        // =============================
        '/elder-profile': (context) => const ElderProfileScreen(),

        // =============================
        // Medication Management
        // =============================
        '/caregiver-medications': (context) =>
            const CaregiverMedicationsScreen(),
        '/weekly-report': (context) => const WeeklyReportScreen(),
        '/medication-details': (context) => const MedicationDetailsScreen(),

        // =============================
        // Add Medication Flow
        // =============================
      },
    );
  }
}
