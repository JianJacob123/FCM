import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/passenger_screen.dart';
import 'screens/conductor_screen.dart';
import 'models/user_role.dart';
import 'screens/admin_login_screen.dart';
import 'services/notif_socket.dart';
import 'services/notif_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  // must be first line in main
  WidgetsFlutterBinding.ensureInitialized();

  //initialize local notifications once
  await NotifService().initNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FCM Transport',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color.fromRGBO(62, 71, 149, 1),
              brightness: Brightness.light,
            ),
            home: kIsWeb
                ? const AdminLoginScreen()
                : const SplashScreen(), //kIsWeb ? const SplashScreen() : const SplashScreen(), //const AdminLoginScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      _controller.reverse().then((_) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppWrapper(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
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
        child: Center(
          child: Image.asset(
            'assets/icons/splash_icon.png',
            height: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize user data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().initializeUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: const Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
          );
        }

        if (!userProvider.isLoggedIn) {
          return LoginScreen();
        }

        // Show different screens based on user role
        final user = userProvider.currentUser;
        if (user == null) return LoginScreen();

        switch (user.role) {
          case UserRole.passenger:
            SocketService().initSocket(user.id.toString()); // joins usersRoom
            return PassengerScreen();
          case UserRole.conductor:
            SocketService().initSocket(user.id.toString()); // joins usersRoom
            return ConductorScreen();
          default:
            return LoginScreen();
        }
      },
    );
  }
}
