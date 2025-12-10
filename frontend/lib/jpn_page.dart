import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'replace_ic_page.dart';

class JPNPage extends StatefulWidget {
  const JPNPage({super.key});

  @override
  State<JPNPage> createState() => _JPNPageState();
}

class _JPNPageState extends State<JPNPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _services = [
    {
      'icon': Icons.credit_card,
      'title': 'MyKad (IC)',
      'subtitle': 'Apply, renew, or replace your identity card',
      'color': Colors.blue,
    },
    {
      'icon': Icons.child_care,
      'title': 'Birth Certificate',
      'subtitle': 'Register birth or get certified copies',
      'color': Colors.pink,
    },
    {
      'icon': Icons.favorite,
      'title': 'Marriage Registration',
      'subtitle': 'Register your marriage (Non-Muslim)',
      'color': Colors.red,
    },
    {
      'icon': Icons.dangerous,
      'title': 'Death Certificate',
      'subtitle': 'Register death and obtain certificates',
      'color': Colors.grey,
    },
    {
      'icon': Icons.people,
      'title': 'Citizenship',
      'subtitle': 'Apply for Malaysian citizenship',
      'color': Colors.indigo,
    },
    {
      'icon': Icons.person_add,
      'title': 'Adoption',
      'subtitle': 'Register adoption of a child',
      'color': Colors.teal,
    },
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I replace a lost MyKad?',
      'answer':
          '1. File a police report at any police station\n2. Visit any JPN branch with the police report\n3. Bring your birth certificate copy and 2 passport photos\n4. Pay RM10 (first loss) or RM100 (second loss)\n5. Collection within 24 hours to 2 weeks',
    },
    {
      'question': 'What documents are needed for MyKad renewal?',
      'answer':
          '• Current MyKad\n• Recent passport-size photo\n• RM5 processing fee\n• Book appointment online at www.jpn.gov.my',
    },
    {
      'question': 'How to register a newborn?',
      'answer':
          '• Register within 60 days of birth (free)\n• Late registration incurs penalties\n• Required: Hospital birth confirmation, parents\' ICs, marriage certificate\n• Visit nearest JPN office',
    },
    {
      'question': 'How to change address on MyKad?',
      'answer':
          '• Visit any JPN branch within 30 days of moving\n• Bring MyKad and proof of new address (utility bill/tenancy agreement)\n• Service is FREE',
    },
  ];

  final List<Map<String, String>> _branches = [
    {
      'name': 'JPN Putrajaya (HQ)',
      'address': 'No. 20, Persiaran Perdana, Presint 2, 62551 Putrajaya',
      'hours': '8:00 AM - 5:00 PM'
    },
    {
      'name': 'JPN Kuala Lumpur',
      'address': 'Kompleks JPN, Jalan Duta, 50480 Kuala Lumpur',
      'hours': '8:30 AM - 4:30 PM'
    },
    {
      'name': 'UTC Kuala Lumpur',
      'address': 'Pudu Sentral, Jalan Pudu, 55100 Kuala Lumpur',
      'hours': '8:00 AM - 10:00 PM'
    },
    {
      'name': 'JPN Petaling Jaya',
      'address': 'Jalan Othman, Seksyen 3, 46000 Petaling Jaya',
      'hours': '8:00 AM - 5:00 PM'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.blue[700],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[800]!, Colors.blue[600]!],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Government Agency',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Jabatan Pendaftaran Negara',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'National Registration Department (NRD)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Quick Info Cards
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      Icons.phone,
                      'Hotline',
                      '03-8000 8000',
                      Colors.green,
                      () => _launchUrl('tel:0380008000'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      Icons.language,
                      'Website',
                      'jpn.gov.my',
                      Colors.blue,
                      () => _launchUrl('https://www.jpn.gov.my'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue[700],
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Services'),
                  Tab(text: 'FAQ'),
                  Tab(text: 'Locations'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildFAQTab(),
                _buildLocationsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchUrl('https://www.jpn.gov.my'),
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.calendar_today, color: Colors.white),
        label: const Text('Book Appointment',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (service['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(service['icon'] as IconData,
                  color: service['color'] as Color),
            ),
            title: Text(
              service['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                service['subtitle'] as String,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () {
              // Navigate to Replace IC page for MyKad service
              if (service['title'] == 'MyKad (IC)') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReplaceICPage()),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFAQTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.help_outline, color: Colors.blue[700], size: 20),
            ),
            title: Text(
              faq['question'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  faq['answer'] as String,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _branches.length,
      itemBuilder: (context, index) {
        final branch = _branches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.location_on, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch['name']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                branch['hours']!,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.map, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch['address']!,
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(
                            'https://www.google.com/maps/search/${Uri.encodeComponent(branch['address']!)}'),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Get Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[200]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl('tel:0380008000'),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
