import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Initialize user from stored preferences
  Future<void> initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        final userData = Map<String, dynamic>.from(
          userJson as Map<String, dynamic>
        );
        _currentUser = UserModel.fromJson(userData);
      }
    } catch (e) {
      print('Error loading user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login user
  Future<void> loginUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', user.toJson().toString());
      _currentUser = user;
    } catch (e) {
      print('Error saving user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Switch user role
  Future<void> switchRole(UserRole newRole) async {
    if (_currentUser == null) return;

    final newUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      role: newRole,
      vehicleId: newRole == UserRole.conductor ? 'VEH001' : null,
    );

    await loginUser(newUser);
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      _currentUser = null;
    } catch (e) {
      print('Error logging out: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
} 