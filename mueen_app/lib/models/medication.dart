class Medication {
  final int id;
  final String drugId;
  final String brandNameAr;
  final String? genericNameEn;
  final String? dosageStrength;
  final String? dosageForm;
  final String? routeAr;
  final String? usesAr;
  final String? foodGuideAr;

  Medication({
    required this.id,
    required this.drugId,
    required this.brandNameAr,
    this.genericNameEn,
    this.dosageStrength,
    this.dosageForm,
    this.routeAr,
    this.usesAr,
    this.foodGuideAr,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      drugId: json['drug_id'],
      brandNameAr: json['brand_name_ar'],
      genericNameEn: json['generic_name_en'],
      dosageStrength: json['dosage_strength'],
      dosageForm: json['dosage_form'],
      routeAr: json['route_ar'],
      usesAr: json['uses_ar'],
      foodGuideAr: json['food_guide_ar'],
    );
  }
}
