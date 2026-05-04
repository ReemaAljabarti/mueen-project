import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/elder.dart';
import '../models/medication.dart';
import '../models/elder_medication.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:8000'; // for Android emulator, use
  // static const String baseUrl ='http://192.168.1.14:8000'; // for real device, use local network IP address of the machine running the backend
  static Future<Map<String, dynamic>> caregiverSignup({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/caregiver/signup');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> caregiverLogin({
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/caregiver/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Elder> addElder(Elder elder) async {
    final url = Uri.parse('$baseUrl/elders');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'caregiver_id': elder.caregiverId,
        'full_name': elder.fullName,
        'phone_number': elder.phoneNumber,
        'gender': elder.gender,
        'password': elder.password,
        'age': elder.age,
        'weight': elder.weight,
        'health_conditions': elder.healthConditions,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add elder: ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data['success'] != true || data['data'] == null) {
      throw Exception(data['message'] ?? 'Failed to add elder');
    }

    return Elder.fromJson(data['data']);
  }

  static Future<List<Elder>> getElders({
    required int caregiverId,
  }) async {
    final url = Uri.parse('$baseUrl/elders/$caregiverId');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load elders: ${response.body}');
    }

    final List data = jsonDecode(response.body);

    return data.map((e) {
      return Elder(
        id: e['id'],
        caregiverId: e['caregiver_id'],
        fullName: e['full_name'],
        phoneNumber: e['phone_number'],
        gender: e['gender'],
        password: e['password'],
        age: e['age'],
        weight: e['weight'],
        healthConditions: e['health_conditions'] != null
            ? List<String>.from(e['health_conditions'])
            : [],
      );
    }).toList();
  }

  static Future<Map<String, dynamic>> elderLogin({
    required String phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/elder/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCaregivers() async {
    final url = Uri.parse('$baseUrl/caregivers');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load caregivers: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<List<Medication>> searchMedications({
    required String query,
  }) async {
    final url = Uri.parse(
      '$baseUrl/medications/search?query=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to search medications: ${response.body}');
    }

    final List data = jsonDecode(response.body);

    return data.map((e) => Medication.fromJson(e)).toList();
  }

  static Future<Medication?> getMedicationByGtin({
    required String gtin,
  }) async {
    final url = Uri.parse('$baseUrl/medications/by-gtin/$gtin');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to lookup medication by gtin: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data['found'] == true && data['medication'] != null) {
      return Medication.fromJson(data['medication']);
    }

    return null;
  }

  static Future<List<ElderMedication>> getElderMedications({
    required int elderId,
  }) async {
    final url = Uri.parse('$baseUrl/elder-medications/$elderId');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load elder medications: ${response.body}');
    }

    final List data = jsonDecode(response.body);

    return data.map((e) => ElderMedication.fromJson(e)).toList();
  }

  static Future<void> createElderMedication({
    required int elderId,
    required int catalogMedicationId,
    required String? displayNameForElder,
    required int dosageAmount,
    required String dosageUnit,
    required String? usageInstruction,
    required String? shortDescription,
    required String? treatmentDurationType,
    required String? startDate,
    required String? endDate,
    required int timesPerDay,
    required String firstReminderTime,
    required String daysPattern,
  }) async {
    final url = Uri.parse('$baseUrl/elder-medications');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'elder_id': elderId,
        'catalog_medication_id': catalogMedicationId,
        'display_name_for_elder': displayNameForElder,
        'dosage_amount': dosageAmount,
        'dosage_unit': dosageUnit,
        'usage_instruction': usageInstruction,
        'short_description': shortDescription,
        'treatment_duration_type': treatmentDurationType,
        'start_date': startDate,
        'end_date': endDate,
        'times_per_day': timesPerDay,
        'first_reminder_time': firstReminderTime,
        'days_pattern': daysPattern,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create elder medication: ${response.body}',
      );
    }
  }

  static Future<void> deleteElderMedication({
    required int elderMedicationId,
  }) async {
    final url = Uri.parse('$baseUrl/elder-medications/$elderMedicationId');

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete elder medication: ${response.body}',
      );
    }
  }

  static Future<void> updateElderMedication({
    required int elderMedicationId,
    required String? displayNameForElder,
    required int dosageAmount,
    required String dosageUnit,
    required String firstReminderTime,
  }) async {
    final url = Uri.parse('$baseUrl/elder-medications/$elderMedicationId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'display_name_for_elder': displayNameForElder,
        'dosage_amount': dosageAmount,
        'dosage_unit': dosageUnit,
        'first_reminder_time': firstReminderTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update elder medication: ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> checkDrugInteraction({
    required int elderId,
    required int catalogMedicationId,
  }) async {
    final url = Uri.parse('$baseUrl/drug-interactions/check');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'elder_id': elderId,
        'catalog_medication_id': catalogMedicationId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to check drug interaction: ${response.body}',
      );
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getElderDrugInteractions({
    required int elderId,
  }) async {
    final url = Uri.parse('$baseUrl/elders/$elderId/drug-interactions');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load elder drug interactions: ${response.body}',
      );
    }

    return jsonDecode(response.body);
  }

  // ─── Dose Reminder & Adherence ────────────────────────────────────────────

  /// GET /reminders/due-now/{elderId}
  /// Returns due doses for the elder right now.
  static Future<Map<String, dynamic>> getDueDoses({
    required int elderId,
  }) async {
    final url = Uri.parse('$baseUrl/reminders/due-now/$elderId');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch due doses: \${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /adherence/taken
  /// Marks a dose as taken and logs it.
  static Future<void> markDoseTaken({
    required int doseId,
    required int elderId,
    required int elderMedicationId,
  }) async {
    final url = Uri.parse('$baseUrl/adherence/taken');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'dose_id': doseId,
        'elder_id': elderId,
        'elder_medication_id': elderMedicationId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark dose taken: \${response.body}');
    }
  }

  /// POST /adherence/missed
  /// Marks a dose as missed and alerts the caregiver.
  static Future<void> markDoseMissed({
    required int doseId,
    required int elderId,
    required int elderMedicationId,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/adherence/missed');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'dose_id': doseId,
        'elder_id': elderId,
        'elder_medication_id': elderMedicationId,
        if (note != null) 'note': note,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark dose missed: \${response.body}');
    }
  }

  /// POST /reminders/snooze
  /// Snoozes a dose once (15, 20, or 30 minutes only).
  /// A second snooze attempt marks the dose as missed on the backend.
  static Future<Map<String, dynamic>> snoozeDose({
    required int doseId,
    required int elderId,
    required int elderMedicationId,
    required int snoozeMinutes,
  }) async {
    final url = Uri.parse('$baseUrl/reminders/snooze');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'dose_id': doseId,
        'elder_id': elderId,
        'elder_medication_id': elderMedicationId,
        'snooze_minutes': snoozeMinutes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to snooze dose: \${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /adherence/no-response
  /// Called when the dose timer expires with no action.
  static Future<void> markDoseNoResponse({
    required int doseId,
    required int elderId,
    required int elderMedicationId,
  }) async {
    final url = Uri.parse('$baseUrl/adherence/no-response');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'dose_id': doseId,
        'elder_id': elderId,
        'elder_medication_id': elderMedicationId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark dose no-response: \${response.body}');
    }
  }

  /// GET /caregiver/missed-doses/{caregiverId}
  /// Returns today's missed/no_response doses for all elders under this caregiver.
  static Future<Map<String, dynamic>> getMissedDoses({
    required int caregiverId,
  }) async {
    final url = Uri.parse('$baseUrl/caregiver/missed-doses/$caregiverId');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load missed doses: \${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /reports/weekly/{elderId}
  /// Returns weekly adherence summary for the report screen.
  static Future<Map<String, dynamic>> getWeeklyReport({
    required int elderId,
  }) async {
    final url = Uri.parse('$baseUrl/reports/weekly/$elderId');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load weekly report: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
