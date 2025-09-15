import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _guestId;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  String? get guestId => _guestId;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Initialize user from stored preferences
  Future<void> initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load guest ID
      String? storedGuestId = prefs.getString('guest_id');
      if (storedGuestId == null) {
        storedGuestId = const Uuid().v4();
        await prefs.setString('guest_id', storedGuestId);
      }
      _guestId = storedGuestId;

      // Load logged-in user if exists
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
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
      // ✅ FIX: use jsonEncode, not .toString()
      await prefs.setString('user', jsonEncode(user.toJson()));
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
