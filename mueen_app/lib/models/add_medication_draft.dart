class AddMedicationDraft {
  final int elderId;

  // Reference medication
  final int catalogMedicationId;
  final String brandName;

  // Details
  String? displayNameForElder;
  int? dosageAmount;
  String? dosageUnit;

  // Optional
  String? usageInstruction;
  String? shortDescription;
  String? treatmentDurationType;
  String? startDate;
  String? endDate;

  // Scheduling
  int? timesPerDay;
  String? firstReminderTime;
  String? daysPattern;

  AddMedicationDraft({
    required this.elderId,
    required this.catalogMedicationId,
    required this.brandName,
  });
}
