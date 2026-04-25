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
      id: json['id'],
      caregiverId: json['caregiver_id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      gender: json['gender'],
      password: json['password'],
      age: json['age'],
      weight: json['weight'],
      healthConditions: json['health_conditions'] != null
          ? List<String>.from(json['health_conditions'])
          : [],
    );
  }
}
