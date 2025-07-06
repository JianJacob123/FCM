import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/passenger_screen.dart';
import 'screens/conductor_screen.dart';
import 'models/user_role.dart';

void main() => runApp(MyApp());

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
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: const Color.fromRGBO(62, 71, 149, 1),
              scaffoldBackgroundColor: const Color(0xFF181A20),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF23242B),
                foregroundColor: Colors.white,
              ),
              colorScheme: ColorScheme.dark(
                primary: const Color.fromRGBO(62, 71, 149, 1),
                secondary: Colors.blueGrey,
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: AppWrapper(),
          );
        },
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
            return PassengerScreen();
          case UserRole.conductor:
            return ConductorScreen();
          default:
            return LoginScreen();
        }
      },
    );
  }
}
