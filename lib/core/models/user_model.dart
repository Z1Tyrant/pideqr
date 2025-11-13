enum UserRole { cliente, vendedor, admin, desconocido }

class UserModel {
  final String uid; 
  final String email;
  final String name;
  final UserRole role;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Usuario PideQR',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == (data['role'] ?? 'desconocido'),
        orElse: () => UserRole.desconocido,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
    };
  }
}