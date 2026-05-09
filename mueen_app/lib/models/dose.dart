class Dose {
  final int doseId;
  final int elderMedicationId;
  final int elderId;
  final String scheduledTime;
  final String doseDate;
  final String status;
  final int snoozeCount;
  final String? snoozedUntil;
  final String? takenAt;
  final String? missedAt;
  final String medicationName;
  final String brandNameAr;
  final String? genericNameEn;
  final String? medCategory;
  final int dosageAmount;
  final String dosageUnit;
  final String? dosageForm;
  final String? dosageStrength;
  final String? routeAr;
  final String? foodGuideAr;
  final String? usageInstruction;
  final String? gtin;

  Dose({
    required this.doseId,
    required this.elderMedicationId,
    required this.elderId,
    required this.scheduledTime,
    required this.doseDate,
    required this.status,
    required this.snoozeCount,
    this.snoozedUntil,
    this.takenAt,
    this.missedAt,
    required this.medicationName,
    required this.brandNameAr,
    this.genericNameEn,
    this.medCategory,
    required this.dosageAmount,
    required this.dosageUnit,
    this.dosageForm,
    this.dosageStrength,
    this.routeAr,
    this.foodGuideAr,
    this.usageInstruction,
    this.gtin,
  });

  factory Dose.fromJson(Map<String, dynamic> json) {
    return Dose(
      doseId: json['dose_id'] ?? 0,
      elderMedicationId: json['elder_medication_id'] ?? 0,
      elderId: json['elder_id'] ?? 0,
      scheduledTime: json['scheduled_time']?.toString() ?? '',
      doseDate: json['dose_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      snoozeCount: json['snooze_count'] ?? 0,
      snoozedUntil: json['snoozed_until']?.toString(),
      takenAt: json['taken_at']?.toString(),
      missedAt: json['missed_at']?.toString(),
      medicationName: json['medication_name']?.toString() ?? '',
      brandNameAr: json['brand_name_ar']?.toString() ?? '',
      genericNameEn: json['generic_name_en']?.toString(),
      medCategory: json['med_category']?.toString(),
      dosageAmount: json['dosage_amount'] ?? 0,
      dosageUnit: json['dosage_unit']?.toString() ?? '',
      dosageForm: json['dosage_form']?.toString(),
      dosageStrength: json['dosage_strength']?.toString(),
      routeAr: json['route_ar']?.toString(),
      foodGuideAr: json['food_guide_ar']?.toString(),
      usageInstruction: json['usage_instruction']?.toString(),
      gtin: json['gtin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dose_id': doseId,
      'elder_medication_id': elderMedicationId,
      'elder_id': elderId,
      'scheduled_time': scheduledTime,
      'dose_date': doseDate,
      'status': status,
      'snooze_count': snoozeCount,
      'snoozed_until': snoozedUntil,
      'taken_at': takenAt,
      'missed_at': missedAt,
      'medication_name': medicationName,
      'brand_name_ar': brandNameAr,
      'generic_name_en': genericNameEn,
      'med_category': medCategory,
      'dosage_amount': dosageAmount,
      'dosage_unit': dosageUnit,
      'dosage_form': dosageForm,
      'dosage_strength': dosageStrength,
      'route_ar': routeAr,
      'food_guide_ar': foodGuideAr,
      'usage_instruction': usageInstruction,
      'gtin': gtin,
    };
  }

  String get displayName {
    if (medicationName.trim().isNotEmpty) {
      return medicationName;
    }

    return brandNameAr;
  }

  String get effectiveTime {
    if (status == 'snoozed' &&
        snoozedUntil != null &&
        snoozedUntil!.trim().isNotEmpty) {
      return snoozedUntil!;
    }

    return scheduledTime;
  }

  bool get isTaken => status == 'taken';

  bool get isMissed => status == 'missed' || status == 'no_response';

  bool get isSnoozed => status == 'snoozed';

  bool get isPending => status == 'pending';
}
