// lib/core/models/user_model.dart

enum UserRole { cliente, vendedor, manager, admin, desconocido }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? tiendaId;
  final String? deliveryZone;
  final List<String> fcmTokens;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.tiendaId,
    this.deliveryZone,
    this.fcmTokens = const [],
  });

  static UserRole _roleFromString(String? roleString) {
    if (roleString == null) return UserRole.desconocido;
    switch (roleString.toLowerCase()) {
      case 'cliente':
        return UserRole.cliente;
      case 'vendedor':
        return UserRole.vendedor;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.desconocido;
    }
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    final tokensFromDb = data['fcm_tokens'] as List<dynamic>?;

    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Usuario PideQR',
      role: _roleFromString(data['role'] as String?),
      tiendaId: data['tienda_id'] as String?,
      deliveryZone: data['delivery_zone'] as String?,
      fcmTokens: tokensFromDb?.map((token) => token as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      if (tiendaId != null) 'tienda_id': tiendaId,
      if (deliveryZone != null) 'delivery_zone': deliveryZone,
      'fcm_tokens': fcmTokens,
    };
  }
}
