import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class IdPage extends StatefulWidget {
  const IdPage({super.key});

  @override
  State<IdPage> createState() => _IdPageState();
}

class _IdPageState extends State<IdPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _idData;
  bool _isLoading = true;
  bool _isTravelMode = false;
  bool _qrUnlocked = false;
  double _pullOffset = 0;
  static const double _pullMax = 400;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // QR auto-refresh
  Timer? _qrRefreshTimer;
  int _qrTimestamp = DateTime.now().millisecondsSinceEpoch;
  int _qrCountdown = 30;

  final Map<String, dynamic> _passportData = {
    'passport_number': 'A12345678',
    'nationality': 'MALAYSIA',
    'issue_date': '2022-01-15',
    'expiry_date': '2032-01-14',
  };

  final List<Map<String, dynamic>> _visas = [
    {'country': 'Singapore', 'code': 'sg', 'type': 'Visa Free', 'expiry': '2030-12-31'},
    {'country': 'Japan', 'code': 'jp', 'type': 'Tourist Visa', 'expiry': '2025-03-15'},
    {'country': 'United States', 'code': 'us', 'type': 'B1/B2 Visa', 'expiry': '2025-01-20'},
    {'country': 'United Kingdom', 'code': 'gb', 'type': 'Tourist Visa', 'expiry': '2026-06-30'},
    {'country': 'Australia', 'code': 'au', 'type': 'ETA', 'expiry': '2025-08-10'},
  ];

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    
    _revealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _revealAnimation = CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack);
    _revealController.addListener(() {
      setState(() {
        _pullOffset = _revealAnimation.value * _pullMax;
      });
    });

    _loadIdData();
    _startQrRefreshTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _revealController.dispose();
    _qrRefreshTimer?.cancel();
    super.dispose();
  }

  void _startQrRefreshTimer() {
    _qrRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _qrCountdown--;
        if (_qrCountdown <= 0) {
          _qrTimestamp = DateTime.now().millisecondsSinceEpoch;
          _qrCountdown = 30;
        }
      });
    });
  }

  String _getQrData(String type) {
    if (type == 'ic') {
      return 'did:my:${_idData?['id_number'] ?? ''}:$_qrTimestamp:verify';
    } else {
      return 'passport:my:${_passportData['passport_number']}:$_qrTimestamp:verify';
    }
  }

  Future<void> _loadIdData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('digital_id_data');
    if (cachedData != null) {
      setState(() { _idData = jsonDecode(cachedData); _isLoading = false; });
      _animationController.forward();
    }
    try {
      final freshData = await _apiService.getDigitalId();
      await prefs.setString('digital_id_data', jsonEncode(freshData));
      setState(() { _idData = freshData; _isLoading = false; });
      if (!_animationController.isCompleted) _animationController.forward();
    } catch (e) {
      if (_idData == null) setState(() => _isLoading = false);
    }
  }

  Color _getExpiryColor(String expiryDateStr) {
    try {
      final expiry = DateTime.parse(expiryDateStr);
      final diff = expiry.difference(DateTime.now()).inDays;
      if (diff < 0) return Colors.red[700]!;
      if (diff < 30) return Colors.red;
      if (diff < 90) return Colors.orange;
      if (diff < 180) return Colors.amber[700]!;
      if (diff < 365) return Colors.green[600]!;
      return Colors.green;
    } catch (e) { return Colors.grey; }
  }

  String _getExpiryLabel(String expiryDateStr) {
    try {
      final expiry = DateTime.parse(expiryDateStr);
      final diff = expiry.difference(DateTime.now()).inDays;
      if (diff < 0) return 'EXPIRED';
      if (diff < 30) return 'Expires soon';
      if (diff < 90) return '${(diff / 30).floor()}mo left';
      return 'Valid';
    } catch (e) { return ''; }
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleQrReveal() async {
    if (_qrUnlocked) {
      // If already unlocked/revealed, hide it
      _revealController.reverse();
      setState(() { _qrUnlocked = false; });
    } else {
      // If hidden, verify first
      final verified = await _showBiometricSheet();
      if (verified && mounted) {
        setState(() { _qrUnlocked = true; });
        _revealController.forward();
      }
    }
  }

  Future<bool> _showBiometricSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              Icon(Icons.fingerprint, size: 64, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 12),
              Text(
                'Biometric Verification',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to view your MyKad QR securely.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.white.withOpacity(0.4)),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Verify'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  String _getDeviceInfo() {
    if (kIsWeb) return 'Web';
    try { return Platform.operatingSystem.toUpperCase(); } catch (e) { return 'Device'; }
  }



  void _showFullscreen(String type) {
    final isIc = type == 'ic';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FullscreenView(
        isIc: isIc,
        idData: _idData,
        passportData: _passportData,
        getQrData: _getQrData,
        getCurrentDateTime: _getCurrentDateTime,
        getDeviceInfo: _getDeviceInfo,
        qrCountdown: _qrCountdown,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2))
            : _idData == null
                ? _buildEmptyState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text('No ID Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          TextButton(onPressed: _loadIdData, style: TextButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)), child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Revealed QR panel behind the main content when pulling down
            if (!_isTravelMode)
              Positioned(
                left: 20,
                right: 20,
                top: 16,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: (_pullOffset / _pullMax).clamp(0, 1),
                    child: Transform.scale(
                      scale: 0.98 + 0.02 * (_pullOffset / _pullMax).clamp(0, 1),
                      child: _qrUnlocked ? _buildQrSection('ic') : _buildLockedQrNotice(),
                    ),
                  ),
                ),
              ),
            // Main content without drag gesture
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Transform.translate(
                offset: Offset(0, _pullOffset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(
                        _isTravelMode ? 'Travel Mode' : 'Digital ID',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      _buildModeToggle(),
                    ]),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _isTravelMode ? _buildTravelMode() : _buildIdMode()),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Emergency Button
            Positioned(
              right: 20,
              bottom: 80,
              child: _buildEmergencyButton(),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildWatermark()),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [_buildToggleButton('ID', Icons.badge, !_isTravelMode), _buildToggleButton('Travel', Icons.flight, _isTravelMode)]),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isTravelMode = label == 'Travel';
          _qrUnlocked = false;
        });
        if (_revealController.value > 0) {
          _revealController.reverse();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))] : null,
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: isActive ? Colors.black : Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.black : Colors.grey[600], fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildIdMode() {
    return Column(key: const ValueKey('id_mode'), children: [
      GestureDetector(onTap: () => _showFullscreen('ic'), child: _buildIcCard()),
      const SizedBox(height: 12),
      Text('Tap card to view fullscreen', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      const SizedBox(height: 24),
      const SizedBox(height: 24),
      _buildRevealButton(),
      const SizedBox(height: 32),
      _buildDetailsSection(),
    ]);
  }

  Widget _buildTravelMode() {
    return Column(key: const ValueKey('travel_mode'), crossAxisAlignment: CrossAxisAlignment.center, children: [
      GestureDetector(onTap: () => _showFullscreen('passport'), child: _buildPassportCard()),
      const SizedBox(height: 12),
      Text('Tap card to view fullscreen', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      const SizedBox(height: 24),
      Center(child: _buildQrSection('passport')),
      const SizedBox(height: 32),
      Align(
        alignment: Alignment.centerLeft,
        child: const Text('Available Visas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      const SizedBox(height: 16),
      ..._visas.map((visa) => _buildVisaCard(visa)),
    ]);
  }

  Widget _buildIcCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/countryFlag/my.png',
                      width: 32,
                      height: 22,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(width: 32, height: 22, color: Colors.grey[200]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MALAYSIA',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.green, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'VERIFIED',
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'REPUBLIC OF MALAYSIA',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'NATIONAL DIGITAL IDENTITY CARD',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _idData!['name'] ?? 'Name',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NRIC number',
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _idData!['id_number'] ?? 'ID',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportCard() {
    final expiryColor = _getExpiryColor(_passportData['expiry_date']);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Image.asset('assets/images/passport.png', width: double.infinity, height: 240, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 240, color: Colors.indigo[100], child: const Center(child: Icon(Icons.menu_book, size: 48)))),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.8)])))),
          Positioned(top: 16, left: 16, child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.asset('assets/images/countryFlag/my.png', width: 32, height: 22, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 32, height: 22, color: Colors.grey))), const SizedBox(width: 8), const Text('PASSPORT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1))])),
          Positioned(top: 16, right: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: expiryColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)), child: Text(_getExpiryLabel(_passportData['expiry_date']), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
          Positioned(bottom: 20, left: 20, right: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_idData!['name'] ?? 'Name', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Row(children: [_buildPassportDetail('Passport No.', _passportData['passport_number']), const SizedBox(width: 32), _buildPassportDetail('Expiry', _passportData['expiry_date'], color: expiryColor)])])),
        ]),
      ),
    );
  }

  Widget _buildPassportDetail(String label, String value, {Color? color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)), const SizedBox(height: 4), Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600))]);
  }

  Widget _buildVisaCard(Map<String, dynamic> visa) {
    final expiryColor = _getExpiryColor(visa['expiry']);
    final expiryLabel = _getExpiryLabel(visa['expiry']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/images/countryFlag/${visa['code']}.png', width: 40, height: 28, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 40, height: 28, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.flag, size: 16, color: Colors.grey)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(visa['country'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(visa['type'], style: TextStyle(fontSize: 13, color: Colors.grey[500]))])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: expiryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(expiryLabel, style: TextStyle(color: expiryColor, fontSize: 11, fontWeight: FontWeight.w600))), const SizedBox(height: 4), Text(visa['expiry'], style: TextStyle(fontSize: 12, color: Colors.grey[400]))]),
      ]),
    );
  }

  Widget _buildQrSection(String type) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(
            type == 'ic' ? 'MyKad Verification' : 'Passport Verification',
            style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            type == 'ic' ? 'Show this to verify your Digital ID' : 'Show this to verify your Passport',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 16),
          QrImageView(data: _getQrData(type), version: QrVersions.auto, size: 180),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text('Auto-refresh in ${_qrCountdown}s', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedQrNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verify to reveal',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the button below to verify and view your MyKad QR.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealButton() {
    return GestureDetector(
      onTap: _toggleQrReveal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_qrUnlocked ? Icons.keyboard_arrow_up : Icons.qr_code_scanner, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              _qrUnlocked ? 'Tap to Close QR' : 'Tap to Verify & View QR',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final expiryColor = _getExpiryColor(_idData!['valid_until'] ?? '2030-12-31');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(children: [_buildDetailRow('Country', _idData!['country'] ?? 'N/A'), _buildDetailRow('Valid Until', _idData!['valid_until'] ?? 'N/A', valueColor: expiryColor), _buildDetailRow('Status', 'Active', valueColor: Colors.green)]),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!.withOpacity(0.6)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWatermark() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.3)])),
      child: SafeArea(top: false, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_user, size: 14, color: Colors.grey[600]), const SizedBox(width: 8), Text('${_getCurrentDateTime()} • ${_getDeviceInfo()}', style: TextStyle(color: Colors.grey[600], fontSize: 11))]))),
    );
  }

  Widget _buildEmergencyButton() {
    return GestureDetector(
      onTap: _showEmergencyOptions,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.emergency,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showEmergencyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.emergency, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Emergency Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isTravelMode 
                ? 'Quick access to emergency contacts while traveling'
                : 'Quick access to emergency services in Malaysia',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildEmergencyTile(
              icon: Icons.local_police,
              title: 'Police',
              subtitle: _isTravelMode ? 'Local Emergency' : '999',
              color: Colors.blue,
            ),
            _buildEmergencyTile(
              icon: Icons.local_hospital,
              title: 'Ambulance',
              subtitle: _isTravelMode ? 'Medical Emergency' : '999',
              color: Colors.red,
            ),
            _buildEmergencyTile(
              icon: Icons.local_fire_department,
              title: 'Fire Department',
              subtitle: _isTravelMode ? 'Fire Emergency' : '994',
              color: Colors.orange,
            ),
            if (_isTravelMode)
              _buildEmergencyTile(
                icon: Icons.account_balance,
                title: 'Embassy',
                subtitle: 'Malaysian Embassy',
                color: Colors.indigo,
              ),
            const SizedBox(height: 16),
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[900])),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: Icon(Icons.phone, color: color),
        onTap: () {
          Navigator.pop(context);
          // In a real app, this would trigger a phone call
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling $title...'),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}

// Fullscreen View Widget with Full Page Watermark
class _FullscreenView extends StatefulWidget {
  final bool isIc;
  final Map<String, dynamic>? idData;
  final Map<String, dynamic> passportData;
  final String Function(String) getQrData;
  final String Function() getCurrentDateTime;
  final String Function() getDeviceInfo;
  final int qrCountdown;

  const _FullscreenView({
    required this.isIc,
    required this.idData,
    required this.passportData,
    required this.getQrData,
    required this.getCurrentDateTime,
    required this.getDeviceInfo,
    required this.qrCountdown,
  });

  @override
  State<_FullscreenView> createState() => _FullscreenViewState();
}

class _FullscreenViewState extends State<_FullscreenView> {
  late Timer _refreshTimer;
  late String _currentTime;
  late int _qrTimestamp;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.getCurrentDateTime();
    _qrTimestamp = DateTime.now().millisecondsSinceEpoch;
    _countdown = widget.qrCountdown;
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = widget.getCurrentDateTime();
        _countdown--;
        if (_countdown <= 0) {
          _qrTimestamp = DateTime.now().millisecondsSinceEpoch;
          _countdown = 30;
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  String _getFullscreenQrData() {
    if (widget.isIc) {
      return 'did:my:${widget.idData?['id_number'] ?? ''}:$_qrTimestamp:verify';
    } else {
      return 'passport:my:${widget.passportData['passport_number']}:$_qrTimestamp:verify';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main Content
          Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(widget.isIc ? 'MyKad' : 'Passport', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.isIc ? 'assets/images/IC.jpg' : 'assets/images/passport.png',
                    width: double.infinity, height: 180, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey[200], child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey))),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 48),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Verification QR', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${_countdown}s', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  QrImageView(data: _getFullscreenQrData(), version: QrVersions.auto, size: 160),
                ]),
              ),
            ],
          ),
          // Full Page Watermark Pattern
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WatermarkPainter(text: 'JOURNEY', dateTime: _currentTime),
              ),
            ),
          ),
          // Bottom Bar
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0), Colors.white])),
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.verified_user, size: 16, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(_currentTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text('• ${widget.getDeviceInfo()}', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Full Page Watermark
class _WatermarkPainter extends CustomPainter {
  final String text;
  final String dateTime;

  _WatermarkPainter({required this.text, required this.dateTime});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    canvas.save();
    canvas.rotate(-0.3);
    
    for (double y = -200; y < size.height + 400; y += 120) {
      for (double x = -200; x < size.width + 200; x += 280) {
        textPainter.text = TextSpan(
          text: text,
          style: TextStyle(color: Colors.grey.withOpacity(0.08), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
        
        textPainter.text = TextSpan(
          text: dateTime,
          style: TextStyle(color: Colors.grey.withOpacity(0.05), fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y + 32));
      }
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter oldDelegate) => oldDelegate.dateTime != dateTime;
}
