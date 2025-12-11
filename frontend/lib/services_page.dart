import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'jpn_page.dart';
import 'main.dart';
import 'print_ic_page.dart';
import 'jpj_page.dart';
import 'immigration_page.dart';
import 'lhdn_page.dart';
import 'kwsp_page.dart';
import 'perkeso_page.dart';
import 'moh_page.dart';
import 'id_page.dart';
import 'scanner_page.dart';
import 'models/quick_action_item.dart';
import 'widgets/quick_actions_grid.dart';
import 'package:frontend/pages/ic_dashboard_page.dart';
import 'package:frontend/pages/rapidkl_page.dart';


class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final PageController _newsController = PageController(viewportFraction: 0.9);
  final PageController _walletController = PageController(viewportFraction: 0.93);
  int _currentNewsIndex = 0;
  int _currentWalletIndex = 0;
  List<Map<String, dynamic>> _icRequests = [];

  List<QuickActionItem> _quickActions = [
    const QuickActionItem(
        id: 'scan',
        label: 'Scan',
        icon: Icons.qr_code_scanner,
        color: Colors.black,
        routeName: 'scanner'),
    const QuickActionItem(
        id: 'tax',
        label: 'Tax',
        icon: Icons.receipt_long,
        color: Colors.green,
        routeName: 'lhdn'),
     const QuickActionItem(
        id: 'rapidkl',
        label: 'RapidKL',
        icon: Icons.directions_bus,
        color: Colors.blueAccent,
        routeName: 'rapidkl',
        assetPath: 'assets/images/rapidKL.png'),
  ];
  
  // Available actions pool for adding
  final List<QuickActionItem> _allAvailableActions = [
    const QuickActionItem(id: 'scan', label: 'Scan', icon: Icons.qr_code_scanner, color: Colors.black, routeName: 'scanner'),
    const QuickActionItem(id: 'tax', label: 'Tax', icon: Icons.receipt_long, color: Colors.green, routeName: 'lhdn'),
    const QuickActionItem(id: 'mykad', label: 'MyKad', icon: Icons.badge, color: Colors.blue, routeName: 'mykad'),
    const QuickActionItem(id: 'passport', label: 'Passport', icon: Icons.book, color: Colors.red, routeName: 'passport'),
    const QuickActionItem(id: 'kwsp', label: 'KWSP', icon: Icons.account_balance, color: Colors.indigo, routeName: 'kwsp'),
    const QuickActionItem(id: 'perkeso', label: 'Perkeso', icon: Icons.health_and_safety, color: Colors.orange, routeName: 'perkeso'),
    const QuickActionItem(id: 'moh', label: 'MOH', icon: Icons.medical_services, color: Colors.pink, routeName: 'moh'),
    const QuickActionItem(id: 'rapidkl', label: 'RapidKL', icon: Icons.directions_bus, color: Colors.blueAccent, routeName: 'rapidkl', assetPath: 'assets/images/rapidKL.png'),
  ];

  final List<Map<String, dynamic>> _walletCards = [
    {
      'title': 'IC Balance',
      'balance': 'RM 154.50',
      'icon': Icons.account_balance_wallet,
      'colors': [Colors.blue[900]!, Colors.blue[700]!],
      'action': 'Reload',
      'isActive': true,
      'logos': ['assets/images/TnG.png'],
      'topIconAsset': 'assets/images/nfc.webp',
    },
    {
      'title': 'Fuel Subsidy',
      'balance': 'RM 200.00',
      'icon': Icons.local_gas_station,
      'colors': [Colors.orange[900]!, Colors.orange[700]!],
      'action': 'History',
      'isActive': true,
      'logos': [],
    },
     {
      'title': 'MyKasih - SAR',
      'balance': 'RM 600.00',
      'icon': Icons.shopping_basket,
      'colors': [Colors.red[900]!, Colors.red[700]!],
      'action': 'View',
      'isActive': true,
      'logos': ['assets/images/Malaysia_Madani_logo.png'],
    },
    {
      'title': 'Madani Credit',
      'balance': 'RM 100.00',
      'icon': Icons.payments,
      'colors': [Colors.purple[900]!, Colors.purple[700]!],
      'action': 'Info',
      'isActive': false,
      'logos': [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadICRequests();
    _loadQuickActions();
  }

  Future<void> _loadQuickActions() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('quick_actions_ids');
    
    if (savedIds != null) {
      final loadedActions = savedIds
          .map((id) => _allAvailableActions.firstWhere(
                (action) => action.id == id,
                orElse: () => _allAvailableActions.first, // Fallback (should ideally be handled better)
              ))
          .toList();
      
      // Filter out any duplicates if they somehow got in, or just trust the list
      // Also ensure we only show valid actions
      setState(() {
        _quickActions = loadedActions.toSet().toList(); 
      });
    }
  }

  Future<void> _saveQuickActions() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _quickActions.map((a) => a.id).toList();
    await prefs.setStringList('quick_actions_ids', ids);
  }

  Future<void> _loadICRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final requestsJson = prefs.getString('ic_replacement_requests');
    if (requestsJson != null) {
      final List<dynamic> decoded = jsonDecode(requestsJson);
      setState(() {
        _icRequests = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('cached_user_name');
    await prefs.clear(); // Clear all
    if (cachedName != null) {
      await prefs.setString('cached_user_name', cachedName); // Restore name
    }
    await prefs.setBool('landing_page_seen', true); // Don't show intro animation again
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    }
  }

  final List<Map<String, String>> _news = [
    {
      'title': 'MyKad Renewal Now Available Online',
      'subtitle': 'Skip the queue - renew your IC from home',
      'date': 'Dec 9, 2024',
    },
    {
      'title': 'Tax Filing Deadline Extended',
      'subtitle': 'LHDN extends e-Filing deadline to May 15',
      'date': 'Dec 8, 2024',
    },
    {
      'title': 'New EPF Withdrawal Scheme',
      'subtitle': 'Flexible Account 3 now open for applications',
      'date': 'Dec 7, 2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.indigo[400], size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Journey',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [Colors.indigo[400]!, Colors.purple[300]!],
                                  ).createShader(const Rect.fromLTWH(0, 0, 150, 20)),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!, width: 2),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/profile.jpeg'), // Placeholder
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: const Icon(Icons.person, size: 24, color: Colors.grey), // Fallback
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Wallet Carousel
              SizedBox(
                height: 200, // Adjusted height for carousel
                child: PageView.builder(
                  controller: _walletController,
                  onPageChanged: (index) => setState(() => _currentWalletIndex = index),
                  itemCount: _walletCards.length,
                  itemBuilder: (context, index) {
                    final card = _walletCards[index];
                    return GestureDetector(
                      onTap: () {
                        if (card['title'] == 'IC Balance') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ICDashboardPage()),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 0), // Side margins for carousel effect
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: card['colors'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (card['colors'] as List<Color>).first.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                card['title'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              card['topIconAsset'] != null
                                  ? Image.asset(card['topIconAsset'], height: 24, fit: BoxFit.contain)
                                  : Icon(card['icon'], color: Colors.white.withOpacity(0.8), size: 22),
                            ],
                          ),
                          Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                const Text(
                                  'Available Balance',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        card['balance'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -1,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (card['logos'] != null && (card['logos'] as List).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: (card['logos'] as List<String>).map((logo) => Padding(
                                            padding: const EdgeInsets.only(left: 6.0),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Image.asset(logo, height: 35, fit: BoxFit.contain),
                                            ), 
                                          )).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                             ],
                          ),
                          Row(
                            children: [
                              if (card['action'] != null && (card['action'] as String).isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    if (card['action'] == 'Reload') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Reload IC Balance'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.touch_app, color: Colors.blue),
                                                title: const Text('Auto-debit from TnG eWallet'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-debit enabled')));
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.payment, color: Colors.green),
                                                title: const Text('Reload from Bank / Card'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirecting to payment gateway...')));
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${card['action']} tapped for ${card['title']}')));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          card['action'] == 'Reload' ? Icons.add : Icons.arrow_forward,
                                          color: Colors.white, size: 16
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          card['action'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (card['isActive'])
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                     color: Colors.black.withOpacity(0.2),
                                     borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                ),
              ),
              const SizedBox(height: 12),
              // Dots Indicator for Wallet
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_walletCards.length, (index) {
                  return Container(
                    width: _currentWalletIndex == index ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentWalletIndex == index ? Colors.blue[900] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 12),

              // Quick Actions
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 24),
                child: QuickActionsGrid(
                      items: _quickActions,
                      onReorder: (newItems) {
                        setState(() {
                          _quickActions = newItems;
                          _saveQuickActions();
                        });
                      },
                      onAddPressed: () {
                         showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add Quick Action',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                      ),
                                      itemCount: _allAvailableActions.length,
                                      itemBuilder: (context, index) {
                                        final item = _allAvailableActions[index];
                                        final isAdded = _quickActions.any((a) => a.id == item.id);
                                        return Opacity(
                                          opacity: isAdded ? 0.4 : 1.0,
                                          child: GestureDetector(
                                            onTap: isAdded
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _quickActions.add(item);
                                                      _saveQuickActions();
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: item.color.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(item.icon, color: item.color, size: 24),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(item.label, style: const TextStyle(fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      onTap: (item) async {
                         if (item.routeName == 'scanner') {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
                            if (result != null && mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scanned: $result')));
                            }
                         } else if (item.routeName == 'lhdn') {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const LHDNPage()));
                         } else if (item.routeName == 'rapidkl') {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const RapidKLPage()));
                         } else {
                           // Handle generic routes or mock pages
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped ${item.label}')));
                         }
                      },
                    ),
              ),
              const SizedBox(height: 12),

              // News Carousel
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Latest News',
                             
                              style: TextStyle(
                                  
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('See all',
                             
                              style: TextStyle(
                                  
                                  fontSize: 14, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: PageView.builder(
                        controller: _newsController,
                        onPageChanged: (index) =>
                            setState(() => _currentNewsIndex = index),
                        itemCount: _news.length,
                        itemBuilder: (context, index) {
                          final news = _news[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(news['date']!,
                                   
                                    style: TextStyle(
                                        
                                        color: Colors.white.withOpacity(0.5),
                                       
                                        fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(news['title']!,
                                   
                                    style: const TextStyle(
                                        
                                        color: Colors.white,
                                       
                                        fontSize: 16,
                                       
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text(news['subtitle']!,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_news.length, (index) {
                        return Container(
                          width: _currentNewsIndex == index ? 20 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _currentNewsIndex == index
                               
                                ? Colors.black
                               
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Services Grid
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('All Services',
                       
                        style: TextStyle(
                            
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                      children: [
                        _buildServiceIcon('JPN', Colors.blue,
                            assetPath: 'assets/images/jpn.png',
                            onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const JPNPage()));
                        }),
                        _buildServiceIcon(
                            'Immigration', Colors.indigo, assetPath: 'assets/images/Immigration.png', onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const ImmigrationPage()));
                            }),
                        _buildServiceIcon(
                            'JPJ', Colors.orange, assetPath: 'assets/images/jpj.png', onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const JPJPage()));
                            }),
                        _buildServiceIcon('LHDN', Colors.green, assetPath: 'assets/images/LHDN.png', onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const LHDNPage()));
                            }),
                        _buildServiceIcon('KWSP', Colors.teal, assetPath: 'assets/images/KWSP.jpg', onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const KWSPPage()));
                            }),
                        _buildServiceIcon(
                            'PERKESO', Colors.cyan, icon: Icons.security, onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const PerkesoPage()));
                            }),
                        _buildServiceIcon(
                            'Print/Scan', Colors.purple, icon: Icons.print, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrintIcPage()));
                            }),
                        _buildServiceIcon(
                            'MOH', Colors.red, assetPath: 'assets/images/MOH.webp', onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const MOHPage()));
                            }),

                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Recent Activity
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Activity',
                           
                            style: TextStyle(
                                
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('View all',
                           
                            style: TextStyle(
                                
                                fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Dynamic IC Replacement Requests
                    ..._icRequests.map((request) {
                      final estimatedReady =
                          DateTime.parse(request['estimatedReady']);
                      return _buildRequestActivityItem(
                        'MyKad Replacement',
                        request['refNumber'],
                        request['pickupLocationName'],
                        request['status'],
                        Icons.credit_card,
                        request['status'] == 'Processing'
                            ? Colors.orange
                            : Colors.green,
                        estimatedDate: 'Est. ${_formatDate(estimatedReady)}',
                        onTap: () =>
                            _showRequestDetailsFromData(context, request),
                      );
                    }),
                    // Other activities
                    _buildActivityItem('MyKad Verified', 'Today, 9:30 AM',
                        Icons.verified, Colors.green),
                    _buildActivityItem('Tax Filing Submitted', 'Dec 5, 2024',
                        Icons.check_circle, Colors.blue),
                    _buildActivityItem('Passport Renewed', 'Nov 28, 2024',
                        Icons.flight, Colors.indigo),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Powered By Footer
              Opacity(
                opacity: 0.6,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Powered by',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Image.asset('assets/images/TnG.png', height: 16),
                      const SizedBox(width: 8),
                      Container(
                        width: 1, 
                        height: 12, 
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Image.asset('assets/images/Malaysia_Madani_logo.png', height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildServiceIcon(String label, Color color,
      {VoidCallback? onTap, IconData? icon, String? assetPath}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: assetPath != null ? const EdgeInsets.all(8) : null,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: assetPath != null
                ? Image.asset(assetPath, fit: BoxFit.contain)
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(date,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  Widget _buildRequestActivityItem(
    String title,
    String refNumber,
    String location,
    String status,
    IconData icon,
    Color statusColor, {
    String estimatedDate = 'Est. Dec 12',
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.orange[700], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(refNumber,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.orange[400], size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Pickup: $location',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(estimatedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.credit_card,
                        color: Colors.orange[700], size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MyKad Replacement',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('JPN-2024-123456',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Processing',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline
                    const Text('Request Timeline',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _buildTimelineItem('Request Submitted',
                        'Dec 10, 2024 • 2:45 AM', true, true),
                    _buildTimelineItem(
                        'Under Review', 'Processing by JPN', true, false),
                    _buildTimelineItem('Printing', 'Waiting', false, false),
                    _buildTimelineItem(
                        'Ready for Collection', 'Est. Dec 12', false, false),

                    const SizedBox(height: 24),

                    // Pickup Location
                    const Text('Pickup Location',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 10),
                              Text('UTC Kuala Lumpur',
                                  style: TextStyle(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Pudu Sentral, Jalan Pudu, 55100 Kuala Lumpur',
                              style: TextStyle(
                                  color: Colors.blue[700], fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.blue[600]),
                              const SizedBox(width: 6),
                              Text('8:00 AM - 10:00 PM (Daily)',
                                  style: TextStyle(
                                      color: Colors.blue[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Request Details
                    const Text('Request Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Reason', 'Change of Address'),
                    _buildDetailRow('Fee', 'RM10'),
                    _buildDetailRow('Submitted', 'Dec 10, 2024'),
                    _buildDetailRow('Expected Ready', 'Dec 12, 2024'),

                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.green[700], size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your virtual ID will update automatically when your physical MyKad is ready.',
                              style: TextStyle(
                                  color: Colors.green[800], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Opening directions...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Get Directions'),
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

  Widget _buildTimelineItem(
      String title, String subtitle, bool isCompleted, bool isFirst) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isFirst)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green[200] : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.black : Colors.grey[500])),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showRequestDetailsFromData(
      BuildContext context, Map<String, dynamic> request) {
    final submittedAt = DateTime.parse(request['submittedAt']);
    final estimatedReady = DateTime.parse(request['estimatedReady']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.credit_card,
                        color: Colors.orange[700], size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MyKad Replacement',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(request['refNumber'],
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: request['status'] == 'Processing'
                          ? Colors.orange
                          : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(request['status'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline
                    const Text('Request Timeline',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                        'Request Submitted',
                        '${_formatDate(submittedAt)} • ${submittedAt.hour}:${submittedAt.minute.toString().padLeft(2, '0')}',
                        true,
                        true),
                    _buildTimelineItem(
                        'Under Review', 'Processing by JPN', true, false),
                    _buildTimelineItem('Printing', 'Waiting', false, false),
                    _buildTimelineItem('Ready for Collection',
                        'Est. ${_formatDate(estimatedReady)}', false, false),

                    const SizedBox(height: 24),

                    // Pickup Location
                    const Text('Pickup Location',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 10),
                              Text(request['pickupLocationName'],
                                  style: TextStyle(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(request['pickupLocationAddress'],
                              style: TextStyle(
                                  color: Colors.blue[700], fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.blue[600]),
                              const SizedBox(width: 6),
                              Text(request['pickupLocationHours'],
                                  style: TextStyle(
                                      color: Colors.blue[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Request Details
                    const Text('Request Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Reason', request['reason']),
                    _buildDetailRow('Fee', request['fee']),
                    _buildDetailRow('Submitted',
                        '${_formatDate(submittedAt)}, ${submittedAt.year}'),
                    _buildDetailRow('Expected Ready',
                        '${_formatDate(estimatedReady)}, ${estimatedReady.year}'),

                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.green[700], size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your virtual ID will update automatically when your physical MyKad is ready.',
                              style: TextStyle(
                                  color: Colors.green[800], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Opening directions...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Get Directions'),
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
