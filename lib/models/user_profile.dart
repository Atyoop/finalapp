class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String gender;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.dateOfBirth,
    required this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      dateOfBirth: DateTime.tryParse(
        (json['dateOfBirth'] ?? json['birthDate'] ?? '').toString(),
      ),
      gender: (json['gender'] ?? '').toString(),
    );
  }
}
