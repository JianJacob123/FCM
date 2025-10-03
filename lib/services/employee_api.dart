import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String _apiBase() => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

class Employee {
  final int id;
  final String fullName;
  final String position;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.fullName,
    required this.position,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? json['user_id'],
      fullName: json['full_name'] ?? '',
      position: json['position'] ?? json['user_role'] ?? '',
      active: json['active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'position': position,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Employee copyWith({
    int? id,
    String? fullName,
    String? position,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      position: position ?? this.position,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EmployeePagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  EmployeePagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  factory EmployeePagination.fromJson(Map<String, dynamic> json) {
    return EmployeePagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      limit: json['limit'] ?? 15,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class EmployeeResponse {
  final bool success;
  final String? message;
  final List<Employee>? data;
  final Employee? employee;
  final EmployeePagination? pagination;

  EmployeeResponse({
    required this.success,
    this.message,
    this.data,
    this.employee,
    this.pagination,
  });

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && json['data'] is List
          ? (json['data'] as List)
                .map((item) => Employee.fromJson(item))
                .toList()
          : null,
      employee: json['data'] != null && json['data'] is Map<String, dynamic>
          ? Employee.fromJson(json['data'])
          : null,
      pagination: json['pagination'] != null
          ? EmployeePagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class EmployeeApiService {
  static String _employeesUrl() => '${_apiBase()}/api/employees';

  // Get all employees with pagination and filtering
  static Future<EmployeeResponse> getAllEmployees({
    int page = 1,
    int limit = 15,
    String? position,
    bool? active,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (position != null && position.isNotEmpty) {
        queryParams['position'] = position;
      }

      if (active != null) {
        queryParams['active'] = active.toString();
      }

      final uri = Uri.parse(_employeesUrl()).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return EmployeeResponse.fromJson(json.decode(response.body));
      } else {
        return EmployeeResponse(
          success: false,
          message: 'Failed to fetch employees: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EmployeeResponse(
        success: false,
        message: 'Error fetching employees: $e',
      );
    }
  }

  // Get employee by ID
  static Future<EmployeeResponse> getEmployeeById(int id) async {
    try {
      final response = await http.get(Uri.parse('${_employeesUrl()}/$id'));

      if (response.statusCode == 200) {
        return EmployeeResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return EmployeeResponse(success: false, message: 'Employee not found');
      } else {
        return EmployeeResponse(
          success: false,
          message: 'Failed to fetch employee: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EmployeeResponse(
        success: false,
        message: 'Error fetching employee: $e',
      );
    }
  }

  // Create new employee
  static Future<EmployeeResponse> createEmployee({
    required String fullName,
    required String position,
    bool active = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_employeesUrl()),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'position': position,
          'active': active,
        }),
      );

      if (response.statusCode == 201) {
        return EmployeeResponse.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        return EmployeeResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to create employee',
        );
      }
    } catch (e) {
      return EmployeeResponse(
        success: false,
        message: 'Error creating employee: $e',
      );
    }
  }

  // Update employee
  static Future<EmployeeResponse> updateEmployee({
    required int id,
    String? fullName,
    String? position,
    bool? active,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (position != null) body['position'] = position;
      if (active != null) body['active'] = active;

      final response = await http.put(
        Uri.parse('${_employeesUrl()}/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return EmployeeResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return EmployeeResponse(success: false, message: 'Employee not found');
      } else {
        final errorData = json.decode(response.body);
        return EmployeeResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to update employee',
        );
      }
    } catch (e) {
      return EmployeeResponse(
        success: false,
        message: 'Error updating employee: $e',
      );
    }
  }

  // Delete employee
  static Future<EmployeeResponse> deleteEmployee(int id) async {
    try {
      final response = await http.delete(Uri.parse('${_employeesUrl()}/$id'));

      if (response.statusCode == 200) {
        return EmployeeResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return EmployeeResponse(success: false, message: 'Employee not found');
      } else {
        return EmployeeResponse(
          success: false,
          message: 'Failed to delete employee: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EmployeeResponse(
        success: false,
        message: 'Error deleting employee: $e',
      );
    }
  }

  // Get employees by position
  static Future<EmployeeResponse> getEmployeesByPosition(
    String position,
  ) async {
    try {
      final response = await http.get(Uri.parse('${_employeesUrl()}/position/$position'));

      if (response.statusCode == 200) {
        return EmployeeResponse.fromJson(json.decode(response.body));
      } else {
        return EmployeeResponse(
          success: false,
          message:
              'Failed to fetch employees by position: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EmployeeResponse(
        success: false,
        message: 'Error fetching employees by position: $e',
      );
    }
  }

  // Toggle employee status
  static Future<EmployeeResponse> toggleEmployeeStatus(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('${_employeesUrl()}/$id/toggle-status'),
      );

      if (response.statusCode == 200) {
        return EmployeeResponse.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return EmployeeResponse(success: false, message: 'Employee not found');
      } else {
        return EmployeeResponse(
          success: false,
          message: 'Failed to toggle employee status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EmployeeResponse(
        success: false,
        message: 'Error toggling employee status: $e',
      );
    }
  }
}
