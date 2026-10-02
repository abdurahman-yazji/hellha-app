import 'user_role.dart';

class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final UserRole role;

  const AppUser({required this.uid, this.name, this.email, required this.role});
}
