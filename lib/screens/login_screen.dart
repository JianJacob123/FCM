import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_role.dart';
import 'passenger_screen.dart';
import 'conductor_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrl = dotenv.env['API_BASE_URL'];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _showDriverLogin = false;

  double _dragStartY = 0;

  void _continueAsPassenger() {
    final guestId = context
        .read<UserProvider>()
        .guestId!; // safe because init ensures it
    final user = UserModel(
      id: guestId,
      name: 'Passenger',
      role: UserRole.passenger,
    );
    context.read<UserProvider>().loginUser(user);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PassengerScreen()),
    );
  }

  Future<void> _loginAsDriver() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your username and password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 1. Call your backend
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'), // change to your endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"username": username, "password": password}),
      );

      // 2. Check if successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'];

        if (data['user_role'].toString().toLowerCase() != 'conductor') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Not a conductor.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // 3. Build user from backend response
        final user = UserModel(
          id: data['user_id'].toString(),
          name: data['full_name'],
          role: data['user_role'].toString().toLowerCase() == 'conductor'
              ? UserRole.conductor
              : UserRole.passenger,
        );

        // 4. Store in provider
        context.read<UserProvider>().loginUser(user);

        // 5. Navigate to appropriate screen based on role
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => user.role == UserRole.conductor
                ? const ConductorScreen()
                : const PassengerScreen(),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? 'Login failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (err) {
      print("Login error: $err");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -20) {
            _continueAsPassenger();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8EA2F8), Color(0xFF3E4795)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/splash_icon.png',
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Swipe up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8EA2F8),
                                fontSize: 32,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: ' to start\ncatching your ride.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 28,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: _continueAsPassenger,
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.keyboard_double_arrow_up,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_showDriverLogin)
                Positioned(
                  right: 24,
                  bottom: 32,
                  child: TextButton(
                    onPressed: () => setState(() => _showDriverLogin = true),
                    child: const Text(
                      'Login as Driver/Conductor',
                      style: TextStyle(
                        color: Color(0xFF8EA2F8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (_showDriverLogin)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Driver/Conductor Login',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E4795),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _loginAsDriver,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3E4795),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Login'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => setState(
                                      () => _showDriverLogin = false,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
