import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/download.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _currentIndex = 0;
  double _homePageScrollOffset = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  VoidCallback? _scrollToAbout;
  VoidCallback? _scrollToTop;
  bool _aboutInView = false;

  // Helper method to check screen size
  bool _isMobileScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  List<Widget> get _pages => [
    HomePage(
      onScrollUpdate: (offset) {
        setState(() {
          _homePageScrollOffset = offset;
        });
      },
      onAboutInViewChanged: (inView) {
        if (_currentIndex == 0 && _aboutInView != inView) {
          setState(() {
            _aboutInView = inView;
          });
        }
      },
      onAboutScrollReady: (scrollCallback) {
        _scrollToAbout = scrollCallback;
      },
      onTopScrollReady: (scrollCallback) {
        _scrollToTop = scrollCallback;
      },
      onNavigateToMap: () {
        setState(() {
          _currentIndex = 3; // MapPage is at index 3
        });
      },
    ),
    const AboutPage(),
    const ContactPage(),
    const MapPage(),
  ];

  void _navigateToMap() {
    // Navigate to login screen where users can continue as passenger
    // This ensures providers are properly initialized
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Get navbar color based on current page and scroll position
  Color _getNavBarColor() {
    switch (_currentIndex) {
      case 0: // HomePage
        // When scrolled (background is white), make navbar solid blue
        // Use same transition length as background (500 pixels)
        const double transitionLength = 500.0;
        final double scrollProgress = (_homePageScrollOffset / transitionLength)
            .clamp(0.0, 1.0);
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
      case 3: // MapPage - light background, solid
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
        final double scrollProgress = (_homePageScrollOffset / transitionLength)
            .clamp(0.0, 1.0);
        // Start with blur, remove blur completely when over white background
        if (scrollProgress >= 0.95) {
          return 0.0;
        }
        return 10.0 * (1.0 - scrollProgress);
      case 1: // AboutPage - light background, no blur needed
      case 2: // ContactPage - light background, no blur needed
      case 3: // MapPage - light background, no blur needed
        return 0.0;
      default:
        return 10.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobileScreen(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Stack(
        children: [
          // Main content
          IndexedStack(index: _currentIndex, children: _pages),
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
                      filter: ImageFilter.blur(
                        sigmaX: _getNavBarBlur(),
                        sigmaY: _getNavBarBlur(),
                      ),
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
    final isMobile = _isMobileScreen(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isMobile ? 60 : 75,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 8 : 12,
          ),
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
              children: [
                // Logo (click to go Home and scroll to top)
                InkWell(
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                      _homePageScrollOffset = 0.0;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToTop?.call();
                    });
                  },
                  child: Image.asset(
                    'assets/logo2.png',
                    height: isMobile ? 45 : 70,
                    width: isMobile ? 45 : 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: isMobile ? 35 : 55,
                      );
                    },
                  ),
                ),
                // Navigation Links - show hamburger on mobile, full nav on desktop
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  )
                else
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 32),
                        _NavLink(
                          text: 'Home',
                          isActive: _currentIndex == 0 && !_aboutInView,
                          onTap: () => setState(() {
                            _currentIndex = 0;
                            _homePageScrollOffset = 0.0;
                            // Scroll to top when already on home
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToTop?.call();
                            });
                          }),
                        ),
                        const SizedBox(width: 48),
                        _NavLink(
                          text: 'About',
                          isActive:
                              (_currentIndex == 0 && _aboutInView) ||
                              _currentIndex == 1,
                          onTap: () {
                            // If on home page, scroll to About section
                            if (_currentIndex == 0 && _scrollToAbout != null) {
                              _scrollToAbout!();
                            } else {
                              // Otherwise, switch to home page and scroll
                              setState(() {
                                _currentIndex = 0;
                              });
                              // Wait for page to switch, then scroll
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollToAbout != null) {
                                  _scrollToAbout!();
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 48),
                        _NavLink(
                          text: 'Map',
                          isActive: _currentIndex == 3,
                          onTap: () => setState(() {
                            _currentIndex = 3;
                            _homePageScrollOffset = 0.0;
                          }),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF5C5C8A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          Container(
            height: 120,
            decoration: const BoxDecoration(color: Color(0xFF5C5C8A)),
            child: SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/logo2.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 50,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'FCM Transport',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          // Menu Items
          _DrawerItem(
            icon: Icons.home,
            title: 'Home',
            isActive: _currentIndex == 0,
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = 0;
                _homePageScrollOffset = 0.0;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToTop?.call();
                });
              });
            },
          ),
          _DrawerItem(
            icon: Icons.info,
            title: 'About',
            isActive: _currentIndex == 1,
            onTap: () {
              Navigator.of(context).pop();
              // If on home page, scroll to About section
              if (_currentIndex == 0 && _scrollToAbout != null) {
                _scrollToAbout!();
              } else {
                // Otherwise, switch to home page and scroll
                setState(() {
                  _currentIndex = 0;
                });
                // Wait for page to switch, then scroll
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollToAbout != null) {
                    _scrollToAbout!();
                  }
                });
              }
            },
          ),
          _DrawerItem(
            icon: Icons.map,
            title: 'Map',
            isActive: _currentIndex == 3,
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = 3;
                _homePageScrollOffset = 0.0;
              });
            },
          ),
        ],
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
    return _Hoverable(
      builder: (hover) => InkWell(
        onTap: onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: isActive
                ? const Color(0xFFA0A0E0)
                : (hover ? Colors.white : const Color(0xFFE0E0E0)),
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            decoration: hover && !isActive
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

class _Hoverable extends StatefulWidget {
  final Widget Function(bool isHovered) builder;
  const _Hoverable({required this.builder});
  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.builder(_hover),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFFA0A0E0) : Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFFA0A0E0) : Colors.white,
          fontSize: 18,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.white.withOpacity(0.1),
      onTap: onTap,
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(double)? onScrollUpdate;
  final Function(VoidCallback)? onAboutScrollReady;
  final Function(VoidCallback)? onTopScrollReady;
  final VoidCallback? onNavigateToMap;
  final Function(bool)? onAboutInViewChanged;

  const HomePage({
    super.key,
    this.onScrollUpdate,
    this.onAboutScrollReady,
    this.onTopScrollReady,
    this.onNavigateToMap,
    this.onAboutInViewChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _aboutSectionKey = GlobalKey();
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
      // Notify about section visibility
      if (widget.onAboutInViewChanged != null) {
        final ctx = _aboutSectionKey.currentContext;
        if (ctx != null) {
          final box = ctx.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final pos = box.localToGlobal(Offset.zero);
            final size = box.size;
            final height = MediaQuery.of(context).size.height;
            final bool inView =
                pos.dy < height * 0.6 && pos.dy + size.height > height * 0.2;
            widget.onAboutInViewChanged!(inView);
          }
        }
      }
    });

    // Register scroll to about method with parent
    if (widget.onAboutScrollReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAboutScrollReady!(() {
          final context = _aboutSectionKey.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }

    // Register scroll to top method with parent
    if (widget.onTopScrollReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTopScrollReady!(() {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Terms of Service'),
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
                    'Welcome to the official website of FCM Transport Corporation ("we," "our," or "us"). By accessing or using this website, you agree to comply with and be bound by the following Terms of Service. Please read them carefully before using the site.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1. Purpose of the Website',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This website provides general information about FCM Transport Corporation, including our company background, transport services, and a real-time bus tracking feature through the “Map” section. The website is for informational and public service purposes only.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '2. Acceptance of Terms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'By browsing or using any part of this website, you acknowledge that you have read, understood, and agreed to these Terms. If you do not agree, please discontinue use immediately.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '3. Use of the Website',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'You agree to use this website responsibly and only for lawful purposes. You must not attempt to gain unauthorized access to any part of the site or its servers; interfere with or disrupt the site’s operation; or use the website’s content or data for commercial or malicious purposes.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '4. Accuracy of Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We strive to keep all content, including route and bus location information, accurate and up to date. However, data shown on the Map (such as active buses and estimated positions) may vary due to network delays or technical limitations. FCM Transport Corporation makes no guarantees regarding accuracy or availability.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '5. Intellectual Property Rights',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All content found on this website—including text, graphics, logos, and designs—is the property of FCM Transport Corporation and protected under applicable copyright and trademark laws. You may not reproduce, modify, or distribute any materials without prior written consent.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '6. Limitation of Liability',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'FCM Transport Corporation shall not be held liable for any direct, indirect, or incidental damages resulting from your access to or use of this website. Use of the Map and any transport data is at your own discretion and risk.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '7. External Links',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This website may contain links to third-party websites for convenience. We are not responsible for the content, accuracy, or policies of those external sites.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '8. Changes to the Website and Terms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We may update or modify website content and these Terms of Service at any time without prior notice. Continued use of the site after updates constitutes acceptance of the new terms.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '9. Contact Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'For questions or concerns about these Terms, you may reach us at:',
                  ),
                  SizedBox(height: 4),
                  Text('📧 info@fcmtransport.com'),
                  Text(
                    '🌐 FCM Transport - Batangas-Bauan Grand Terminal Corporation facebook page',
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
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Privacy Policy'),
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
                    'At FCM Transport Corporation ("we," "our," or "us"), we value your privacy and are committed to maintaining a safe and transparent online experience. This Privacy Policy explains how we handle information when you visit our website.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1. Information We Collect',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We do not collect, store, or process any personal information from visitors. Our website does not include contact forms, registration pages, or features that request user data.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '2. Non-Personal Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We do not use cookies, tracking technologies, or analytics tools that gather personally identifiable data. However, basic, anonymous server logs (such as visit counts or general browser types) may be automatically recorded by our hosting provider for site performance and security purposes. These logs do not identify individual visitors.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '3. Use of Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Since we do not collect personal data, there is no user information to process, analyze, or share.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '4. Data Sharing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We do not sell, rent, or share any visitor data with third parties.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '5. External Links',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Our website may contain links to other websites, such as app download pages or social media platforms. We are not responsible for the content or privacy practices of those external sites. We encourage you to review their respective privacy policies when visiting them.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '6. Data Security',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Although we do not collect personal data, our website is hosted on secure servers that use standard security measures to prevent unauthorized access or misuse of the site.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '7. Updates to This Policy',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'We may update this Privacy Policy from time to time to reflect changes in our website or legal requirements. Any updates will be posted on this page with a revised “Last Updated” date.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    '8. Contact Us',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'For any questions or concerns regarding this Privacy Policy, you may contact us at:',
                  ),
                  SizedBox(height: 4),
                  Text('📧 fcmtransport@gmail.com'),
                  Text(
                    '🌐 FCM Transport - Batangas-Bauan Grand Terminal Corporation facebook page',
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

  // Calculate background opacity based on scroll position
  double _getBackgroundOpacity() {
    // Transition over 500 pixels of scroll
    const double transitionLength = 500.0;
    final double opacity = (_scrollOffset / transitionLength).clamp(0.0, 1.0);
    return 1.0 - opacity; // Fade out from 1.0 to 0.0
  }

  // Responsive helper methods
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  double _getResponsiveFontSize(
    BuildContext context,
    double desktop,
    double tablet,
    double mobile,
  ) {
    if (_isMobile(context)) return mobile;
    if (_isTablet(context)) return tablet;
    return desktop;
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600)
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0);
    if (width < 1024)
      return const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0);
    return const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0);
  }

  Widget _buildTrackButton(BuildContext context) {
    return InkWell(
      onTap: widget.onNavigateToMap ?? () {}, // Navigate to map page
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5C5C8A).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Track FCM Units',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.play_arrow, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return InkWell(
      onTap: () => _showDownloadAppModal(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5C5C8A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Download App',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.smartphone, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showDownloadAppModal(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          content: SizedBox(
            width: screenWidth < 600 ? screenWidth * 0.9 : 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get the FCM Transport App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(62, 71, 149, 1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The FCM Transport mobile app is currently supported on Android devices only. For iOS users, the map and tracking features are available via the Map section of this website.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Stack buttons vertically on mobile, horizontally on desktop
            if (isMobile)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close modal
                        widget.onNavigateToMap?.call(); // Navigate to MapPage
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        elevation: 0,
                      ),
                      icon: Image.asset(
                        'assets/apple.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.phone_iphone, size: 20);
                        },
                      ),
                      label: const Text(
                        'Go to Map',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final url =
                            (dotenv.env['ANDROID_APK_URL'] ?? '').isNotEmpty
                            ? dotenv.env['ANDROID_APK_URL']!
                            : '/downloads/app-release.apk';
                        if (url.isNotEmpty) {
                          downloadFromUrl(url, filename: 'fcm_app.apk');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ANDROID_APK_URL not set.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C5C8A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.phone,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Download for Android',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Go to Map Page button with Apple icon
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close modal
                      widget.onNavigateToMap?.call(); // Navigate to MapPage
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      elevation: 0,
                    ),
                    icon: Image.asset(
                      'assets/apple.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.phone_iphone, size: 20);
                      },
                    ),
                    label: const Text(
                      'Go to Map Page',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Download App button with Android icon
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final url =
                          (dotenv.env['ANDROID_APK_URL'] ?? '').isNotEmpty
                          ? dotenv.env['ANDROID_APK_URL']!
                          : '/downloads/app-release.apk';
                      if (url.isNotEmpty) {
                        downloadFromUrl(url, filename: 'fcm_app.apk');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ANDROID_APK_URL not set.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5C8A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/android.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.phone_android,
                          size: 20,
                          color: Colors.white,
                        );
                      },
                    ),
                    label: const Text(
                      'Download for Android',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bgOpacity = _getBackgroundOpacity();

    return Stack(
      children: [
        // White background (shown as image fades)
        Positioned.fill(child: Container(color: Colors.white)),
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
                          const Color(
                            0xFFFFFFFF,
                          ).withOpacity(1.0 * 0.7), // 0% - White - 70%
                          const Color(
                            0xFF7680D9,
                          ).withOpacity(0.96 * 0.7), // 12% - #7680D9 - 67.2%
                          const Color(
                            0xFF555DA3,
                          ).withOpacity(0.98 * 0.7), // 24% - #555DA3 - 68.6%
                          const Color(
                            0xFF3E4795,
                          ).withOpacity(0.98 * 0.7), // 39% - #3E4795 - 68.6%
                          const Color(
                            0xFF293385,
                          ).withOpacity(1.0 * 0.7), // 65% - #293385 - 70%
                          const Color(
                            0xFF020A4B,
                          ).withOpacity(1.0 * 0.7), // 85% - #020A4B - 70%
                          const Color(
                            0xFF00073D,
                          ).withOpacity(1.0 * 0.7), // 97% - #00073D - 70%
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
                      width: MediaQuery.of(context).size.width * 0.72,
                      padding: _getResponsivePadding(context),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'FCM Transport Services Corporation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(
                                context,
                                56,
                                42,
                                32,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Your reliable transport service from Bauan to Lipa",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(
                                context,
                                28,
                                22,
                                18,
                              ),
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
                          _isMobile(context)
                              ? Column(
                                  children: [
                                    _buildTrackButton(context),
                                    const SizedBox(height: 12),
                                    _buildDownloadButton(context),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(child: _buildTrackButton(context)),
                                    const SizedBox(width: 16),
                                    Flexible(
                                      child: _buildDownloadButton(context),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                // About Our Services Section
                Container(
                  width: double.infinity,
                  padding: _getResponsivePadding(context),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What we offer?',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 36, 28, 24),
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(62, 71, 149, 1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quick facts about the services we provide every day.',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 18, 16, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _isMobile(context)
                          ? Column(
                              children: [
                                _ServiceCard(
                                  icon: Icons.directions_bus,
                                  iconColor: const Color(0xFF5C5C8A),
                                  title: 'Fleet Size',
                                  description:
                                      'A total of 15 modern air-conditioned buses operate daily between Bauan and Lipa.',
                                ),
                                const SizedBox(height: 20),
                                _ServiceCard(
                                  icon: Icons.access_time,
                                  iconColor: const Color(0xFF9C27B0),
                                  title: 'Service Hours',
                                  description:
                                      'Bauan → Lipa: 4:30 AM – 7:00 PM\nLipa → Bauan: 6:00 AM – 8:00 PM',
                                ),
                                const SizedBox(height: 20),
                                _ServiceCard(
                                  icon: Icons.verified_user,
                                  iconColor: const Color(0xFF2196F3),
                                  title: 'Safety First',
                                  description:
                                      'Operated by certified professional drivers trained in safety and passenger care.',
                                ),
                                const SizedBox(height: 20),
                                _ServiceCard(
                                  icon: Icons.accessible,
                                  iconColor: const Color(0xFF2196F3),
                                  title: 'Accessibility',
                                  description:
                                      'Spacious seating and well-maintained interiors ensure a comfortable ride throughout your journey.',
                                ),
                                const SizedBox(height: 20),
                                _ServiceCard(
                                  icon: Icons.local_offer,
                                  iconColor: const Color(0xFF5C5C8A),
                                  title: 'Affordable Fares',
                                  description:
                                      'Budget-friendly rates with discounts for students, seniors, and PWD.',
                                ),
                                const SizedBox(height: 20),
                                _ServiceCard(
                                  icon: Icons.air,
                                  iconColor: const Color(0xFF2196F3),
                                  title: 'On-board Amenities',
                                  description:
                                      'Air-conditioned buses on all trips for a cool and convenient travel experience.',
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ServiceCard(
                                        icon: Icons.directions_bus,
                                        iconColor: const Color(0xFF5C5C8A),
                                        title: 'Fleet Size',
                                        description:
                                            'A total of 15 modern air-conditioned buses operate daily between Bauan and Lipa.',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _ServiceCard(
                                        icon: Icons.access_time,
                                        iconColor: const Color(0xFF9C27B0),
                                        title: 'Service Hours',
                                        description:
                                            'Bauan → Lipa: 4:30 AM – 7:00 PM\nLipa → Bauan: 6:00 AM – 8:00 PM',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _ServiceCard(
                                        icon: Icons.verified_user,
                                        iconColor: const Color(0xFF2196F3),
                                        title: 'Safety First',
                                        description:
                                            'Operated by certified professional drivers trained in safety and passenger care.',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ServiceCard(
                                        icon: Icons.accessible,
                                        iconColor: const Color(0xFF2196F3),
                                        title: 'Accessibility',
                                        description:
                                            'Spacious seating and well-maintained interiors ensure a comfortable ride throughout your journey.',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _ServiceCard(
                                        icon: Icons.local_offer,
                                        iconColor: const Color(0xFF5C5C8A),
                                        title: 'Affordable Fares',
                                        description:
                                            'Budget-friendly rates with discounts for students, seniors, and PWD.',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _ServiceCard(
                                        icon: Icons.air,
                                        iconColor: const Color(0xFF2196F3),
                                        title: 'On-board Amenities',
                                        description:
                                            'Air-conditioned buses on all trips for a cool and convenient travel experience.',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                // Why Choose Us Section
                Container(
                  width: double.infinity,
                  padding: _getResponsivePadding(context),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why Choose FCM Transport',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 36, 28, 24),
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(62, 71, 149, 1),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.access_time,
                              title: 'On-Time Service',
                              description:
                                  'We prioritize punctuality to ensure you reach your destination on schedule.',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.security,
                              title: 'Safe & Reliable',
                              description:
                                  'Your safety is our top priority with well-maintained vehicles and trained drivers.',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _FeatureItem(
                              icon: Icons.track_changes,
                              title: 'Real-Time Tracking',
                              description:
                                  'Track your bus in real-time and know exactly when it will arrive.',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // About FCM Transport Section
                Container(
                  key: _aboutSectionKey,
                  width: double.infinity,
                  padding: _getResponsivePadding(context),
                  color: Colors.white,
                  child: _isMobile(context)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About FCM Transport',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(
                                  context,
                                  36,
                                  28,
                                  24,
                                ),
                                fontWeight: FontWeight.bold,
                                color: const Color.fromRGBO(62, 71, 149, 1),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'FCM Transport Batangas-Bauan-Grand Terminal Corporation is dedicated to providing modern and reliable public transportation services in Batangas. In partnership with Hino Batangas, we launched 15 Hino Modern Public Utility Vehicles (PUVs) featuring ergonomic seating, efficient air-conditioning, and robust safety systems.',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(
                                  context,
                                  16,
                                  15,
                                  14,
                                ),
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Our vision is to offer better transport services to Bauan and neighboring areas, supported by the Land Transportation Franchising and Regulatory Board (LTFRB) Region IV and the local government of Batangas. We aim to improve commuting between Bauan and Lipa, creating opportunities for work, business, and leisure.',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(
                                  context,
                                  16,
                                  15,
                                  14,
                                ),
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'This partnership with Hino reflects FCM Transport\'s commitment to innovation and our goal of providing safe, sustainable, and world-class mobility solutions.',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(
                                  context,
                                  16,
                                  15,
                                  14,
                                ),
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Image
                            Container(
                              height: 300,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/3d.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.bus_alert,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text content on the left
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About FCM Transport',
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        36,
                                        28,
                                        24,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(
                                        62,
                                        71,
                                        149,
                                        1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'FCM Transport Batangas-Bauan-Grand Terminal Corporation is dedicated to providing modern and reliable public transportation services in Batangas. In partnership with Hino Batangas, we launched 15 Hino Modern Public Utility Vehicles (PUVs) featuring ergonomic seating, efficient air-conditioning, and robust safety systems.',
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        16,
                                        15,
                                        14,
                                      ),
                                      color: Colors.grey[700],
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Our vision is to offer better transport services to Bauan and neighboring areas, supported by the Land Transportation Franchising and Regulatory Board (LTFRB) Region IV and the local government of Batangas. We aim to improve commuting between Bauan and Lipa, creating opportunities for work, business, and leisure.',
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        16,
                                        15,
                                        14,
                                      ),
                                      color: Colors.grey[700],
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'This partnership with Hino reflects FCM Transport\'s commitment to innovation and our goal of providing safe, sustainable, and world-class mobility solutions.',
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        16,
                                        15,
                                        14,
                                      ),
                                      color: Colors.grey[700],
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 40),
                            // Image on the right
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/3d.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.bus_alert,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                // Mission and Vision Section
                Container(
                  width: double.infinity,
                  padding: _getResponsivePadding(context),
                  color: Colors.white,
                  child: _isMobile(context)
                      ? Column(
                          children: [
                            // Vision Card
                            _Hoverable(
                              builder: (hover) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  transform: Matrix4.identity()
                                    ..translate(0.0, hover ? -4.0 : 0.0),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: hover
                                          ? const Color(
                                              0xFF3E4795,
                                            ).withOpacity(0.2)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          hover ? 0.12 : 0.08,
                                        ),
                                        blurRadius: hover ? 14 : 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Our Vision',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            28,
                                            24,
                                            22,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromRGBO(
                                            62,
                                            71,
                                            149,
                                            1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'To be the most trusted and modern transport service in Batangas—connecting communities with reliable, comfortable, and inclusive mobility.',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            16,
                                            15,
                                            14,
                                          ),
                                          color: Colors.grey[700],
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            // Mission Card
                            _Hoverable(
                              builder: (hover) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  transform: Matrix4.identity()
                                    ..translate(0.0, hover ? -4.0 : 0.0),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: hover
                                          ? const Color(
                                              0xFF3E4795,
                                            ).withOpacity(0.2)
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          hover ? 0.12 : 0.08,
                                        ),
                                        blurRadius: hover ? 14 : 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Our Mission',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            28,
                                            24,
                                            22,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromRGBO(
                                            62,
                                            71,
                                            149,
                                            1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Provide safe, efficient, and customer-focused public transport through well-maintained vehicles, trained personnel, and continuous innovation—delivering value to riders and supporting sustainable growth across Bauan, Lipa, and neighboring areas.',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            16,
                                            15,
                                            14,
                                          ),
                                          color: Colors.grey[700],
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Vision Card
                              Expanded(
                                child: _Hoverable(
                                  builder: (hover) {
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOut,
                                      transform: Matrix4.identity()
                                        ..translate(0.0, hover ? -4.0 : 0.0),
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hover
                                              ? const Color(
                                                  0xFF3E4795,
                                                ).withOpacity(0.2)
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              hover ? 0.12 : 0.08,
                                            ),
                                            blurRadius: hover ? 14 : 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Our Vision',
                                            style: TextStyle(
                                              fontSize: _getResponsiveFontSize(
                                                context,
                                                28,
                                                24,
                                                22,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromRGBO(
                                                62,
                                                71,
                                                149,
                                                1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'To be the most trusted and modern transport service in Batangas—connecting communities with reliable, comfortable, and inclusive mobility.',
                                            style: TextStyle(
                                              fontSize: _getResponsiveFontSize(
                                                context,
                                                16,
                                                15,
                                                14,
                                              ),
                                              color: Colors.grey[700],
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Mission Card
                              Expanded(
                                child: _Hoverable(
                                  builder: (hover) {
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOut,
                                      transform: Matrix4.identity()
                                        ..translate(0.0, hover ? -4.0 : 0.0),
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hover
                                              ? const Color(
                                                  0xFF3E4795,
                                                ).withOpacity(0.2)
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              hover ? 0.12 : 0.08,
                                            ),
                                            blurRadius: hover ? 14 : 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Our Mission',
                                            style: TextStyle(
                                              fontSize: _getResponsiveFontSize(
                                                context,
                                                28,
                                                24,
                                                22,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromRGBO(
                                                62,
                                                71,
                                                149,
                                                1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Provide safe, efficient, and customer-focused public transport through well-maintained vehicles, trained personnel, and continuous innovation—delivering value to riders and supporting sustainable growth across Bauan, Lipa, and neighboring areas.',
                                            style: TextStyle(
                                              fontSize: _getResponsiveFontSize(
                                                context,
                                                16,
                                                15,
                                                14,
                                              ),
                                              color: Colors.grey[700],
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                // Download App Section
                Container(
                  width: double.infinity,
                  padding: _getResponsivePadding(context),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Our App',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 36, 28, 24),
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(62, 71, 149, 1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isMobile(context)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/app.png',
                                    height: 260,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Stay connected and informed with real-time tracking of FCM Transport units through our mobile app.',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      18,
                                      16,
                                      14,
                                    ),
                                    color: Colors.grey[700],
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 800,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        _BulletPoint(
                                          text:
                                              'Track active FCM buses along the Bauan–Lipa route in real time',
                                        ),
                                        _BulletPoint(
                                          text:
                                              'View estimated arrival times to plan your trip better',
                                        ),
                                        _BulletPoint(
                                          text:
                                              'Save your favorite locations for quick access',
                                        ),
                                        _BulletPoint(
                                          text:
                                              'Receive instant updates directly from our operators',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Experience smart, convenient, and reliable commuting—anytime, anywhere.',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      16,
                                      15,
                                      14,
                                    ),
                                    color: Colors.grey[700],
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Currently available for Android users only.',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                      14,
                                      13,
                                    ),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showDownloadAppModal(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3E4795),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  icon: const Icon(
                                    Icons.android,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Download App',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // QR container (mobile)
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/FCM App.png',
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 24.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/app.png',
                                        height: 360,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const SizedBox.shrink();
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Stay connected and informed with real-time tracking of FCM Transport units through our mobile app.',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            18,
                                            16,
                                            14,
                                          ),
                                          color: Colors.grey[700],
                                          height: 1.6,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 800,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            _BulletPoint(
                                              text:
                                                  'Track active FCM buses along the Bauan–Lipa route in real time',
                                            ),
                                            _BulletPoint(
                                              text:
                                                  'View estimated arrival times to plan your trip better',
                                            ),
                                            _BulletPoint(
                                              text:
                                                  'Save your favorite locations for quick access',
                                            ),
                                            _BulletPoint(
                                              text:
                                                  'Receive instant updates directly from our operators',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Experience smart, convenient, and reliable commuting—anytime, anywhere.',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            16,
                                            15,
                                            14,
                                          ),
                                          color: Colors.grey[700],
                                          height: 1.6,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Currently available for Android users only.',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            14,
                                            14,
                                            13,
                                          ),
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _showDownloadAppModal(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF3E4795,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 4,
                                        ),
                                        icon: const Icon(
                                          Icons.android,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Download App',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  width: double.infinity,
                  color: const Color(0xFF5C5C8A),
                  child: Column(
                    children: [
                      // Main Footer Content
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40.0,
                          vertical: 60.0,
                        ),
                        child: Column(
                          children: [
                            // Top Section: Company Info, Links, Contact, QR
                            _isMobile(context)
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Company Information
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                      const SizedBox(height: 24),
                                      // Quick Links
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              if (_scrollController
                                                  .hasClients) {
                                                _scrollController.animateTo(
                                                  0,
                                                  duration: const Duration(
                                                    milliseconds: 500,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                              }
                                            },
                                          ),
                                          _FooterLink(
                                            text: 'Map',
                                            onTap: () {
                                              if (widget.onNavigateToMap !=
                                                  null) {
                                                widget.onNavigateToMap!();
                                              }
                                            },
                                          ),
                                          _FooterLink(
                                            text: 'About',
                                            onTap: () {
                                              final ctx = _aboutSectionKey
                                                  .currentContext;
                                              if (ctx != null) {
                                                Scrollable.ensureVisible(
                                                  ctx,
                                                  duration: const Duration(
                                                    milliseconds: 500,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                              }
                                            },
                                          ),
                                          _FooterLink(
                                            text: 'Download App',
                                            onTap: () {
                                              _showDownloadAppModal(context);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Contact
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          const _ContactDetail(
                                            text:
                                                'Makalintal Ave, Bauan, Batangas',
                                            icon: Icons.location_on,
                                          ),
                                          const SizedBox(height: 8),
                                          const _ContactDetail(
                                            text: 'info@fcmtransport.com',
                                            icon: Icons.email,
                                          ),
                                          const SizedBox(height: 20),
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
                                              _SocialMediaButton(
                                                icon: Icons.facebook,
                                                onTap: () {
                                                  launchUrlString(
                                                    'https://www.facebook.com/profile.php?id=100094508181738',
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // QR box
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: 220,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/FCM App.png',
                                                width: 160,
                                                height: 160,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'FCM App for Android',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF3E4795),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Company Information
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                if (_scrollController
                                                    .hasClients) {
                                                  _scrollController.animateTo(
                                                    0,
                                                    duration: const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                  );
                                                }
                                              },
                                            ),
                                            _FooterLink(
                                              text: 'Map',
                                              onTap: () {
                                                if (widget.onNavigateToMap !=
                                                    null) {
                                                  widget.onNavigateToMap!();
                                                }
                                              },
                                            ),
                                            _FooterLink(
                                              text: 'About',
                                              onTap: () {
                                                final ctx = _aboutSectionKey
                                                    .currentContext;
                                                if (ctx != null) {
                                                  Scrollable.ensureVisible(
                                                    ctx,
                                                    duration: const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                  );
                                                }
                                              },
                                            ),
                                            _FooterLink(
                                              text: 'Download App',
                                              onTap: () {
                                                _showDownloadAppModal(context);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                      // Contact Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              text:
                                                  'Makalintal Ave, Bauan, Batangas',
                                              icon: Icons.location_on,
                                            ),
                                            const SizedBox(height: 8),
                                            _ContactDetail(
                                              text: 'info@fcmtransport.com',
                                              icon: Icons.email,
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
                                                _SocialMediaButton(
                                                  icon: Icons.facebook,
                                                  onTap: () {
                                                    launchUrlString(
                                                      'https://www.facebook.com/profile.php?id=100094508181738',
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // QR container (desktop)
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            width: 260,
                                            height: 260,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/FCM App.png',
                                                  width: 200,
                                                  height: 200,
                                                  fit: BoxFit.contain,
                                                ),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  'FCM App for Android',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF3E4795),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      // Copyright Notice
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40.0,
                          vertical: 20.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Builder(
                          builder: (context) {
                            final bool isMobile =
                                MediaQuery.of(context).size.width < 600;
                            final copyright = InkWell(
                              onTap: () {
                                //Removed link to FCM site
                              },
                              child: Text(
                                '© 2025 FCM Transport Corporation. All rights reserved.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            );

                            final links = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: _showPrivacyPolicy,
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
                                  onPressed: _showTermsOfService,
                                  child: Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Center(child: copyright),
                                  const SizedBox(height: 8),
                                  links,
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [copyright, links],
                            );
                          },
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

class _ScheduleCard extends StatelessWidget {
  final String route;
  final String firstTrip;
  final String lastTrip;

  const _ScheduleCard({
    required this.route,
    required this.firstTrip,
    required this.lastTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First Trip',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstTrip,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Trip',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastTrip,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
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
    return _Hoverable(
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: hover
            ? (Matrix4.identity()..translate(0.0, -4.0, 0.0))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hover ? 0.18 : 0.08),
              blurRadius: hover ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: hover
              ? Border.all(color: const Color(0xFF3E4795).withOpacity(0.15))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color.fromRGBO(62, 71, 149, 1)),
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
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _ServiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _Hoverable(
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, hover ? -4.0 : 0.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hover
                ? const Color(0xFF3E4795).withOpacity(0.15)
                : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hover ? 0.12 : 0.08),
              blurRadius: hover ? 14 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(62, 71, 149, 1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.grey[300]),
        ),
      ),
    );
  }
}

class _ContactDetail extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _ContactDetail({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final content = Text(
      text,
      style: TextStyle(fontSize: 14, color: Colors.grey[300], height: 1.4),
    );
    if (icon == null) return content;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: content),
      ],
    );
  }
}

class _SocialMediaButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialMediaButton({required this.icon, required this.onTap});

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
        child: Icon(icon, color: Colors.white, size: 24),
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
            Icon(icon, size: 32, color: const Color.fromRGBO(62, 71, 149, 1)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color.fromRGBO(62, 71, 149, 1)),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
        padding: const EdgeInsets.only(
          top: 100.0,
          left: 40.0,
          right: 40.0,
          bottom: 40.0,
        ),
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
            _BulletPoint(
              text: 'Real-time bus tracking and arrival predictions',
            ),
            _BulletPoint(text: 'Comprehensive route management system'),
            _BulletPoint(
              text: 'Advanced analytics and forecasting capabilities',
            ),
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
                    const Icon(Icons.bus_alert, size: 48, color: Colors.white),
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
        padding: const EdgeInsets.only(
          top: 100.0,
          left: 40.0,
          right: 40.0,
          bottom: 40.0,
        ),
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
                    _OfficeHourRow(
                      day: 'Monday - Friday',
                      hours: '8:00 AM - 6:00 PM',
                    ),
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
            Icon(icon, size: 32, color: const Color.fromRGBO(62, 71, 149, 1)),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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

  const _OfficeHourRow({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(hours, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// MapPage - Same map implementation as admin live tracking
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late IO.Socket vehicleSocket;
  final Map<int, Marker> _vehicleMarkers = {};
  Map<String, dynamic>? _selectedVehicle;
  List<LatLng> _routePolyline = [];
  final MapController _mapController = MapController();
  bool _showVehicleInfo = false;

  @override
  void initState() {
    super.initState();
    final baseUrl = dotenv.env['API_BASE_URL'];
    vehicleSocket = IO.io(
      "$baseUrl/vehicles",
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    vehicleSocket.connect();
    vehicleSocket.onConnect((_) {
      print('Connected to vehicle backend');
      vehicleSocket.emit("subscribeVehicles");
    });
    vehicleSocket.on('vehicleUpdate', (data) {
      if (!mounted) return;
      setState(() {
        for (var v in data) {
          final id = v["vehicle_id"];
          final lat = double.parse(v["lat"].toString());
          final lng = double.parse(v["lng"].toString());
          _vehicleMarkers[id] = Marker(
            point: LatLng(lat, lng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVehicle = v;
                  _showVehicleInfo = true;
                  _routePolyline = [];
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3E4795),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    });
    vehicleSocket.onDisconnect((_) {
      print('Vehicle disconnected');
    });
  }

  @override
  void dispose() {
    vehicleSocket.off('vehicleUpdate');
    vehicleSocket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: const LatLng(13.945, 121.163),
              zoom: 14,
              onTap: (tapPosition, point) {
                setState(() {
                  _showVehicleInfo = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePolyline,
                    strokeWidth: 4.0,
                    color: const Color(0xFF3E4795),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_routePolyline.isNotEmpty)
                    Marker(
                      point: _routePolyline.last,
                      width: 30,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF3E4795),
                        size: 32,
                      ),
                    ),
                  ..._vehicleMarkers.values.toList(),
                ],
              ),
            ],
          ),
          if (_showVehicleInfo && _selectedVehicle != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 400,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FCM No. ${_selectedVehicle?["vehicle_id"] ?? "Unknown"}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E4795),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _showVehicleInfo = false;
                              _selectedVehicle = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedVehicle?["route_name"] ?? "Unknown"}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          _selectedVehicle?["is_off_route"] == true
                              ? 'Off Route'
                              : 'On Route',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedVehicle?["is_off_route"] == true
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Animated progress bar
                    if (_selectedVehicle != null &&
                        _selectedVehicle!["route_progress_percent"] != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.2,
                          end:
                              ((double.tryParse(
                                            _selectedVehicle!["route_progress_percent"]
                                                .toString(),
                                          ) ??
                                          0) /
                                      100)
                                  .clamp(0.0, 1.0), //clamp after dividing
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            color: const Color(0xFF3E4795),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Time of Arrival',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          _selectedVehicle != null &&
                                  _selectedVehicle!['eta'] != null
                              ? DateFormat.jm().format(
                                  DateTime.parse(
                                    _selectedVehicle!['eta'],
                                  ).toLocal(),
                                )
                              : '--:--',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Capacity',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${_selectedVehicle?["current_passenger_count"] ?? "--"}/20',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Plate Number",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '${_selectedVehicle?["plate_number"] ?? "---"}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final remainingRoute =
                                _selectedVehicle?["remaining_route_polyline"];

                            if (remainingRoute == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No route data available."),
                                ),
                              );
                              return;
                            }

                            // Decode JSON string into a Map
                            final routeJson = remainingRoute is String
                                ? jsonDecode(remainingRoute)
                                : remainingRoute;

                            final coords =
                                (routeJson["coordinates"] as List?)
                                    ?.map(
                                      (c) => LatLng(
                                        (c[1] as num).toDouble(),
                                        (c[0] as num).toDouble(),
                                      ),
                                    )
                                    .toList() ??
                                [];

                            if (coords.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No route data available."),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _routePolyline = coords;
                            });
                          },
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text(
                            'Track Trip',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
