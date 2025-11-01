import 'dart:ui';
import 'package:flutter/material.dart';
import 'admin_login_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _currentIndex = 0;
  double _homePageScrollOffset = 0.0;

  List<Widget> get _pages => [
    HomePage(
      onScrollUpdate: (offset) {
        setState(() {
          _homePageScrollOffset = offset;
        });
      },
    ),
    const AboutPage(),
    const ContactPage(),
  ];

  void _navigateToMap() {
    // Navigate to login screen where users can continue as passenger
    // This ensures providers are properly initialized
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  // Get navbar color based on current page and scroll position
  Color _getNavBarColor() {
    switch (_currentIndex) {
      case 0: // HomePage
        // When scrolled (background is white), make navbar solid blue
        // Use same transition length as background (500 pixels)
        const double transitionLength = 500.0;
        final double scrollProgress = (_homePageScrollOffset / transitionLength).clamp(0.0, 1.0);
        // Start transparent (0.3 opacity) when at top, become fully solid (1.0) when scrolled
        final double opacity = 0.3 + (scrollProgress * 0.7);
        // When opacity is high (close to 1.0), return solid color
        if (opacity >= 0.95) {
          return const Color(0xFF5C5C8A);
        }
        return Color(0xFF5C5C8A).withOpacity(opacity);
      case 1: // AboutPage - light background, solid
        return const Color(0xFF5C5C8A);
      case 2: // ContactPage - light background, solid
        return const Color(0xFF5C5C8A);
      default:
        return const Color(0xFF5C5C8A);
    }
  }

  // Get navbar blur intensity based on current page and scroll position
  double _getNavBarBlur() {
    switch (_currentIndex) {
      case 0: // HomePage
        // Reduce blur as we scroll (when background becomes white)
        // Use same transition length as background (500 pixels)
        const double transitionLength = 500.0;
        final double scrollProgress = (_homePageScrollOffset / transitionLength).clamp(0.0, 1.0);
        // Start with blur, remove blur completely when over white background
        if (scrollProgress >= 0.95) {
          return 0.0;
        }
        return 10.0 * (1.0 - scrollProgress);
      case 1: // AboutPage - light background, no blur needed
      case 2: // ContactPage - light background, no blur needed
        return 0.0;
      default:
        return 10.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
              child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: _getNavBarBlur() > 0
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: _getNavBarBlur(), sigmaY: _getNavBarBlur()),
                      child: _buildNavBarContainer(),
                    )
                  : _buildNavBarContainer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarContainer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _getNavBarColor(),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Image.asset(
              'assets/logo2.png',
              height: 70,
              width: 70,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 55,
                );
              },
            ),
            // Navigation Links - spread evenly
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavLink(
                    text: 'Home',
                    isActive: _currentIndex == 0,
                    onTap: () => setState(() {
                      _currentIndex = 0;
                      _homePageScrollOffset = 0.0;
                    }),
                  ),
                  _NavLink(
                    text: 'Map',
                    isActive: false,
                    onTap: () {}, // Static - no navigation
                  ),
                  _NavLink(
                    text: 'About Us',
                    isActive: _currentIndex == 1,
                    onTap: () => setState(() {
                      _currentIndex = 1;
                      _homePageScrollOffset = 0.0;
                    }),
                  ),
                  _NavLink(
                    text: 'Contact',
                    isActive: _currentIndex == 2,
                    onTap: () => setState(() {
                      _currentIndex = 2;
                      _homePageScrollOffset = 0.0;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? const Color(0xFFA0A0E0) : const Color(0xFFE0E0E0),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(double)? onScrollUpdate;
  
  const HomePage({super.key, this.onScrollUpdate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
      // Notify parent of scroll position
      if (widget.onScrollUpdate != null) {
        widget.onScrollUpdate!(_scrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Calculate background opacity based on scroll position
  double _getBackgroundOpacity() {
    // Transition over 500 pixels of scroll
    const double transitionLength = 500.0;
    final double opacity = (_scrollOffset / transitionLength).clamp(0.0, 1.0);
    return 1.0 - opacity; // Fade out from 1.0 to 0.0
  }

  @override
  Widget build(BuildContext context) {
    final double bgOpacity = _getBackgroundOpacity();
    
    return Stack(
      children: [
        // White background (shown as image fades)
        Positioned.fill(
          child: Container(
            color: Colors.white,
          ),
        ),
        // Background Image with Gradient Overlay
        Positioned.fill(
          child: Opacity(
            opacity: bgOpacity,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(62, 71, 149, 0.9),
              ),
              child: Stack(
                children: [
                  // Background image with error handling
                  Positioned.fill(
                    child: Image.asset(
                      'assets/bg.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color.fromRGBO(62, 71, 149, 1),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.12, 0.24, 0.39, 0.65, 0.85, 0.97],
                        colors: [
                          const Color(0xFFFFFFFF).withOpacity(1.0 * 0.7),    // 0% - White - 70%
                          const Color(0xFF7680D9).withOpacity(0.96 * 0.7),   // 12% - #7680D9 - 67.2%
                          const Color(0xFF555DA3).withOpacity(0.98 * 0.7),    // 24% - #555DA3 - 68.6%
                          const Color(0xFF3E4795).withOpacity(0.98 * 0.7),    // 39% - #3E4795 - 68.6%
                          const Color(0xFF293385).withOpacity(1.0 * 0.7),     // 65% - #293385 - 70%
                          const Color(0xFF020A4B).withOpacity(1.0 * 0.7),     // 85% - #020A4B - 70%
                          const Color(0xFF00073D).withOpacity(1.0 * 0.7),    // 97% - #00073D - 70%
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Scrollable Content
        SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Hero Content
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FCM Transport Services Corporation',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "You're reliable Transport Service",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              shadows: [
                                Shadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: null, // Static button - no action for now
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(62, 71, 149, 1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                              disabledBackgroundColor: const Color.fromRGBO(62, 71, 149, 1),
                              disabledForegroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Track FCM Units',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.play_arrow, size: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Why Choose Us Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why Choose FCM Transport',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(62, 71, 149, 1),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.access_time,
                              title: 'On-Time Service',
                              description: 'We prioritize punctuality to ensure you reach your destination on schedule.',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.security,
                              title: 'Safe & Reliable',
                              description: 'Your safety is our top priority with well-maintained vehicles and trained drivers.',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.track_changes,
                              title: 'Real-Time Tracking',
                              description: 'Track your bus in real-time and know exactly when it will arrive.',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Download App Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromRGBO(62, 71, 149, 1),
                        const Color.fromRGBO(41, 51, 133, 1),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Download Our App',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Track buses in real-time, view schedules, and plan your journey all in one place.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AppDownloadButton(
                            icon: Icons.phone_android,
                            text: 'Google Play',
                            onTap: () {},
                          ),
                          const SizedBox(width: 20),
                          _AppDownloadButton(
                            icon: Icons.phone_iphone,
                            text: 'App Store',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  width: double.infinity,
                  color: const Color(0xFF2A2A2A),
                  child: Column(
                    children: [
                      // Main Footer Content
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                        child: Column(
                          children: [
                            // Top Section: Company Info and Quick Links
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Company Information
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'FCM Transport Corporation',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Committed to safe, reliable, and modern public transport services across Southern Luzon.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                                // Quick Links
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Quick Links',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _FooterLink(
                                        text: 'Home',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const AdminLoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      _FooterLink(
                                        text: 'Routes & Map',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const AdminLoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      _FooterLink(
                                        text: 'About Us',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const AdminLoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      _FooterLink(
                                        text: 'Contact',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const AdminLoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      _FooterLink(
                                        text: 'Download App',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const AdminLoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                                // Contact Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Contact Us',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _ContactDetail(
                                        text: 'FCM Transport Terminal, Poblacion, Bauang, La Union',
                                      ),
                                      const SizedBox(height: 8),
                                      _ContactDetail(
                                        text: 'info@fcmtransport.com',
                                      ),
                                      const SizedBox(height: 30),
                                      // Follow Us Section
                                      const Text(
                                        'Follow Us',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _SocialMediaButton(icon: Icons.facebook, onTap: () {}),
                                          const SizedBox(width: 12),
                                          _SocialMediaButton(icon: Icons.photo_camera, onTap: () {}), // Instagram
                                          const SizedBox(width: 12),
                                          _SocialMediaButton(icon: Icons.close, onTap: () {}), // Twitter/X
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Copyright Notice
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AdminLoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                '© 2025 FCM Transport Corporation. All rights reserved.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Text(
                                  ' | ',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;

  const _StatCard({
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: const Color.fromRGBO(62, 71, 149, 1),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(62, 71, 149, 1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

class _ContactDetail extends StatelessWidget {
  final String text;

  const _ContactDetail({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[300],
        height: 1.4,
      ),
    );
  }
}

class _SocialMediaButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialMediaButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _AppDownloadButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _AppDownloadButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color.fromRGBO(62, 71, 149, 1),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: const Color.fromRGBO(62, 71, 149, 1),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 100.0, left: 40.0, right: 40.0, bottom: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About FCM Transport',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'FCM Transport is committed to providing reliable, efficient, and safe public transportation services to our community. We strive to connect people with their destinations while maintaining the highest standards of service quality.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Our Vision',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To become the leading public transportation provider by leveraging technology and innovation to enhance passenger experience and operational efficiency.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'What We Offer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 16),
            _BulletPoint(text: 'Real-time bus tracking and arrival predictions'),
            _BulletPoint(text: 'Comprehensive route management system'),
            _BulletPoint(text: 'Advanced analytics and forecasting capabilities'),
            _BulletPoint(text: 'Efficient vehicle and driver assignment'),
            _BulletPoint(text: 'Passenger-friendly mobile application'),
            const SizedBox(height: 40),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color.fromRGBO(62, 71, 149, 1),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bus_alert,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need Help?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact our support team for assistance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color.fromRGBO(62, 71, 149, 1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 100.0, left: 40.0, right: 40.0, bottom: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 40),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _ContactItem(
                      icon: Icons.email,
                      title: 'Email',
                      content: 'admin@fcmapp.com',
                      onTap: () {
                        // Handle email tap
                      },
                    ),
                    const Divider(),
                    _ContactItem(
                      icon: Icons.phone,
                      title: 'Phone',
                      content: '+1 (555) 123-4567',
                      onTap: () {
                        // Handle phone tap
                      },
                    ),
                    const Divider(),
                    _ContactItem(
                      icon: Icons.location_on,
                      title: 'Address',
                      content: '123 Transport Street\nCity, State 12345',
                      onTap: () {
                        // Handle address tap
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Office Hours',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _OfficeHourRow(day: 'Monday - Friday', hours: '8:00 AM - 6:00 PM'),
                    const Divider(),
                    _OfficeHourRow(day: 'Saturday', hours: '9:00 AM - 4:00 PM'),
                    const Divider(),
                    _OfficeHourRow(day: 'Sunday', hours: 'Closed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Send Us a Message',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(62, 71, 149, 1),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Your Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message sent successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(62, 71, 149, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Send Message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color.fromRGBO(62, 71, 149, 1),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(62, 71, 149, 1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeHourRow extends StatelessWidget {
  final String day;
  final String hours;

  const _OfficeHourRow({
    required this.day,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

