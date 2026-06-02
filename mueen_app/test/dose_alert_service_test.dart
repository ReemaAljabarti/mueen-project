// Unit Test Description:
// This test file validates two helper methods from DoseAlertService:
// 1. isElderAreaRouteForTest()
// 2. todayDoseKeyForTest()
//
// These methods were selected because they support the
// "Detect Due Dose and Open Dose Alert" functionality.
//
// The first method, isElderAreaRouteForTest(), checks whether the current
// route belongs to the elder area before allowing the full-screen dose alert
// to open. This prevents the alert from appearing in unrelated screens,
// such as caregiver screens.
//
// The second method, todayDoseKeyForTest(), checks the daily dose generation
// key format. The key combines the elder ID with today's date, such as
// "1-2026-05-22". This helps DoseAlertService avoid repeatedly requesting
// dose generation for the same elder on the same day during the current
// app session.
//
// Five test cases are included:
// 1. An elder route should return true.
// 2. A non-elder route should return false.
// 3. A null route should return false.
// 4. The generated dose key should contain the elder ID.
// 5. The generated dose key should follow the format elderId-yyyy-mm-dd.
//
// These tests help ensure that the dose alert screen is only allowed to open
// in elder-related screens, and that the service uses a consistent daily key
// before checking for due doses.

// Import Flutter's testing package.
// This package provides test(), group(), and expect().
import 'package:flutter_test/flutter_test.dart';

// Import the DoseAlertService class from the app.
// We need this because the function being tested belongs to DoseAlertService.
import 'package:mueen_settings/services/dose_alert_service.dart';

void main() {
  // group() is used to organize related test cases together.
  // All tests inside this group are related to route checking in DoseAlertService.
  group('DoseAlertService route checking unit tests', () {
    // Test case 1:
    // This test checks that the alert is allowed on an elder screen.
    test('Elder route allowed: /elder-home returns true', () {
      // Arrange:
      // Define a route name that belongs to the elder area.
      const routeName = '/elder-home';

      // Act:
      // Call the function that checks whether this route is an elder route.
      final result = DoseAlertService.isElderAreaRouteForTest(routeName);

      // Assert:
      // The expected result is true because /elder-home is an allowed elder route.
      expect(result, true);
    });

    // Test case 2:
    // This test checks that the alert is blocked on a non-elder screen.
    test('Non-elder route blocked: /caregiver-home returns false', () {
      // Arrange:
      // Define a route name that does not belong to the elder area.
      const routeName = '/caregiver-home';

      // Act:
      // Call the function to check whether this route is an elder route.
      final result = DoseAlertService.isElderAreaRouteForTest(routeName);

      // Assert:
      // The expected result is false because /caregiver-home is not an elder route.
      expect(result, false);
    });

    // Test case 3:
    // This test checks how the function handles a null route.
    test('Null route handling: null returns false', () {
      // Arrange:
      // Define a null route name to simulate a missing or unknown route.
      const String? routeName = null;

      // Act:
      // Call the function with a null route.
      final result = DoseAlertService.isElderAreaRouteForTest(routeName);

      // Assert:
      // The expected result is false because a null route should not open the alert.
      expect(result, false);
    });
  });

  // Test case 4:
// This test checks that the generated key starts with the elder ID.
  test('Today dose key contains elder id', () {
    // Act:
    // Generate today's dose key for elder with ID = 1.
    final result = DoseAlertService.todayDoseKeyForTest(1);

    // Assert:
    // The key should start with "1-" because the elder ID is part of the key.
    expect(result.startsWith('1-'), true);
  });

// Test case 5:
// This test checks that the generated key uses the correct date format.
  test('Today dose key uses date format yyyy-mm-dd', () {
    // Act:
    // Generate today's dose key for elder with ID = 1.
    final result = DoseAlertService.todayDoseKeyForTest(1);

    // Arrange:
    // Define the expected pattern:
    // elderId-year-month-day
    // Example: 1-2026-05-22
    final pattern = RegExp(r'^1-\d{4}-\d{2}-\d{2}$');

    // Assert:
    // The generated key should match the expected format.
    expect(pattern.hasMatch(result), true);
  });
}
