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
  final String? gtin;

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
    this.gtin,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      drugId: json['drug_id']?.toString() ?? '',
      brandNameAr: json['brand_name_ar']?.toString() ?? '',
      genericNameEn: json['generic_name_en']?.toString(),
      dosageStrength: json['dosage_strength']?.toString(),
      dosageForm: json['dosage_form']?.toString(),
      routeAr: json['route_ar']?.toString(),
      usesAr: json['uses_ar']?.toString(),
      foodGuideAr: json['food_guide_ar']?.toString(),
      gtin: json['gtin']?.toString(),
    );
  }
}
