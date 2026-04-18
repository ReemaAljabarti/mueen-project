class Elder {
  final int caregiverId;
  final String fullName;
  final String phoneNumber;
  final String gender;
  final String password;
  final String? age;
  final String? weight;
  final List<String> healthConditions;

  Elder({
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
}
