// Pure Dart entity — no Flutter or backend imports.

enum UserRole { donor, driver, beneficiary }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
}
