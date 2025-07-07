import 'package:flutter/material.dart';
import 'admin_login_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF3E4795),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF3E4795)),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome, Admin!\nThis is your dashboard.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            color: Color(0xFF3E4795),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 