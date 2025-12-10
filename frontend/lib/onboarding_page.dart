import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/glassy_button.dart';


class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;
  
  const OnboardingPage({super.key, required this.onComplete, this.onBack});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isProcessing = false;
  late AnimationController _pageController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // IC Data (editable)
  Map<String, String> _icData = {};
  bool _icValidated = false;
  
  // Passport Data
  Map<String, String> _passportData = {};
  bool _passportSkipped = false;
  bool _passportScanned = false;
  bool _hasMismatch = false;
  List<String> _mismatchFields = [];
  
  // Biometric
  bool _fingerprintDone = false;
  bool _faceIdDone = false;

  // Text Controllers for editing
  final _nameController = TextEditingController();
  final _icNumberController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );
    
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _icNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _changeStep(int newStep) {
    _pageController.reset();
    setState(() {
      _currentStep = newStep;
    });
    _pageController.forward();
  }

  void _simulateIcScan() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Mock IC data retrieved from scan
    setState(() {
      _icData = {
        'name': 'TAN AH KOW',
        'ic_number': '900101-14-1234',
        'address': '123, Jalan Example, 50000 Kuala Lumpur',
        'dob': '01-01-1990',
        'gender': 'Male',
      };
      _nameController.text = _icData['name']!;
      _icNumberController.text = _icData['ic_number']!;
      _addressController.text = _icData['address']!;
      _isProcessing = false;
      _changeStep(1); // Go to validation step
    });
  }

  void _validateIcData() {
    // Update IC data with edited values
    _icData['name'] = _nameController.text.trim();
    _icData['ic_number'] = _icNumberController.text.trim();
    _icData['address'] = _addressController.text.trim();
    
    setState(() {
      _icValidated = true;
      _changeStep(2); // Go to passport step
    });
  }

  void _simulatePassportScan() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Mock passport data (intentionally slightly different for demo)
    _passportData = {
      'name': 'TAN AH KOW',  // Same
      'passport_number': 'A12345678',
      'nationality': 'MALAYSIA',
      'dob': '01-01-1990',  // Same
    };
    
    // Check for mismatches with IC data
    _mismatchFields = [];
    if (_passportData['name'] != _icData['name']) {
      _mismatchFields.add('Name');
    }
    if (_passportData['dob'] != _icData['dob']) {
      _mismatchFields.add('Date of Birth');
    }
    
    setState(() {
      _isProcessing = false;
      _passportScanned = true;
      _hasMismatch = _mismatchFields.isNotEmpty;
      if (!_hasMismatch) {
        _changeStep(3); // Proceed to biometric
      }
      // If mismatch, stay on passport step to show warning
    });
  }

  void _skipPassport() {
    setState(() {
      _passportSkipped = true;
      _changeStep(3); // Go to biometric
    });
  }

  void _proceedDespiteMismatch() {
    // User acknowledges mismatch, proceed without updating IC data
    setState(() {
      _changeStep(3);
    });
  }

  void _goBackToEditIc() {
    // Go back to IC validation to fix the mismatch
    setState(() {
      _hasMismatch = false;
      _passportScanned = false;
      _changeStep(1); // Back to IC validation
    });
  }

  void _simulateBiometric(String type) async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() {
      _isProcessing = false;
      if (type == 'fingerprint') {
        _fingerprintDone = true;
      } else if (type == 'face') {
        _faceIdDone = true;
      }
      if (_fingerprintDone && _faceIdDone) {
        _changeStep(4); // Complete
      }
    });
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildTopBar(),
                    const SizedBox(height: 32),
                    _buildProgressBar(),
                    const SizedBox(height: 40),
                    Expanded(child: _buildCurrentStep()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.onBack != null)
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.black87,
              size: 22,
            ),
          )
        else
          const SizedBox(width: 26),
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.black87, size: 22),
            const SizedBox(width: 6),
            Text(
              'Journey',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(width: 26),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(5, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent 
                  ? Colors.black87
                  : Colors.black12,
              borderRadius: BorderRadius.circular(2),
              boxShadow: (isCompleted || isCurrent)
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildIcScanStep();
      case 1: return _buildIcValidationStep();
      case 2: return _buildPassportStep();
      case 3: return _buildBiometricStep();
      case 4: return _buildCompleteStep();
      default: return _buildIcScanStep();
    }
  }

  Widget _buildIcScanStep() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: _isProcessing
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.black87,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  Icons.credit_card,
                  size: 70,
                  color: Colors.black54,
                ),
        ),
        const SizedBox(height: 40),
        Text(
          'Scan Your IC',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Place your MyKad on a flat surface',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        const Spacer(),
        GlassyButton(
          onPressed: _isProcessing ? null : _simulateIcScan,
          borderRadius: BorderRadius.circular(16),
          child: Text(
            _isProcessing ? 'Scanning...' : 'Start Scanning',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildIcValidationStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Verify Your Details',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please verify and edit if needed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          _buildEditableField('Full Name', _nameController, Icons.person),
          _buildEditableField('IC Number', _icNumberController, Icons.badge),
          _buildEditableField('Address', _addressController, Icons.home, maxLines: 2),
          
          // Non-editable fields
          _buildReadOnlyField('Date of Birth', _icData['dob'] ?? '', Icons.calendar_today),
          _buildReadOnlyField('Gender', _icData['gender'] ?? '', Icons.wc),
          
          const SizedBox(height: 32),
          GlassyButton(
            onPressed: _validateIcData,
            borderRadius: BorderRadius.circular(16),
            child: const Text(
              'Confirm Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              cursorColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.lock, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportStep() {
    // If mismatch detected, show warning
    if (_hasMismatch && _passportScanned) {
      return Column(
        children: [
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 56,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Data Mismatch Detected',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The following fields differ between your IC and Passport:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_mismatchFields.map((field) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            field,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ))),
                    const SizedBox(height: 16),
                    Text(
                      'Passport data will not update your IC details. Please update your IC first if needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          GlassyButton(
            onPressed: _proceedDespiteMismatch,
            borderRadius: BorderRadius.circular(16),
            child: const Text(
              'Continue Anyway',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _goBackToEditIc,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text(
              'Go Back to Edit IC',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      children: [
        const Spacer(),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: _isProcessing
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.black87,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  Icons.menu_book,
                  size: 70,
                  color: Colors.black54,
                ),
        ),
        const SizedBox(height: 40),
        Text(
          'Scan Passport',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Optional: Add passport for international travel',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            'IC data is locked after validation',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        GlassyButton(
          onPressed: _isProcessing ? null : _simulatePassportScan,
          borderRadius: BorderRadius.circular(16),
          child: Text(
            _isProcessing ? 'Scanning...' : 'Scan Passport',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skipPassport,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: const Text(
            'Skip for now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBiometricStep() {
    return Column(
      children: [
        const Spacer(),
        Text(
          'Biometric Verification',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Complete both to secure your Digital ID',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
        _buildBiometricCard(Icons.fingerprint, 'Fingerprint', _fingerprintDone, () => _simulateBiometric('fingerprint')),
        const SizedBox(height: 16),
        _buildBiometricCard(Icons.face, 'Face ID', _faceIdDone, () => _simulateBiometric('face')),
        const Spacer(),
        if (_fingerprintDone && _faceIdDone)
          GlassyButton(
            onPressed: () => setState(() => _changeStep(4)),
            borderRadius: BorderRadius.circular(16),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBiometricCard(IconData icon, String title, bool isDone, VoidCallback onTap) {
    return GestureDetector(
      onTap: isDone ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone
                    ? Colors.green.withOpacity(0.5)
                    : Colors.grey[300]!,
                width: isDone ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDone
                      ? Colors.green.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle : icon,
                    color: isDone ? Colors.green[700] : Colors.grey[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (!isDone)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.withOpacity(0.2), width: 3),
          ),
          child: Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'All Set!',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your Digital ID is ready',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        GlassyButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_user_name', _nameController.text.trim());
            widget.onComplete();
          },
          borderRadius: BorderRadius.circular(16),
          child: const Text(
            'Get Started',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
