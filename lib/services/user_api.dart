import 'dart:convert';
import 'package:http/http.dart' as http;

class UserAccount {
  final int userId;
  final String fullName;
  final String userRole;
  final String username;
  final bool active;

  UserAccount({
    required this.userId,
    required this.fullName,
    required this.userRole,
    required this.username,
    required this.active,
  });

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
        userId: j['user_id'] as int,
        fullName: j['full_name'] as String,
        userRole: j['user_role'] as String,
        username: j['username'] as String,
        active: (j['active'] as bool?) ?? true,
      );

  Map<String, dynamic> toCreateBody({required String password}) => {
        'full_name': fullName,
        'user_role': userRole,
        'username': username,
        'user_pass': password,
        'active': active,
      };

  Map<String, dynamic> toUpdateBody({String? password}) {
    final body = <String, dynamic>{
      'full_name': fullName,
      'user_role': userRole,
      'username': username,
      'active': active,
    };
    if (password != null) body['user_pass'] = password;
    return body;
  }
}

class UserApiService {
  static const String base = 'http://localhost:8080/api/users';

  static Future<List<UserAccount>> listUsers() async {
    final res = await http.get(Uri.parse(base));
    if (res.statusCode != 200) {
      throw Exception('Failed to load users: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(UserAccount.fromJson).toList();
  }

  static Future<int> createUser(UserAccount user, {required String password}) async {
    final res = await http.post(
      Uri.parse(base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toCreateBody(password: password)),
    );
    if (res.statusCode != 201) {
      throw Exception('Create failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  static Future<void> updateUser(int id, UserAccount user, {String? password}) async {
    final res = await http.put(
      Uri.parse('$base/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toUpdateBody(password: password)),
    );
    if (res.statusCode != 200) {
      throw Exception('Update failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> deleteUser(int id) async {
    final res = await http.delete(Uri.parse('$base/$id'));
    if (res.statusCode != 200) {
      throw Exception('Delete failed: ${res.statusCode} ${res.body}');
    }
  }

  static Future<String> revealPassword({
    required int userId,
    required String adminUsername,
    required String adminPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$base/$userId/reveal-password'),
      headers: {'Content-Type': 'application/json'},
      // backend no longer requires admin fields; send empty body
      body: jsonEncode({}),
    );
    if (res.statusCode != 200) {
      throw Exception('Reveal failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['password'] as String;
  }
}


