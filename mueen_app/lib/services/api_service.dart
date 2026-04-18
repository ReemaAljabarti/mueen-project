import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/elder.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

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

    final data = jsonDecode(response.body);
    return data;
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

    final data = jsonDecode(response.body);
    return data;
  }

  static Future<void> addElder(Elder elder) async {
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
        caregiverId: e['caregiver_id'],
        fullName: e['full_name'],
        phoneNumber: e['phone_number'],
        gender: e['gender'],
        password: e['password'],
        age: e['age'],
        weight: e['weight'],
        healthConditions: List<String>.from(e['health_conditions']),
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

    final data = jsonDecode(response.body);
    return data;
  }

  static Future<List<dynamic>> getCaregivers() async {
    final url = Uri.parse('$baseUrl/caregivers');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load caregivers');
    }

    return jsonDecode(response.body);
  }
}
