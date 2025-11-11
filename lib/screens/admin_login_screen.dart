import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'admin_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_role.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

final baseUrl = dotenv.env['API_BASE_URL'];

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  //THIS IS CODE WITH OTP, CHANGE
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Please enter both username and password.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        if (data['user_role'] != 'admin') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Not an admin user.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show OTP dialog
        _showOtpDialog(data['userid'].toString(), data['full_name']);
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

  void _showOtpDialog(String userId, String fullName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _LoginOtpDialog(
          userId: userId,
          fullName: fullName,
          onVerified: () {
            Navigator.of(context).pop(); // close OTP modal
                          // Save user in SharedPreferences
            SharedPreferences.getInstance().then((prefs) async {
                          await prefs.setString('admin_user_id', userId);
                          await prefs.setString('admin_user_name', fullName);
                          await prefs.setString('admin_user_role', 'admin');

                          // Update Provider
                          final user = UserModel(
                            id: userId,
                            name: fullName,
                            role: UserRole.admin,
                          );
                          context.read<UserProvider>().loginUser(user);

                          // Navigate to AdminScreen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AdminScreen(),
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login successful!'),
                              backgroundColor: Colors.green,
                            ),
                          );
            });
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Forgot Password',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email to receive a 6-digit OTP.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) return;

                          setModalState(() => isSending = true);

                          try {
                            print('Sending OTP request to: $baseUrl/users/forgot-password');
                            print('Request body: ${jsonEncode({'username': email})}');

                          final res = await http.post(
                            Uri.parse('$baseUrl/users/forgot-password'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'username': email}),
                          );

                            print('Response status: ${res.statusCode}');
                            print('Response body: ${res.body}');

                          setModalState(() => isSending = false);

                          if (res.statusCode == 200) {
                              final responseData = jsonDecode(res.body);
                            Navigator.of(context).pop(); // close current modal
                              _showOtpVerificationDialog(email);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    responseData['message'] ?? 'OTP sent to your email',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                          } else {
                              final responseBody = res.body;
                              Map<String, dynamic> err;
                              try {
                                err = jsonDecode(responseBody);
                              } catch (e) {
                                err = {'error': responseBody};
                              }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    err['error'] ?? err['message'] ?? 'Failed to send OTP. Status: ${res.statusCode}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSending = false);
                            print('Error sending OTP: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send OTP'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOtpVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _OtpVerificationDialog(email: email, onVerified: (otp) {
          Navigator.of(context).pop(); // close OTP modal
          _showResetPasswordDialog(email, otp); // open password reset modal
        });
      },
    );
  }

  void _showResetPasswordDialog(String email, String otp) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isResetting = false;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    String? passwordError;

    // Password strength validation
    String? validatePassword(String password) {
      if (password.isEmpty) {
        return null; // Don't show error for empty field
      }
      if (password.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (password.length > 128) {
        return 'Password must be at most 128 characters';
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        return 'Password must contain at least one uppercase letter';
      }
      if (!password.contains(RegExp(r'[a-z]'))) {
        return 'Password must contain at least one lowercase letter';
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        return 'Password must contain at least one number';
      }
      if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'Password must contain at least one symbol (!@#\$%^&*...)';
      }
      return null; // Valid password
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Reset Password',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter your new password and confirm it.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      maxLength: 128,
                      onChanged: (value) {
                        setModalState(() {
                          passwordError = validatePassword(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'New Password',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                        errorText: passwordError,
                        errorMaxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      maxLength: 128,
                      decoration: InputDecoration(
                        hintText: 'Re-enter Password',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final newPassword = newPasswordController.text.trim();
                          final confirmPassword = confirmPasswordController.text.trim();

                          if (newPassword.isEmpty || confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Validate password strength
                          final validationError = validatePassword(newPassword);
                          if (validationError != null) {
                            setModalState(() {
                              passwordError = validationError;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(validationError),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setModalState(() => isResetting = true);

                          final resetRes = await http.post(
                            Uri.parse('$baseUrl/users/reset-password'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'username': email,
                              'otp': otp,
                              'newPassword': newPassword,
                            }),
                          );

                          setModalState(() => isResetting = false);

                          if (resetRes.statusCode == 200) {
                            Navigator.of(context).pop(); // close modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            final err = jsonDecode(resetRes.body);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err['error'] ?? 'Failed to reset password'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                  ),
                  child: isResetting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Terms of Service',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 4),
                  Text(
                    'Last Updated: November 6, 2025',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Welcome to the FCM Transport Admin Portal ("we," "our," or "us"). By accessing or using this administrative system, you agree to comply with and be bound by the following Terms of Service. Please read them carefully before using the system.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1. Purpose of the Admin Portal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This administrative portal is designed exclusively for authorized FCM Transport Corporation personnel to manage operations, including but not limited to:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• Managing employee accounts and user roles'),
                  SizedBox(height: 4),
                  Text('• Sending notifications to passengers'),
                  SizedBox(height: 4),
                  Text('• Monitoring vehicle assignments and routes'),
                  SizedBox(height: 4),
                  Text('• Viewing analytics and activity logs'),
                  SizedBox(height: 4),
                  Text('• Accessing system settings and configurations'),
                  SizedBox(height: 16),
                  Text(
                    '2. Acceptance of Terms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'By logging into this admin portal, you acknowledge that you have read, understood, and agreed to these Terms. If you do not agree, please discontinue use immediately and contact your system administrator.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '3. Authorized Access',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Access to this admin portal is restricted to authorized personnel only. You must:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• Use only your assigned credentials'),
                  SizedBox(height: 4),
                  Text('• Not share your login credentials with anyone'),
                  SizedBox(height: 4),
                  Text('• Report any unauthorized access attempts immediately'),
                  SizedBox(height: 4),
                  Text('• Log out when finished using the system'),
                  SizedBox(height: 16),
                  Text(
                    '4. User Responsibilities',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'As an authorized admin user, you are responsible for:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• Maintaining the confidentiality of your account'),
                  SizedBox(height: 4),
                  Text('• Using the system only for legitimate business purposes'),
                  SizedBox(height: 4),
                  Text('• Ensuring data accuracy when entering or modifying information'),
                  SizedBox(height: 4),
                  Text('• Complying with all applicable laws and company policies'),
                  SizedBox(height: 4),
                  Text('• Not attempting to bypass security measures or access unauthorized areas'),
                  SizedBox(height: 16),
                  Text(
                    '5. Data Security and Privacy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'You must handle all data accessed through this portal with the utmost care and in accordance with data protection regulations. Unauthorized disclosure, modification, or deletion of data is strictly prohibited.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '6. System Availability',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'FCM Transport Corporation reserves the right to perform maintenance, updates, or modifications to the system at any time. We strive to minimize disruptions but do not guarantee uninterrupted access.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '7. Limitation of Liability',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'FCM Transport Corporation shall not be held liable for any direct, indirect, or incidental damages resulting from your use of this admin portal, including but not limited to data loss, system errors, or unauthorized access due to credential compromise.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '8. Termination of Access',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'FCM Transport Corporation reserves the right to suspend or terminate your access to this admin portal at any time, with or without notice, if you violate these Terms or engage in any unauthorized or harmful activities.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '9. Changes to These Terms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We may update these Terms of Service from time to time. Continued use of the admin portal after such updates constitutes acceptance of the new terms.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '10. Contact Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'For questions or concerns about these Terms, please contact your system administrator or reach us at:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('📧 support@fcmtransport.com'),
                  Text(
                    '🌐 FCM Transport - Batangas-Bauan Grand Terminal Corporation',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 4),
                  Text(
                    'Last Updated: November 6, 2025',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'At FCM Transport Corporation ("we," "our," or "us"), we are committed to protecting the privacy and security of all data handled through our administrative systems. This Privacy Policy explains how we collect, use, and protect information in the Admin Portal.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1. Information We Collect',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'In the Admin Portal, we collect and process the following information:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• Admin user credentials (username, password)'),
                  SizedBox(height: 4),
                  Text('• Admin user profile information (name, role, email)'),
                  SizedBox(height: 4),
                  Text('• Activity logs and system usage data'),
                  SizedBox(height: 4),
                  Text('• Employee and user account data managed through the portal'),
                  SizedBox(height: 4),
                  Text('• Notification and communication records'),
                  SizedBox(height: 16),
                  Text(
                    '2. How We Use Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We use the collected information to:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• Authenticate and authorize admin users'),
                  SizedBox(height: 4),
                  Text('• Manage system operations and user accounts'),
                  SizedBox(height: 4),
                  Text('• Send notifications and communications'),
                  SizedBox(height: 4),
                  Text('• Monitor system security and detect unauthorized access'),
                  SizedBox(height: 4),
                  Text('• Generate analytics and reports for business operations'),
                  SizedBox(height: 4),
                  Text('• Maintain audit trails for compliance and security purposes'),
                  SizedBox(height: 16),
                  Text(
                    '3. Data Security',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We implement industry-standard security measures to protect data, including:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• Encrypted password storage'),
                  SizedBox(height: 4),
                  Text('• Two-factor authentication (OTP) for admin login'),
                  SizedBox(height: 4),
                  Text('• Secure server infrastructure'),
                  SizedBox(height: 4),
                  Text('• Regular security audits and updates'),
                  SizedBox(height: 4),
                  Text('• Access controls and role-based permissions'),
                  SizedBox(height: 16),
                  Text(
                    '4. Data Sharing',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We do not sell, rent, or share admin portal data with third parties except:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• When required by law or legal process'),
                  SizedBox(height: 4),
                  Text('• To protect our rights, property, or safety'),
                  SizedBox(height: 4),
                  Text('• With service providers who assist in system operations (under strict confidentiality agreements)'),
                  SizedBox(height: 16),
                  Text(
                    '5. Activity Logging',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All admin activities are logged for security and audit purposes. This includes login attempts, data modifications, and system access. These logs are retained in accordance with our data retention policy.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '6. Your Rights',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'As an admin user, you have the right to:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('• Access your account information'),
                  SizedBox(height: 4),
                  Text('• Update your profile and password'),
                  SizedBox(height: 4),
                  Text('• Request information about data we hold about you'),
                  SizedBox(height: 4),
                  Text('• Report security concerns or data breaches'),
                  SizedBox(height: 16),
                  Text(
                    '7. Data Retention',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We retain admin portal data for as long as necessary to fulfill the purposes outlined in this policy, comply with legal obligations, and maintain system security. Activity logs are retained according to our retention schedule.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '8. Updates to This Policy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. Any updates will be posted on this page with a revised "Last Updated" date.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '9. Contact Us',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'For any questions or concerns regarding this Privacy Policy or data handling practices, please contact us at:',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 4),
                  Text('📧 support@fcmtransport.com'),
                  Text(
                    '🌐 FCM Transport - Batangas-Bauan Grand Terminal Corporation',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B73FF), Color(0xFF1A1F3A)],
          ),
        ),
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
        width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: _buildLoginForm(),
        ),
          ),
          // Arc logo at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _buildArcLogo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
          width: 400,
              margin: const EdgeInsets.fromLTRB(32, 80, 32, 32),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: _buildLoginForm(),
        ),
            // Arc logo at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _buildArcLogo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArcLogo() {
    return Container(
      width: 280,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // White arc shape (perfect semicircle)
          CustomPaint(
            size: Size(280, 140),
            painter: _ArcPainter(),
          ),
          // Logo content
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_bus,
                        size: 40,
                        color: const Color(0xFF3E4795),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'FCM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        'TRANSMART',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E4795),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spacer to account for logo
        const SizedBox(height: 20),
        // Header with purple line
        Container(
          width: 60,
          height: 2,
          color: const Color(0xFF3E4795),
          margin: const EdgeInsets.only(bottom: 8),
        ),
        const Text(
          'Login as Admin User',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 32),

        // Username field
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'email',
            hintStyle: const TextStyle(color: Color(0xFF999999)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3E4795)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFF999999),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'password',
            hintStyle: const TextStyle(color: Color(0xFF999999)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3E4795)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF999999),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFF999999),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E4795),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Error message
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
          const SizedBox(height: 16),
        ],

        // Forgot password link
        Center(
          child: TextButton(
            onPressed: () {
              _showForgotPasswordDialog();
            },
            style: ButtonStyle(
              padding: MaterialStateProperty.all(EdgeInsets.zero),
              minimumSize: MaterialStateProperty.all(Size(0, 0)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: MaterialStateProperty.all(
                const Color(0xFF3E4795),
              ),
              overlayColor: MaterialStateProperty.resolveWith<Color?>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.hovered)) {
                  return const Color(0xFF3E4795).withOpacity(0.1);
                }
                if (states.contains(MaterialState.pressed)) {
                  return const Color(0xFF3E4795).withOpacity(0.2);
                }
                return null;
              }),
            ),
            child: const Text(
              'Forget your password?',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3E4795),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Footer
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _showTermsOfService,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Terms of use',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
              const Text(
                '. ',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              TextButton(
                onPressed: _showPrivacyPolicy,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Privacy policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Draw a perfect semicircle (top half of a circle)
    // The arc is the top half of a circle with diameter = width
    final centerX = size.width / 2;
    final radius = size.width / 2;
    
    // Start from bottom left corner
    path.moveTo(0, size.height);
    
    // Draw line to where arc starts (left side of semicircle)
    path.lineTo(0, size.height);
    
    // Draw the arc (top half of circle)
    // The circle center is at (centerX, size.height) and radius is width/2
    // We want the top half, so we start at 180 degrees (left) and sweep 180 degrees (to right)
    path.arcTo(
      Rect.fromCircle(
        center: Offset(centerX, size.height),
        radius: radius,
      ),
      math.pi, // Start angle (180 degrees - left side)
      math.pi, // Sweep angle (180 degrees - half circle, going counterclockwise)
      false, // largeArc
    );
    
    // Close the path back to start
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _OtpVerificationDialog extends StatefulWidget {
  final String email;
  final Function(String) onVerified;

  const _OtpVerificationDialog({
    required this.email,
    required this.onVerified,
  });

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  int _secondsRemaining = 120; // 2 minutes
  bool _isVerifying = false;
  bool _hasError = false;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '').split('').take(6).toList();
      for (int i = 0; i < digits.length && (index + i) < 6; i++) {
        _controllers[index + i].text = digits[i];
        if (i < digits.length - 1 && (index + i + 1) < 6) {
          _focusNodes[index + i + 1].requestFocus();
        }
      }
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Check if all fields are filled - auto verify OTP
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6 && !_isVerifying) {
      _verifyOtp(otp);
    }

    setState(() {
      _hasError = false;
    });
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    try {
      print('Verifying OTP: $otp for email: ${widget.email}');
      
      // Try to verify OTP first - check if there's a verify endpoint
      // If not, we'll need to verify during password reset
      final verifyRes = await http.post(
        Uri.parse('$baseUrl/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.email,
          'otpCode': otp,
        }),
      );

      print('Verify OTP response status: ${verifyRes.statusCode}');
      print('Verify OTP response body: ${verifyRes.body}');

      setState(() {
        _isVerifying = false;
      });

      if (verifyRes.statusCode == 200) {
        final verifyData = jsonDecode(verifyRes.body);
        if (verifyData['status'] == 'success' || verifyData['success'] == true) {
          // OTP is valid, proceed to password reset
          widget.onVerified(otp);
        } else {
          setState(() {
            _hasError = true;
            // Clear all fields
            for (var controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                verifyData['message'] ?? verifyData['error'] ?? 'Invalid OTP',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _hasError = true;
          // Clear all fields
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
        final err = jsonDecode(verifyRes.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['error'] ?? err['message'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      setState(() {
        _hasError = true;
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying OTP: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _canResend = false;
      _secondsRemaining = 120;
      _hasError = false;
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    });

    _timer?.cancel();
    _startTimer();

    try {
      print('Resending OTP request to: $baseUrl/users/forgot-password');
      print('Request body: ${jsonEncode({'username': widget.email})}');
      
      final res = await http.post(
        Uri.parse('$baseUrl/users/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.email}),
      );

      print('Resend response status: ${res.statusCode}');
      print('Resend response body: ${res.body}');

      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'OTP sent successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final responseBody = res.body;
        Map<String, dynamic> err;
        try {
          err = jsonDecode(responseBody);
        } catch (e) {
          err = {'error': responseBody};
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err['error'] ?? err['message'] ?? 'Failed to send OTP. Status: ${res.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error resending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Verification code',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the 6-digit code sent to your email.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          // OTP Input Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 5 ? 8 : 0),
                child: SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _hasError ? Colors.red : Colors.black,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError
                            ? Colors.red
                            : _focusNodes[index].hasFocus
                                ? const Color(0xFF3E4795)
                                : Colors.grey[300]!,
                        width: _focusNodes[index].hasFocus ? 2 : 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError
                            ? Colors.red
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF3E4795),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (value) => _onDigitChanged(index, value),
                  onTap: () {
                    _controllers[index].selection = TextSelection.fromPosition(
                      TextPosition(offset: _controllers[index].text.length),
                    );
                  },
                ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Error message
          if (_hasError)
            const Text(
              'The code you entered is incorrect. Please try again.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          if (_hasError) const SizedBox(height: 16),
          // Timer
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatTime(_secondsRemaining),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _canResend ? Colors.grey[600] : const Color(0xFF3E4795),
              ),
            ),
          ),
          // Resend code (only shown when timer is done)
          if (_canResend) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive a code? ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: _resendCode,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3E4795),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying || _getOtp().length != 6
              ? null
              : () => _verifyOtp(_getOtp()),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getOtp().length == 6 && !_isVerifying
                ? const Color(0xFF3E4795)
                : Colors.grey[300],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _hasError ? 'Try Again' : 'Verify',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

class _LoginOtpDialog extends StatefulWidget {
  final String userId;
  final String fullName;
  final VoidCallback onVerified;

  const _LoginOtpDialog({
    required this.userId,
    required this.fullName,
    required this.onVerified,
  });

  @override
  State<_LoginOtpDialog> createState() => _LoginOtpDialogState();
}

class _LoginOtpDialogState extends State<_LoginOtpDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  int _secondsRemaining = 120; // 2 minutes
  bool _isVerifying = false;
  bool _hasError = false;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '').split('').take(6).toList();
      for (int i = 0; i < digits.length && (index + i) < 6; i++) {
        _controllers[index + i].text = digits[i];
        if (i < digits.length - 1 && (index + i + 1) < 6) {
          _focusNodes[index + i + 1].requestFocus();
        }
      }
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Check if all fields are filled - auto verify OTP
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6 && !_isVerifying) {
      _verifyOtp(otp);
    }

    setState(() {
      _hasError = false;
    });
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    try {
      final verifyRes = await http.post(
        Uri.parse('$baseUrl/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": widget.userId,
          "otpCode": otp,
        }),
      );

      setState(() {
        _isVerifying = false;
      });

      if (verifyRes.statusCode == 200) {
        final verifyData = jsonDecode(verifyRes.body);

        if (verifyData['status'] == 'success') {
          widget.onVerified();
        } else {
          setState(() {
            _hasError = true;
            // Clear all fields
            for (var controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          });
          // Error is shown inline in the dialog, no SnackBar needed
        }
      } else {
        setState(() {
          _hasError = true;
          // Clear all fields
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
        // Error is shown inline in the dialog, no SnackBar needed
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _canResend = false;
      _secondsRemaining = 120;
      _hasError = false;
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    });

    _timer?.cancel();
    _startTimer();

    try {
      // Resend OTP by calling login again (which triggers OTP send)
      // Note: This might require the username/password, but since we're in OTP dialog,
      // we might need a separate resend endpoint. For now, show a message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please try logging in again to receive a new OTP'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Two-Factor Authentication',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the 6-digit code sent to your email.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          // OTP Input Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 5 ? 8 : 0),
                child: SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _hasError ? Colors.red : Colors.black,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _hasError
                              ? Colors.red
                              : _focusNodes[index].hasFocus
                                  ? const Color(0xFF3E4795)
                                  : Colors.grey[300]!,
                          width: _focusNodes[index].hasFocus ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _hasError
                              ? Colors.red
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF3E4795),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onDigitChanged(index, value),
                    onTap: () {
                      _controllers[index].selection = TextSelection.fromPosition(
                        TextPosition(offset: _controllers[index].text.length),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Error message
          if (_hasError)
            const Text(
              'The code you entered is incorrect. Please try again.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          if (_hasError) const SizedBox(height: 16),
          // Timer
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatTime(_secondsRemaining),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _canResend ? Colors.grey[600] : const Color(0xFF3E4795),
              ),
            ),
          ),
          // Resend code (only shown when timer is done)
          if (_canResend) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive a code? ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: _resendCode,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3E4795),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying || _getOtp().length != 6
              ? null
              : () => _verifyOtp(_getOtp()),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getOtp().length == 6 && !_isVerifying
                ? const Color(0xFF3E4795)
                : Colors.grey[300],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _hasError ? 'Try Again' : 'Verify',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ),
      ],
    );
  }
}
