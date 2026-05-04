// lib/models/elder_medication.dart
//
// تم إضافة: medCategory (med_category من medications_catalog)

class ElderMedication {
  final int id;
  final int elderId;
  final int catalogMedicationId;
  final String? displayNameForElder;
  final int dosageAmount;
  final String dosageUnit;
  final String? usageInstruction;
  final String? shortDescription;
  final int timesPerDay;
  final String firstReminderTime;
  final String daysPattern;
  final String brandNameAr;
  final String? dosageForm;
  final String? dosageStrength;
  final String? routeAr;
  final String? foodGuideAr;
  final String? gtin;
  // ← جديد: فئة الدواء من medications_catalog
  final String? medCategory;

  ElderMedication({
    required this.id,
    required this.elderId,
    required this.catalogMedicationId,
    this.displayNameForElder,
    required this.dosageAmount,
    required this.dosageUnit,
    this.usageInstruction,
    this.shortDescription,
    required this.timesPerDay,
    required this.firstReminderTime,
    required this.daysPattern,
    required this.brandNameAr,
    this.dosageForm,
    this.dosageStrength,
    this.routeAr,
    this.foodGuideAr,
    this.gtin,
    this.medCategory,
  });

  factory ElderMedication.fromJson(Map<String, dynamic> json) {
    return ElderMedication(
      id: json['id'],
      elderId: json['elder_id'],
      catalogMedicationId: json['catalog_medication_id'],
      displayNameForElder: json['display_name_for_elder'],
      dosageAmount: json['dosage_amount'],
      dosageUnit: json['dosage_unit'],
      usageInstruction: json['usage_instruction'],
      shortDescription: json['short_description'],
      timesPerDay: json['times_per_day'],
      firstReminderTime: json['first_reminder_time'],
      daysPattern: json['days_pattern'],
      brandNameAr: json['brand_name_ar'],
      dosageForm: json['dosage_form'],
      dosageStrength: json['dosage_strength'],
      routeAr: json['route_ar'],
      foodGuideAr: json['food_guide_ar'],
      gtin: json['gtin']?.toString(),
      // ← جديد
      medCategory: json['med_category'],
    );
  }
}
