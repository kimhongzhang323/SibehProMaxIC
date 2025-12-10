import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class ReplaceICPage extends StatefulWidget {
  const ReplaceICPage({super.key});

  @override
  State<ReplaceICPage> createState() => _ReplaceICPageState();
}

class _ReplaceICPageState extends State<ReplaceICPage> {
  int _currentStep = 0;
  bool _isAutofillEnabled = true;
  bool _isLoading = false;
  String? _selectedCategory;
  String? _selectedReason;

  // Track completed regulatory milestones
  bool _hasCompleted18YearRenewal = false;
  bool _hasLatestVersion = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _icNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _newAddressController = TextEditingController();
  final _newNameController = TextEditingController();
  final _policeReportController = TextEditingController();
  final _correctionDetailsController = TextEditingController();

  // Stored user data for autofill
  Map<String, dynamic>? _userData;

  // Pickup location
  String? _selectedPickupLocation;

  // UTC/JPN Locations for pickup
  final List<Map<String, dynamic>> _pickupLocations = [
    {
      'id': 'utc_kl',
      'name': 'UTC Kuala Lumpur',
      'address': 'Pudu Sentral, Jalan Pudu, 55100 Kuala Lumpur',
      'hours': '8:00 AM - 10:00 PM (Daily)',
      'distance': '2.3 km',
      'waitTime': '~15 mins',
      'isRecommended': true,
    },
    {
      'id': 'jpn_kl',
      'name': 'JPN Kuala Lumpur',
      'address': 'Kompleks JPN, Jalan Duta, 50480 Kuala Lumpur',
      'hours': '8:30 AM - 4:30 PM (Mon-Fri)',
      'distance': '5.1 km',
      'waitTime': '~30 mins',
      'isRecommended': false,
    },
    {
      'id': 'utc_sentul',
      'name': 'UTC Sentul',
      'address': 'Sentul Village Mall, 51000 Kuala Lumpur',
      'hours': '8:00 AM - 10:00 PM (Daily)',
      'distance': '6.8 km',
      'waitTime': '~20 mins',
      'isRecommended': false,
    },
    {
      'id': 'jpn_pj',
      'name': 'JPN Petaling Jaya',
      'address': 'Jalan Othman, Seksyen 3, 46000 Petaling Jaya',
      'hours': '8:00 AM - 5:00 PM (Mon-Fri)',
      'distance': '8.2 km',
      'waitTime': '~25 mins',
      'isRecommended': false,
    },
    {
      'id': 'utc_pj',
      'name': 'UTC Petaling Jaya',
      'address': 'MBPJ Tower, Jalan Yong Shook Lin, 46050 PJ',
      'hours': '8:00 AM - 10:00 PM (Daily)',
      'distance': '9.5 km',
      'waitTime': '~10 mins',
      'isRecommended': false,
    },
  ];

  // Categories and their reasons
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'physical',
      'title': 'Physical Failures',
      'subtitle': 'Hardware problems with your plastic card',
      'icon': Icons.broken_image_outlined,
      'color': Colors.orange,
      'tagline': 'Problems eliminated with Virtual ID',
      'reasons': [
        {
          'id': 'chip_damaged',
          'title': 'Chip Damaged / Unreadable',
          'description':
              'The gold chip is scratched or oxidized. Card readers cannot read it.',
          'icon': Icons.memory,
          'traditionalSolution':
              'Go to JPN counter, pay fee, wait for new card',
          'appSolution':
              'Virtual IDs don\'t get scratched! Your digital ID works everywhere.',
          'fee': 'FREE',
          'isInstant': true,
        },
        {
          'id': 'physical_breakage',
          'title': 'Physical Breakage',
          'description':
              'Card snapped in half, peeled apart, or photo has faded.',
          'icon': Icons.credit_card_off,
          'traditionalSolution': 'Must replace the entire physical card',
          'appSolution': 'Your virtual ID is always pristine and clear.',
          'fee': 'FREE',
          'isInstant': true,
        },
        {
          'id': 'wear_tear',
          'title': 'Wear and Tear (Old Card)',
          'description': 'Card is over 10 years old and material has degraded.',
          'icon': Icons.timelapse,
          'traditionalSolution': 'Pay for replacement card',
          'appSolution': 'Digital IDs never age or degrade.',
          'fee': 'FREE',
          'isInstant': true,
        },
        {
          'id': 'device_incompatible',
          'title': 'Device Incompatibility',
          'description':
              'MyKad works at some banks but fails at others with older machines.',
          'icon': Icons.devices,
          'traditionalSolution': 'Try different branches or get new card',
          'appSolution': 'QR verification works on any smartphone.',
          'fee': 'FREE',
          'isInstant': true,
        },
      ],
    },
    {
      'id': 'data_update',
      'title': 'Data Updates',
      'subtitle': 'Update information on your ID',
      'icon': Icons.edit_document,
      'color': Colors.blue,
      'tagline': 'Instant updates, no reprinting needed',
      'reasons': [
        {
          'id': 'change_address',
          'title': 'Change of Address',
          'description':
              'You moved house. By law, your IC address must match your residence.',
          'icon': Icons.home,
          'traditionalSolution':
              'Go to JPN, pay RM10, wait for new card just to change text',
          'appSolution':
              'Update in-app → Upload proof (utility bill) → JPN approves → Instant update!',
          'fee': 'RM10',
          'isInstant': false,
          'requiresProof': true,
          'proofType': 'Address proof (utility bill, tenancy agreement)',
        },
        {
          'id': 'change_name',
          'title': 'Change of Name',
          'description':
              'Name change due to marriage, conversion, or correcting spelling error.',
          'icon': Icons.badge,
          'traditionalSolution': 'Submit documents, reprint entire card',
          'appSolution': 'Submit documents digitally, get approved remotely.',
          'fee': 'RM10',
          'isInstant': false,
          'requiresProof': true,
          'proofType': 'Court order, marriage certificate, or deed poll',
        },
        {
          'id': 'change_religion',
          'title': 'Change of Religion',
          'description': 'Updating religious status on your ID.',
          'icon': Icons.brightness_7,
          'traditionalSolution': 'Submit religious documents, reprint card',
          'appSolution':
              'Digital submission with religious authority verification.',
          'fee': 'RM10',
          'isInstant': false,
          'requiresProof': true,
          'proofType': 'Religious authority certificate',
        },
        {
          'id': 'correction',
          'title': 'Correction of Particulars',
          'description':
              'Original MyKad had wrong birthplace, gender, or other clerical errors.',
          'icon': Icons.edit_note,
          'traditionalSolution':
              'Lodge complaint, wait for investigation, reprint',
          'appSolution': 'Submit correction request with supporting documents.',
          'fee': 'FREE',
          'isInstant': false,
          'requiresProof': true,
          'proofType': 'Birth certificate, supporting documents',
        },
      ],
    },
    {
      'id': 'regulatory',
      'title': 'Regulatory Milestones',
      'subtitle': 'Mandatory updates required by law',
      'icon': Icons.gavel,
      'color': Colors.purple,
      'tagline': 'Skip the queue with digital verification',
      'reasons': [
        {
          'id': 'age_18_renewal',
          'title': '18-Year-Old Mandatory Renewal',
          'description':
              'Every Malaysian must replace MyKad at age 18 (Regulation 18). Photo from age 12 no longer resembles you.',
          'icon': Icons.cake,
          'traditionalSolution': 'Queue at JPN for new photo and card',
          'appSolution':
              'Take selfie verification in-app (e-KYC) to update your Adult Profile!',
          'fee': 'FREE',
          'isInstant': false,
          'requiresSelfie': true,
        },
        {
          'id': 'version_upgrade',
          'title': 'Upgrade to Latest Version',
          'description':
              'Government released new MyKad version with better security features.',
          'icon': Icons.system_update,
          'traditionalSolution':
              'Citizens ignore this because they don\'t want to queue',
          'appSolution': 'App updates automatically via App Store!',
          'fee': 'FREE',
          'isInstant': true,
        },
      ],
    },
    {
      'id': 'loss_security',
      'title': 'Loss & Security',
      'subtitle': 'Lost, stolen, or security concerns',
      'icon': Icons.security,
      'color': Colors.red,
      'tagline': 'Cloud restore on any device',
      'reasons': [
        {
          'id': 'lost_card',
          'title': 'Lost Physical Card',
          'description':
              'Dropped wallet, misplaced card, or cannot find it anywhere.',
          'icon': Icons.search_off,
          'traditionalSolution':
              'Pay fine (RM100 first, RM300 second), wait for replacement',
          'appSolution':
              'Request replacement with Cloud Restore. Virtual ID stays active!',
          'fee': 'RM100',
          'isInstant': false,
          'requiresPoliceReport': false,
        },
        {
          'id': 'stolen_card',
          'title': 'Stolen Physical Card (Crime)',
          'description': 'Card was stolen during robbery or theft.',
          'icon': Icons.report_problem,
          'traditionalSolution':
              'Police report required, pay fine, wait for new card',
          'appSolution':
              'Remote wipe stolen device, restore on new phone instantly.',
          'fee': 'FREE',
          'isInstant': false,
          'requiresPoliceReport': true,
        },
        {
          'id': 'phone_stolen',
          'title': 'Phone with App Stolen',
          'description':
              'Device with Journey app was stolen. Worried about misuse.',
          'icon': Icons.phone_android,
          'traditionalSolution': 'N/A',
          'appSolution':
              'Remote lock your digital ID from any browser, restore on new device.',
          'fee': 'FREE',
          'isInstant': true,
          'requiresPoliceReport': true,
        },
        {
          'id': 'security_concern',
          'title': 'Security Concern',
          'description':
              'Worried someone may have copied or is misusing your ID.',
          'icon': Icons.shield,
          'traditionalSolution': 'Replace physical card to change chip data',
          'appSolution':
              'Generate new secure QR codes instantly, invalidate old ones.',
          'fee': 'FREE',
          'isInstant': true,
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _newAddressController.dispose();
    _newNameController.dispose();
    _policeReportController.dispose();
    _correctionDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('digital_id_data');
    if (cachedData != null) {
      setState(() {
        _userData = jsonDecode(cachedData);
      });
    }
    // Always apply autofill since fields are read-only
    _applyAutofill();
    // Load completed regulatory milestones
    await _loadCompletedMilestones();
  }

  Future<void> _loadCompletedMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = prefs.getString('ic_replacement_requests');
    if (requestsJson != null) {
      final List<dynamic> requests = jsonDecode(requestsJson);
      setState(() {
        // Check if user has already completed the 18-year-old renewal
        _hasCompleted18YearRenewal =
            requests.any((r) => r['reason'] == '18-Year-Old Mandatory Renewal');
        // Check if user already has the latest version
        _hasLatestVersion =
            requests.any((r) => r['reason'] == 'Upgrade to Latest Version');
      });
    }
  }

  void _applyAutofill() {
    if (_userData != null) {
      _nameController.text = _userData!['name'] ?? '';
      _icNumberController.text = _userData!['id_number'] ?? '';
      _phoneController.text = '+60 12-345 6789';
      _emailController.text = 'tanahkow@email.com';
      _addressController.text = 'No. 123, Jalan Example, 50000 Kuala Lumpur';
    }
  }

  void _clearAutofill() {
    _nameController.clear();
    _icNumberController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
  }

  void _toggleAutofill(bool value) {
    setState(() {
      _isAutofillEnabled = value;
    });
    if (value) {
      _applyAutofill();
    } else {
      _clearAutofill();
    }
  }

  Map<String, dynamic>? get _selectedCategoryData {
    if (_selectedCategory == null) return null;
    return _categories.firstWhere((c) => c['id'] == _selectedCategory);
  }

  Map<String, dynamic>? get _selectedReasonData {
    if (_selectedReason == null || _selectedCategoryData == null) return null;
    final reasons =
        _selectedCategoryData!['reasons'] as List<Map<String, dynamic>>;
    return reasons.firstWhere((r) => r['id'] == _selectedReason);
  }

  bool get _requiresPoliceReport =>
      _selectedReasonData?['requiresPoliceReport'] ?? false;
  bool get _requiresProof => _selectedReasonData?['requiresProof'] ?? false;
  bool get _requiresSelfie => _selectedReasonData?['requiresSelfie'] ?? false;
  bool get _isInstant => _selectedReasonData?['isInstant'] ?? false;

  Map<String, dynamic>? get _selectedPickupLocationData {
    if (_selectedPickupLocation == null) return null;
    return _pickupLocations
        .firstWhere((l) => l['id'] == _selectedPickupLocation);
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_currentStep == 1 && _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specific reason')),
      );
      return;
    }

    if (_currentStep == 2 && !_formKey.currentState!.validate()) {
      return;
    }

    if (_currentStep == 3 && _selectedPickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location')),
      );
      return;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _showSubmitConfirmation();
    }
  }

  void _showSubmitConfirmation() {
    final reason = _selectedReasonData!;
    final fee = reason['fee'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.orange[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Submission',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to submit a MyKad replacement request.',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Fee info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fee == 'FREE' ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long,
                        color: fee == 'FREE'
                            ? Colors.green[700]
                            : Colors.orange[700],
                        size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Processing Fee: $fee',
                      style: TextStyle(
                        color: fee == 'FREE'
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warning section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.red[700], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notice',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '• Frequent replacements may trigger security flags',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• JPN officers may question unusual patterns',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Multiple requests may result in temporary blocks',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Suspicious activity may require officer interview',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Are you sure you want to proceed?',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFaceScanVerification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  void _showFaceScanVerification() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _FaceScanDialog(),
    ).then((success) {
      if (success == true) {
        _submitApplication();
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      if (_currentStep == 3) {
        _selectedPickupLocation = null;
      }
      if (_currentStep == 2) {
        _selectedReason = null;
      }
      if (_currentStep == 1) {
        _selectedCategory = null;
      }
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    final pickupLocation = _selectedPickupLocationData!;
    final category = _selectedCategoryData!;
    final reason = _selectedReasonData!;

    // Generate reference number
    final now = DateTime.now();
    final refNumber =
        'JPN-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    // Save request to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final requestData = {
      'refNumber': refNumber,
      'category': category['title'],
      'reason': reason['title'],
      'fee': reason['fee'],
      'pickupLocationId': pickupLocation['id'],
      'pickupLocationName': pickupLocation['name'],
      'pickupLocationAddress': pickupLocation['address'],
      'pickupLocationHours': pickupLocation['hours'],
      'status': 'Processing',
      'submittedAt': now.toIso8601String(),
      'estimatedReady': now.add(const Duration(days: 3)).toIso8601String(),
      'name': _nameController.text,
      'icNumber': _icNumberController.text,
    };

    // Get existing requests list
    final existingRequestsJson = prefs.getString('ic_replacement_requests');
    List<dynamic> requests = [];
    if (existingRequestsJson != null) {
      requests = jsonDecode(existingRequestsJson);
    }

    // Add new request at the beginning
    requests.insert(0, requestData);

    // Save back to SharedPreferences
    await prefs.setString('ic_replacement_requests', jsonEncode(requests));

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    color: Colors.green[600], size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Request Submitted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your MyKad replacement request has been submitted.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  refNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.blue[700], size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pickup: ${pickupLocation['name']}',
                            style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Ready in 1-3 working days',
                          style:
                              TextStyle(color: Colors.blue[700], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You will receive an SMS when your new MyKad is ready. Your virtual ID will update automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _previousStep,
        ),
        title: const Text(
          'MyKad Services',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Category'),
                _buildStepConnector(0),
                _buildStepIndicator(1, 'Issue'),
                _buildStepConnector(1),
                _buildStepIndicator(2, 'Details'),
                _buildStepConnector(2),
                _buildStepIndicator(3, 'Pickup'),
                _buildStepConnector(3),
                _buildStepIndicator(4, 'Confirm'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == 4 ? 'Submit Request' : 'Continue',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue[700] : Colors.grey[200],
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: Colors.blue[200]!, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.blue[700] : Colors.grey[500],
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.blue[700] : Colors.grey[200],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildReasonStep();
      case 2:
        return _buildDetailsStep();
      case 3:
        return _buildPickupStep();
      case 4:
        return _buildConfirmStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What brings you here today?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the category that best describes your situation',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ...List.generate(_categories.length, (index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['id']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (category['color'] as Color)
                      : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: (category['color'] as Color)
                                .withValues(alpha: 0.15),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (category['color'] as Color)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category['icon'] as IconData,
                            color: category['color'] as Color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['title'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category['subtitle'] as String,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: category['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          category['tagline'] as String,
                          style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReasonStep() {
    final category = _selectedCategoryData!;
    final reasons = category['reasons'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (category['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category['icon'] as IconData,
                  color: category['color'] as Color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              category['title'] as String,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: category['color'] as Color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select the specific issue you\'re experiencing',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ...List.generate(reasons.length, (index) {
          final reason = reasons[index];
          final isSelected = _selectedReason == reason['id'];

          // Check if this regulatory milestone is already completed
          final bool isDisabled = _selectedCategory == 'regulatory' &&
              ((reason['id'] == 'age_18_renewal' &&
                      _hasCompleted18YearRenewal) ||
                  (reason['id'] == 'version_upgrade' && _hasLatestVersion));

          return GestureDetector(
            onTap: isDisabled
                ? null
                : () => setState(() => _selectedReason = reason['id']),
            child: Opacity(
              opacity: isDisabled ? 0.6 : 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDisabled ? Colors.grey[100] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.grey[300]!
                        : (isSelected ? Colors.blue[700]! : Colors.grey[200]!),
                    width: isSelected && !isDisabled ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? Colors.grey[200]
                                  : (category['color'] as Color)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(reason['icon'] as IconData,
                                color: isDisabled
                                    ? Colors.grey[400]
                                    : category['color'] as Color,
                                size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reason['title'] as String,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: isDisabled
                                                ? Colors.grey[500]
                                                : null),
                                      ),
                                    ),
                                    if (isDisabled)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle,
                                                size: 12,
                                                color: Colors.green[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Completed',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: reason['fee'] == 'FREE'
                                              ? Colors.green[50]
                                              : Colors.orange[50],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          reason['fee'] as String,
                                          style: TextStyle(
                                            color: reason['fee'] == 'FREE'
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reason['description'] as String,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.close,
                                    color: Colors.red[400], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Traditional Way:',
                                          style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          reason['traditionalSolution']
                                              as String,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green[600], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('With Journey:',
                                          style: TextStyle(
                                              color: Colors.green[700],
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      Text(reason['appSolution'] as String,
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (reason['isInstant'] == true) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt,
                                        color: Colors.blue[700], size: 14),
                                    const SizedBox(width: 4),
                                    Text('Instant Update',
                                        style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final reason = _selectedReasonData!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green[700], size: 14),
                    const SizedBox(width: 4),
                    Text('Verified',
                        style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Information retrieved from your digital ID',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _nameController,
            label: 'Full Name (as per IC)',
            icon: Icons.person_outline,
            readOnly: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),

          _buildTextField(
            controller: _icNumberController,
            label: 'IC Number',
            icon: Icons.credit_card,
            readOnly: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),

          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            readOnly: true,
            keyboardType: TextInputType.phone,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),

          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            readOnly: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),

          _buildTextField(
            controller: _addressController,
            label: 'Current Address',
            icon: Icons.location_on_outlined,
            readOnly: true,
            maxLines: 2,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),

          // Conditional fields based on reason
          if (_selectedReason == 'change_address') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Enter your new address below',
                        style:
                            TextStyle(color: Colors.blue[800], fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _newAddressController,
              label: 'New Address',
              icon: Icons.home,
              maxLines: 2,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],

          if (_selectedReason == 'change_name') ...[
            const SizedBox(height: 8),
            _buildTextField(
              controller: _newNameController,
              label: 'New Name',
              icon: Icons.badge,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],

          if (_selectedReason == 'correction') ...[
            const SizedBox(height: 8),
            _buildTextField(
              controller: _correctionDetailsController,
              label: 'What needs to be corrected?',
              icon: Icons.edit_note,
              maxLines: 3,
              hint: 'Describe the error and the correct information',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],

          if (_requiresPoliceReport) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Colors.orange[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('A police report is required',
                        style:
                            TextStyle(color: Colors.orange[900], fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _policeReportController,
              label: 'Police Report Number',
              icon: Icons.description_outlined,
              hint: 'e.g., KLSP/123456/2024',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],

          if (_requiresProof && !_requiresPoliceReport) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Proof Required:',
                            style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(reason['proofType'] as String,
                            style: TextStyle(
                                color: Colors.blue[700], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement file picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document upload coming soon')),
                );
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Document'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[700],
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                side: BorderSide(color: Colors.blue[300]!),
              ),
            ),
          ],

          if (_requiresSelfie) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.face, color: Colors.purple[700], size: 20),
                      const SizedBox(width: 10),
                      Text('Selfie Verification Required',
                          style: TextStyle(
                              color: Colors.purple[800],
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo to verify your identity and update your adult profile.',
                    style: TextStyle(color: Colors.purple[700], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Camera verification coming soon')),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Selfie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Pickup Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose where to collect your new physical MyKad',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Physical + Virtual Update',
                      style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your virtual ID will update automatically when your physical card is ready.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Location header
        Row(
          children: [
            Icon(Icons.near_me, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              'Nearest locations to you',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Location cards
        ...List.generate(_pickupLocations.length, (index) {
          final location = _pickupLocations[index];
          final isSelected = _selectedPickupLocation == location['id'];
          final isRecommended = location['isRecommended'] as bool;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedPickupLocation = location['id']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.blue[700]! : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.1),
                            blurRadius: 10)
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.blue[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          location['name'].toString().contains('UTC')
                              ? Icons.business
                              : Icons.account_balance,
                          color:
                              isSelected ? Colors.blue[700] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    location['name'] as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                                if (isRecommended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Recommended',
                                      style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location['address'] as String,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location['hours'] as String,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                            width: 1, height: 16, color: Colors.grey[300]),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              location['distance'] as String,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                            width: 1, height: 16, color: Colors.grey[300]),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(Icons.timer,
                                size: 14, color: Colors.orange[400]),
                            const SizedBox(width: 4),
                            Text(
                              location['waitTime'] as String,
                              style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Processing time info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Processing Time',
                      style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your new MyKad will be ready for collection within 1-3 working days.',
                      style: TextStyle(color: Colors.orange[800], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        style: TextStyle(
          color: readOnly ? Colors.grey[700] : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon,
              color: readOnly ? Colors.grey[400] : Colors.grey[500], size: 20),
          suffixIcon: readOnly
              ? Icon(Icons.lock_outline, color: Colors.grey[400], size: 18)
              : null,
          filled: true,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: readOnly ? Colors.grey[200]! : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: readOnly ? Colors.grey[300]! : Colors.blue[700]!,
                width: readOnly ? 1 : 2),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmStep() {
    final category = _selectedCategoryData!;
    final reason = _selectedReasonData!;
    final pickupLocation = _selectedPickupLocationData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Request',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Issue Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          (category['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(reason['icon'] as IconData,
                        color: category['color'] as Color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category['title'] as String,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                        Text(reason['title'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: reason['fee'] == 'FREE'
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reason['fee'] as String,
                      style: TextStyle(
                        color: reason['fee'] == 'FREE'
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Personal Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Information',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 14),
              _buildConfirmRow('Name', _nameController.text),
              _buildConfirmRow('IC Number', _icNumberController.text),
              _buildConfirmRow('Phone', _phoneController.text),
              _buildConfirmRow('Email', _emailController.text),
              if (_selectedReason == 'change_address')
                _buildConfirmRow('New Address', _newAddressController.text),
              if (_selectedReason == 'change_name')
                _buildConfirmRow('New Name', _newNameController.text),
              if (_requiresPoliceReport)
                _buildConfirmRow('Police Report', _policeReportController.text),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Pickup Location Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  const Text('Pickup Location',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        pickupLocation['name'].toString().contains('UTC')
                            ? Icons.business
                            : Icons.account_balance,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickupLocation['name'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900]),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pickupLocation['address'] as String,
                            style: TextStyle(
                                color: Colors.blue[700], fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Ready in 1-3 working days',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // What happens next
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.purple[50]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'What happens next?',
                    style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNextStepItem(
                  1, 'Your request will be submitted to JPN', Colors.blue),
              _buildNextStepItem(
                  2, 'New physical MyKad will be printed', Colors.purple),
              _buildNextStepItem(
                  3, 'Collect at ${pickupLocation['name']}', Colors.green),
              _buildNextStepItem(
                  4, 'Virtual ID updates automatically', Colors.orange),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Terms
        Text(
          'By submitting, you confirm all information is accurate.',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNextStepItem(int number, String text, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                    color: color[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// Face Scan Verification Dialog
class _FaceScanDialog extends StatefulWidget {
  const _FaceScanDialog();

  @override
  State<_FaceScanDialog> createState() => _FaceScanDialogState();
}

class _FaceScanDialogState extends State<_FaceScanDialog>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  String _status = 'positioning';
  String _statusText = 'Position your face in the frame';
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
    _checkBiometrics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      _canUseBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _canUseBiometrics = _canUseBiometrics && isDeviceSupported;
    } catch (e) {
      _canUseBiometrics = false;
    }

    // Start the scan simulation after a short delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _startScan();
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _status = 'scanning';
      _statusText = 'Scanning your face...';
    });

    // Try device biometrics first
    if (_canUseBiometrics) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Verify your identity to submit MyKad replacement',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (mounted) {
          if (authenticated) {
            _showSuccess();
          } else {
            _showFailure('Biometric verification failed');
          }
        }
        return;
      } catch (e) {
        // Fall through to simulation if biometrics fail
      }
    }

    // Fallback: Simulate face scan for devices without biometrics
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _status = 'verifying';
        _statusText = 'Verifying identity...';
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _showSuccess();
    }
  }

  void _showSuccess() {
    _animationController.stop();
    setState(() {
      _status = 'success';
      _statusText = 'Verification successful!';
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showFailure(String message) {
    _animationController.stop();
    setState(() {
      _status = 'failed';
      _statusText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, color: Colors.blue[700], size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Face Verification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Face scan frame
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _status == 'success'
                          ? Colors.green
                          : _status == 'failed'
                              ? Colors.red
                              : Colors.blue[700]!,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_status == 'success'
                                ? Colors.green
                                : _status == 'failed'
                                    ? Colors.red
                                    : Colors.blue)
                            .withValues(
                                alpha: 0.2 + (_scanAnimation.value * 0.2)),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background
                      Container(
                        width: 172,
                        height: 172,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                        ),
                        child: Icon(
                          _status == 'success'
                              ? Icons.check_circle
                              : _status == 'failed'
                                  ? Icons.error
                                  : Icons.face,
                          size: 80,
                          color: _status == 'success'
                              ? Colors.green
                              : _status == 'failed'
                                  ? Colors.red
                                  : Colors.grey[400],
                        ),
                      ),
                      // Scanning line
                      if (_status == 'scanning' || _status == 'positioning')
                        Positioned(
                          top: 10 + (_scanAnimation.value * 152),
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.blue[400]!,
                                  Colors.blue[700]!,
                                  Colors.blue[400]!,
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _status == 'success'
                    ? Colors.green[700]
                    : _status == 'failed'
                        ? Colors.red[700]
                        : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Loading indicator or status icon
            if (_status == 'scanning' || _status == 'verifying')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.blue[700],
                  ),
                ),
              ),

            if (_status == 'failed') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _status = 'positioning';
                        _statusText = 'Position your face in the frame';
                      });
                      _animationController.repeat(reverse: true);
                      Future.delayed(const Duration(seconds: 2), _startScan);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ],

            if (_status == 'positioning') ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
