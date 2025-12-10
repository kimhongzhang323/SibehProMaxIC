import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // import shared_preferences
import 'widgets/glassy_button.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onSignUp;
  final VoidCallback onLogin;
  final String? cachedUserName;

  const LandingPage({
    super.key, 
    required this.onSignUp, 
    required this.onLogin,
    this.cachedUserName,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isScanning = false;
  // Local state to handle "Use another account" content switch
  bool _showQuickLogin = true; 

  @override
  void initState() {
    super.initState();
    _showQuickLogin = widget.cachedUserName != null; // Default to quick login if name exists
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }
  
  // Method to clear cached user
  Future<void> _clearCachedUser() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_name');
      setState(() {
        _showQuickLogin = false;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildGlow(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 36),
                        const SizedBox(height: 36),
                        const Spacer(),
                        if (_showQuickLogin && widget.cachedUserName != null)
                             _buildWelcomeBackUI()
                        else
                             _buildStandardUI(),
                        const Spacer(),
                      ],
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

  Widget _buildStandardUI() {
    return Column(
      children: [
        _buildTextStack(),
        const SizedBox(height: 32),
        _buildSignUpButton(),
        const SizedBox(height: 16),
        _buildLoginButton(),
      ],
    );
  }

  Widget _buildWelcomeBackUI() {
    return Column(
      children: [
         Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome back,',
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.cachedUserName!,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        GlassyButton(
          onPressed: _handleLogin,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
               Icon(Icons.face, color: Colors.black87),
               SizedBox(width: 12),
               Text(
                'Quick Login',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _clearCachedUser, 
          child: Text(
            'Use another account',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlow() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            width: 360,
            height: 360,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFFB4D0),
                  Color(0xFF8ED6FF),
                  Color(0xFFE7C8FF),
                  Colors.transparent,
                ],
                stops: [0.1, 0.4, 0.65, 1.0],
                center: Alignment.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextStack() {
    return Column(
      children: [
        Text(
          'Journey',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Get started with a modern, glassy experience.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return GlassyButton(
      onPressed: widget.onSignUp,
      borderRadius: BorderRadius.circular(16),
      child: const Text(
        'Sign Up',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _handleLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black26, width: 1.5),
        ),
        child: const Center(
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    setState(() => _isScanning = true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildFaceScanDialog(),
    );

    setState(() => _isScanning = false);
  }

  Widget _buildFaceScanDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.face,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Face Recognition',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scanning your face...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 2000)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Future.microtask(() {
                    Navigator.of(context).pop();
                    widget.onLogin();
                  });
                  return const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
