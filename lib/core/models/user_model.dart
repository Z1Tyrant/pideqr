enum UserRole { cliente, vendedor, admin, desconocido }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? tiendaId;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.tiendaId,
  });

  // --- MÉTODO DE AYUDA PARA CONVERTIR EL ROL DE FORMA SEGURA ---
  static UserRole _roleFromString(String? roleString) {
    if (roleString == null) return UserRole.desconocido;
    // Convierte el string a minúsculas para evitar errores de mayúsculas/minúsculas
    switch (roleString.toLowerCase()) {
      case 'cliente':
        return UserRole.cliente;
      case 'vendedor':
        return UserRole.vendedor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.desconocido;
    }
  }

  // --- fromFirestore REFACTORIZADO ---
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Usuario PideQR',
      // Usamos la nueva función para más seguridad
      role: _roleFromString(data['role'] as String?),
      tiendaId: data['tiendaId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      // Guarda el rol como un string en minúsculas
      'role': role.toString().split('.').last,
      if (tiendaId != null) 'tiendaId': tiendaId,
    };
  }
}
