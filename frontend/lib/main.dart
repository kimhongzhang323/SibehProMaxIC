import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'id_page.dart';
import 'services_page.dart';
import 'chat_page.dart';
import 'landing_page.dart';
import 'notification_page.dart'; // Contains NotificationService
import 'profile_page.dart';
import 'splash_page.dart';
import 'onboarding_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        colorScheme: ColorScheme.fromSeed(
            
            seedColor: Colors.black, brightness: Brightness.light),
        fontFamily: 'SF Pro Display',
      ),
      home: const AppWrapper(),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _showLanding = true;
  bool _showVerification = false;
  bool _showSplash = false;

  String? _cachedUserName;

  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final landingSeen = prefs.getBool('landing_page_seen') ?? false;
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final cachedName = prefs.getString('cached_user_name');
    final shouldShowSplash = landingSeen && onboardingComplete;

    if (!mounted) return;
    setState(() {
      _cachedUserName = cachedName;
      // If not logged in (onboarding incomplete), show landing. 
      // User might be "returning" (cachedName exists) but logged out.
      _showLanding = !onboardingComplete; 
      _showVerification = landingSeen && !onboardingComplete && cachedName == null; // Only show verification if in middle of onboarding? Simpler: Just Landing -> Onboarding
      // actually, if logged out, onboarding_complete is false (cleared in logout?). 
      // Wait, logout clears 'onboarding_complete'. So !onboardingComplete is true.
      // So _showLanding = true. Correct.
      
      _showSplash = shouldShowSplash;
      _isLoading = false;
    });

    if (shouldShowSplash) {
      _startSplashTimer();
    }
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _showSplash = false;
      });
    });
  }

  Future<void> _completeLanding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('landing_page_seen', true);
    if (!mounted) return;
    setState(() {
      _showLanding = false;
      _showVerification = true;
    });
  }

  Future<void> _handleLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('landing_page_seen', true);
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    setState(() {
      _showLanding = false;
      _showVerification = false;
      _showSplash = true;
    });
    _startSplashTimer();
  }



  void _goBackToLanding() {
    setState(() {
      _showVerification = false;
      _showLanding = true;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    setState(() {
      _showVerification = false;
      _showSplash = true;
    });
    _startSplashTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            
            child:
               
                CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
      );
    }

    if (_showLanding) {
      return LandingPage(
        onSignUp: _completeLanding,
        onLogin: _handleLogin,
        cachedUserName: _cachedUserName,
      );
    }

    if (_showVerification) {
      return OnboardingPage(
        onComplete: _completeOnboarding,
        onBack: _goBackToLanding,
      );
    }

    if (_showSplash) {
      return const SplashPage();
    }

    return const MainLayout();
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const IdPage(),
    const ServicesPage(),
    const NotificationPage(),
    const ChatPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Removed AnimatedSwitcher to simplify state retention test
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding slightly
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better spacing for 5 items
              children: [
                _buildNavItem(0, Icons.wallet_outlined, Icons.wallet, 'Home'),
                _buildNavItem(1, Icons.grid_view_outlined, Icons.grid_view, 'Services'),
                
                // AnimatedBuilder to listen for notification updates
                AnimatedBuilder(
                  animation: NotificationService(),
                  builder: (context, _) {
                    final unreadCount = NotificationService().unreadCount;
                    return _buildNavItem(
                      2, 
                      Icons.notifications_outlined, 
                      Icons.notifications, 
                      'Inbox',
                      badgeCount: unreadCount
                    );
                  }
                ),

                _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Assistant'),
                 _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? activeIcon : icon,
                    color: isSelected ? Colors.black : Colors.grey[400], size: 26),
                
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey[400],
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
