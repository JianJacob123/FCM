import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/admin_login_screen.dart';
import '../screens/admin_screen.dart';
import '../models/user_role.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FCM Transport Admin',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color.fromRGBO(62, 71, 149, 1),
          brightness: Brightness.light,
        ),
        home: const AdminRoot(),
      ),
    );
  }
}

class AdminRoot extends StatefulWidget {
  const AdminRoot({super.key});

  @override
  State<AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<AdminRoot> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkPersistentLogin();
  }

  Future<void> _checkPersistentLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('admin_user_id');
    final userName = prefs.getString('admin_user_name');

    if (userId != null && userName != null) {
      // ✅ Rebuild admin user model
      final adminUser = UserModel(
        id: userId,
        name: userName,
        role: UserRole.admin,
      );

      // ✅ Store in provider
      context.read<UserProvider>().loginUser(adminUser);

      setState(() {
        _isLoggedIn = true;
      });
    }

    // ✅ Ensure the loading spinner disappears even if not logged in
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(62, 71, 149, 1),
          ),
        ),
      );
    }

    // ✅ Show admin dashboard or login
    return _isLoggedIn ? const AdminScreen() : const AdminLoginScreen();
  }
}
