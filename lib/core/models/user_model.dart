// lib/core/models/user_model.dart

enum UserRole { cliente, vendedor, manager, admin, desconocido } // <-- ROL AÑADIDO

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? tiendaId;
  final String? deliveryZone;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.tiendaId,
    this.deliveryZone,
  });

  static UserRole _roleFromString(String? roleString) {
    if (roleString == null) return UserRole.desconocido;
    switch (roleString.toLowerCase()) {
      case 'cliente':
        return UserRole.cliente;
      case 'vendedor':
        return UserRole.vendedor;
      case 'manager': // <-- LÓGICA AÑADIDA
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.desconocido;
    }
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Usuario PideQR',
      role: _roleFromString(data['role'] as String?),
      tiendaId: data['tiendaId'] as String?,
      deliveryZone: data['deliveryZone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name, // .name es más seguro que toString()
      if (tiendaId != null) 'tiendaId': tiendaId,
      if (deliveryZone != null) 'deliveryZone': deliveryZone,
    };
  }
}
