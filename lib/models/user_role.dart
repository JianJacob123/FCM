enum UserRole {
  passenger,
  conductor,
}

class UserModel {
  final String id;
  final String name;
  final UserRole role;
  final String? vehicleId; // For conductors

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.vehicleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.toString(),
      'vehicleId': vehicleId,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
      ),
      vehicleId: json['vehicleId'],
    );
  }
} 