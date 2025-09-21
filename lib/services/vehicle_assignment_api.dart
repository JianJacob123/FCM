import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleAssignment {
  final int? assignmentId;
  final int vehicleId;
  final String? driver;
  final String? conductor;
  final String? unitNumber;
  final String? plateNumber;

  VehicleAssignment({
    this.assignmentId,
    required this.vehicleId,
    this.driver,
    this.conductor,
    this.unitNumber,
    this.plateNumber,
  });

  factory VehicleAssignment.fromJson(Map<String, dynamic> json) {
    return VehicleAssignment(
      assignmentId: json['assignment_id'],
      vehicleId: json['vehicle_id'],
      driver: json['driver']?.toString(),
      conductor: json['conductor']?.toString(),
      unitNumber: json['unit_number']?.toString(),
      plateNumber: json['plate_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'driver': driver ?? '',
      'conductor': conductor ?? '',
    };
  }
}

class Vehicle {
  final int vehicleId;
  final String unitNumber;
  final String plateNumber;

  Vehicle({
    required this.vehicleId,
    required this.unitNumber,
    required this.plateNumber,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'],
      unitNumber: json['unit_number']?.toString() ?? 'Unknown Unit',
      plateNumber: json['plate_number']?.toString() ?? 'Unknown Plate',
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
      totalItems: json['totalItems'],
      itemsPerPage: json['itemsPerPage'],
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final PaginationInfo? pagination;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      pagination: json['pagination'] != null ? PaginationInfo.fromJson(json['pagination']) : null,
    );
  }
}

class VehicleAssignmentApi {
  static const String baseUrl = 'http://localhost:8080/api/vehicle-assignments';

  // Get all assignments with pagination
  static Future<ApiResponse<List<VehicleAssignment>>> getAssignments({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> assignmentsJson = jsonData['data'];
        final List<VehicleAssignment> assignments = assignmentsJson
            .map((json) => VehicleAssignment.fromJson(json))
            .toList();

        return ApiResponse<List<VehicleAssignment>>(
          success: true,
          data: assignments,
          pagination: jsonData['pagination'] != null
              ? PaginationInfo.fromJson(jsonData['pagination'])
              : null,
        );
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Failed to fetch assignments';
        } catch (_) {
          message = 'Failed to fetch assignments (HTTP ${response.statusCode})';
        }
        return ApiResponse<List<VehicleAssignment>>(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return ApiResponse<List<VehicleAssignment>>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get assignment by ID
  static Future<ApiResponse<VehicleAssignment>> getAssignmentById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final assignment = VehicleAssignment.fromJson(jsonData['data']);
        return ApiResponse<VehicleAssignment>(
          success: true,
          data: assignment,
        );
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Failed to fetch assignment';
        } catch (_) {
          message = 'Failed to fetch assignment (HTTP ${response.statusCode})';
        }
        return ApiResponse<VehicleAssignment>(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return ApiResponse<VehicleAssignment>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Create new assignment
  static Future<ApiResponse<VehicleAssignment>> createAssignment(
    VehicleAssignment assignment,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(assignment.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final createdAssignment = VehicleAssignment.fromJson(jsonData['data']);
        return ApiResponse<VehicleAssignment>(
          success: true,
          message: jsonData['message'],
          data: createdAssignment,
        );
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Failed to create assignment';
        } catch (_) {
          message = 'Failed to create assignment (HTTP ${response.statusCode})';
        }
        return ApiResponse<VehicleAssignment>(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return ApiResponse<VehicleAssignment>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Update assignment
  static Future<ApiResponse<VehicleAssignment>> updateAssignment(
    int id,
    VehicleAssignment assignment,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(assignment.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final updatedAssignment = VehicleAssignment.fromJson(jsonData['data']);
        return ApiResponse<VehicleAssignment>(
          success: true,
          message: jsonData['message'],
          data: updatedAssignment,
        );
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Failed to update assignment';
        } catch (_) {
          message = 'Failed to update assignment (HTTP ${response.statusCode})';
        }
        return ApiResponse<VehicleAssignment>(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return ApiResponse<VehicleAssignment>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Delete assignment
  static Future<ApiResponse<void>> deleteAssignment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse<void>(
          success: true,
          message: jsonData['message'],
        );
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Failed to delete assignment';
        } catch (_) {
          message = 'Failed to delete assignment (HTTP ${response.statusCode})';
        }
        return ApiResponse<void>(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get available vehicles
  static Future<ApiResponse<List<Vehicle>>> getAvailableVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/available'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> vehiclesJson = jsonData['data'];
        final List<Vehicle> vehicles = vehiclesJson
            .map((json) => Vehicle.fromJson(json))
            .toList();

        return ApiResponse<List<Vehicle>>(
          success: true,
          data: vehicles,
        );
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Failed to fetch available vehicles';
        } catch (_) {
          message = 'Failed to fetch available vehicles (HTTP ${response.statusCode})';
        }
        return ApiResponse<List<Vehicle>>(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return ApiResponse<List<Vehicle>>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get all vehicles
  static Future<ApiResponse<List<Vehicle>>> getAllVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> vehiclesJson = jsonData['data'];
        final List<Vehicle> vehicles = vehiclesJson
            .map((json) => Vehicle.fromJson(json))
            .toList();

        return ApiResponse<List<Vehicle>>(
          success: true,
          data: vehicles,
        );
      } else {
        String message;
        try {
          final errorData = json.decode(response.body);
          message = errorData['message'] ?? 'Failed to fetch vehicles';
        } catch (_) {
          message = 'Failed to fetch vehicles (HTTP ${response.statusCode})';
        }
        return ApiResponse<List<Vehicle>>(
          success: false,
          message: message,
        );
      }
    } catch (e) {
      return ApiResponse<List<Vehicle>>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
