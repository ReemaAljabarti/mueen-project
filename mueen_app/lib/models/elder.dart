// lib/models/elder.dart
//
// التغيير الوحيد عن النسخة الأصلية:
//   Elder.fromJson يعالج health_conditions بأمان سواء جاءت:
//     - List   → مباشرة من /elders/{caregiver_id}
//     - String → JSON-encoded من /elder/login (لأن SQLite تخزنها نصاً)
//     - null   → قائمة فارغة

import 'dart:convert';

class Elder {
  final int? id;
  final int caregiverId;
  final String fullName;
  final String phoneNumber;
  final String gender;
  final String password;
  final String? age;
  final String? weight;
  final List<String> healthConditions;

  Elder({
    this.id,
    required this.caregiverId,
    required this.fullName,
    required this.phoneNumber,
    required this.gender,
    required this.password,
    this.age,
    this.weight,
    required this.healthConditions,
  });

  Elder copyWith({
    int? id,
    int? caregiverId,
    String? fullName,
    String? phoneNumber,
    String? gender,
    String? password,
    String? age,
    String? weight,
    List<String>? healthConditions,
  }) {
    return Elder(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      password: password ?? this.password,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      healthConditions: healthConditions ?? this.healthConditions,
    );
  }

  factory Elder.fromJson(Map<String, dynamic> json) {
    return Elder(
      id: json['id'] as int?,
      caregiverId: json['caregiver_id'] as int,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      gender: json['gender'] as String,
      password: json['password'] as String,
      age: json['age'] as String?,
      weight: json['weight'] as String?,
      // ─── معالجة آمنة لـ health_conditions ─────────────────────────────
      // /elders/{caregiver_id} → يُعيدها List بعد json.loads في Python
      // /elder/login           → يُعيدها String لأن dict(sqlite3.Row) لا يُحوّلها
      healthConditions: _parseHealthConditions(json['health_conditions']),
    );
  }

  /// يحوّل health_conditions بأمان بغض النظر عن نوعها
  static List<String> _parseHealthConditions(dynamic raw) {
    if (raw == null) return [];

    // حالة 1: قائمة جاهزة (من /elders/{caregiver_id})
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }

    // حالة 2: نص JSON (من /elder/login عبر dict(sqlite3.Row))
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return [];
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // إذا فشل الـ JSON parsing، نُعيد قائمة فارغة بدلاً من crash
      }
    }

    return [];
  }
}
