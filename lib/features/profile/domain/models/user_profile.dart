class UserProfile {
  final String id;
  final String firebaseUid;
  final String? name;
  final String? email;
  final String role;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.firebaseUid,
    this.name,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      firebaseUid: json['firebase_uid'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      isActive: json['is_active'],
    );
  }
}
