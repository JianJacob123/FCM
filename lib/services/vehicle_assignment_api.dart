import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseURL = dotenv.env['API_BASE_URL'];

class VehicleAssignment {
  final int assignmentId;
  final int vehicleId;
  final String? plateNumber;
  final int? driverId;
  final int? conductorId;
  final String? driverName;
  final String? conductorName;
  final DateTime assignedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleAssignment({
    required this.assignmentId,
    required this.vehicleId,
    this.plateNumber,
    this.driverId,
    this.conductorId,
    this.driverName,
    this.conductorName,
    required this.assignedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleAssignment.fromJson(Map<String, dynamic> json) {
    return VehicleAssignment(
      assignmentId: int.parse(json['assignment_id'].toString()),
      vehicleId: int.parse(json['vehicle_id'].toString()),
      plateNumber: json['plate_number'],
      driverId: json['driver_id'] != null ? int.parse(json['driver_id'].toString()) : null,
      conductorId: json['conductor_id'] != null ? int.parse(json['conductor_id'].toString()) : null,
      driverName: json['driver_name'],
      conductorName: json['conductor_name'],
      assignedAt: DateTime.parse(json['assigned_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'vehicle_id': vehicleId,
      'plate_number': plateNumber,
      'driver_id': driverId,
      'conductor_id': conductorId,
      'driver_name': driverName,
      'conductor_name': conductorName,
      'assigned_at': assignedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VehicleInfo {
  final int vehicleId;
  final double? lat;
  final double? lng;
  final DateTime? lastUpdate;

  VehicleInfo({required this.vehicleId, this.lat, this.lng, this.lastUpdate});

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      vehicleId: json['vehicle_id'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      lastUpdate: json['last_update'] != null
          ? DateTime.parse(json['last_update'])
          : null,
    );
  }
}

class UserInfo {
  final int userId;
  final String fullName;
  final String userRole;
  final bool active;

  UserInfo({
    required this.userId,
    required this.fullName,
    required this.userRole,
    required this.active,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'],
      fullName: json['full_name'],
      userRole: json['user_role'],
      active: json['active'],
    );
  }
}

class VehicleAssignmentResponse {
  final bool success;
  final String? message;
  final List<VehicleAssignment>? data;
  final VehicleAssignment? assignment;
  final List<VehicleInfo>? vehicles;
  final List<UserInfo>? users;

  VehicleAssignmentResponse({
    required this.success,
    this.message,
    this.data,
    this.assignment,
    this.vehicles,
    this.users,
  });

  factory VehicleAssignmentResponse.fromJson(Map<String, dynamic> json) {
    return VehicleAssignmentResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && json['data'] is List
          ? (json['data'] as List)
                .map((item) => VehicleAssignment.fromJson(item))
                .toList()
          : null,
      assignment: json['data'] != null && json['data'] is Map<String, dynamic>
          ? VehicleAssignment.fromJson(json['data'])
          : null,
      vehicles: json['vehicles'] != null
          ? (json['vehicles'] as List)
                .map((item) => VehicleInfo.fromJson(item))
                .toList()
          : null,
      users: json['users'] != null
          ? (json['users'] as List)
                .map((item) => UserInfo.fromJson(item))
                .toList()
          : null,
    );
  }
}

class VehicleAssignmentApiService {
  static String baseUrl = '$baseURL/api/vehicle-assignments';

  // Get all vehicle assignments
  static Future<VehicleAssignmentResponse> getAllAssignments() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        return VehicleAssignmentResponse.fromJson(json.decode(response.body));
      } else {
        return VehicleAssignmentResponse(
          success: false,
          message:
              'Failed to fetch vehicle assignments: ${response.statusCode}',
        );
      }
    } catch (e) {
      return VehicleAssignmentResponse(
        success: false,
        message: 'Error fetching vehicle assignments: $e',
      );
    }
  }

  // Get assignment by ID
  static Future<VehicleAssignmentResponse> getAssignmentById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        return VehicleAssignmentResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return VehicleAssignmentResponse(
          success: false,
          message: 'Assignment not found',
        );
      } else {
        return VehicleAssignmentResponse(
          success: false,
          message: 'Failed to fetch assignment: ${response.statusCode}',
        );
      }
    } catch (e) {
      return VehicleAssignmentResponse(
        success: false,
        message: 'Error fetching assignment: $e',
      );
    }
  }

  // Create new assignment
  static Future<VehicleAssignmentResponse> createAssignment({
    required int vehicleId,
    required String plateNumber,
    int? driverId,
    int? conductorId,
  }) async {
    try {
      final body = <String, dynamic>{
        'vehicle_id': vehicleId,
        'plate_number': plateNumber,
      };
      if (driverId != null) body['driver_id'] = driverId;
      if (conductorId != null) body['conductor_id'] = conductorId;

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return VehicleAssignmentResponse.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        return VehicleAssignmentResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to create assignment',
        );
      }
    } catch (e) {
      return VehicleAssignmentResponse(
        success: false,
        message: 'Error creating assignment: $e',
      );
    }
  }

  // Update assignment
  static Future<VehicleAssignmentResponse> updateAssignment({
    required int assignmentId,
    int? vehicleId,
    String? plateNumber,
    int? driverId,
    int? conductorId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (vehicleId != null) body['vehicle_id'] = vehicleId;
      if (plateNumber != null) body['plate_number'] = plateNumber;
      if (driverId != null) body['driver_id'] = driverId;
      if (conductorId != null) body['conductor_id'] = conductorId;

      final response = await http.put(
        Uri.parse('$baseUrl/$assignmentId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return VehicleAssignmentResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return VehicleAssignmentResponse(
          success: false,
          message: 'Assignment not found',
        );
      } else {
        final errorData = json.decode(response.body);
        return VehicleAssignmentResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to update assignment',
        );
      }
    } catch (e) {
      return VehicleAssignmentResponse(
        success: false,
        message: 'Error updating assignment: $e',
      );
    }
  }

  // Delete assignment
  static Future<VehicleAssignmentResponse> deleteAssignment(
    int assignmentId,
  ) async {
    try {
      print('Frontend: Attempting to delete assignment with ID: $assignmentId');
      print('Frontend: API URL: $baseUrl/$assignmentId');
      
      final response = await http.delete(Uri.parse('$baseUrl/$assignmentId'));
      
      print('Frontend: Response status code: ${response.statusCode}');
      print('Frontend: Response body: ${response.body}');

      if (response.statusCode == 200) {
        return VehicleAssignmentResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return VehicleAssignmentResponse(
          success: false,
          message: 'Assignment not found',
        );
      } else {
        return VehicleAssignmentResponse(
          success: false,
          message: 'Failed to delete assignment: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Frontend: Error deleting assignment: $e');
      return VehicleAssignmentResponse(
        success: false,
        message: 'Error deleting assignment: $e',
      );
    }
  }

  // Get available vehicles (not assigned)
  static Future<List<VehicleInfo>> getAvailableVehicles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vehicles/available'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((vehicle) => VehicleInfo.fromJson(vehicle))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching available vehicles: $e');
      return [];
    }
  }

  // Get available drivers
  static Future<List<UserInfo>> getAvailableDrivers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/drivers/available'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((user) => UserInfo.fromJson(user))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching available drivers: $e');
      return [];
    }
  }

  // Get available conductors
  static Future<List<UserInfo>> getAvailableConductors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conductors/available'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((user) => UserInfo.fromJson(user))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching available conductors: $e');
      return [];
    }
  }

  // Get all vehicles with assignment status
  static Future<List<Map<String, dynamic>>> getAllVehiclesWithStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vehicles/status'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching vehicles with status: $e');
      return [];
    }
  }
}
