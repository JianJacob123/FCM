import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_role.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _driverPassword = "driver123";
  bool _showDriverLogin = false;

  double _dragStartY = 0;

  void _continueAsPassenger() {
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Passenger',
      role: UserRole.passenger,
    );
    context.read<UserProvider>().loginUser(user);

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppWrapper()));
  }

  void _loginAsDriver() {
    if (_passwordController.text == _driverPassword) {
      final user = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Driver',
        role: UserRole.conductor,
        vehicleId: 'VEH001',
      );
      context.read<UserProvider>().loginUser(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragStart: (details) {
          _dragStartY = details.globalPosition.dy;
        },
        onVerticalDragUpdate: (details) {
          double dragDistance = _dragStartY - details.globalPosition.dy;
          if (dragDistance > 100) {
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
                        text: const TextSpan(
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
