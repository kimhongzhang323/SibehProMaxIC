import 'package:flutter/material.dart';

class RapidKLPage extends StatefulWidget {
  const RapidKLPage({super.key});

  @override
  State<RapidKLPage> createState() => _RapidKLPageState();
}

class _RapidKLPageState extends State<RapidKLPage> {
  final List<Map<String, dynamic>> _passes = [
    {
      'title': 'My50 Unlimited Pass',
      'price': 'RM 50.00',
      'duration': '30 Days',
      'description': 'Unlimited rides on Rapid KL rail & bus services for 30 days.',
      'color': Colors.blue[900],
      'icon': Icons.directions_bus,
      'isPopular': true,
    },
    {
      'title': 'KL Travel Pass',
      'price': 'RM 75.00',
      'duration': '2 Days',
      'description': 'Unlimited rail rides for 2 days + KLIA Ekspres single trip.',
      'color': Colors.purple[800],
      'icon': Icons.train,
      'isPopular': false,
    },
    {
      'title': 'City Pass (1 Day)',
      'price': 'RM 15.00',
      'duration': '1 Day',
      'description': 'Unlimited rides on LRT, MRT, Monorail & BRT for 1 day.',
      'color': Colors.orange[800],
      'icon': Icons.location_city,
      'isPopular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('RapidKL Passes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.blue[50],
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.blue[100]!),
               ),
               child: Row(
                 children: [
                   Icon(Icons.info_outline, color: Colors.blue[800], size: 24),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       'Passes are activated upon first tap at any gate or bus reader.',
                       style: TextStyle(color: Colors.blue[900], fontSize: 13),
                     ),
                   ),
                 ],
               ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Passes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              itemCount: _passes.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final pass = _passes[index];
                return _buildPassCard(pass);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassCard(Map<String, dynamic> pass) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showConfirmationDialog(pass),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (pass['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(pass['icon'], color: pass['color'], size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pass['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (pass['isPopular'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'POPULAR',
                                    style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pass['description'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[100]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('VALIDITY', style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
                         Text(pass['duration'], style: const TextStyle(fontWeight: FontWeight.w600)),
                       ],
                    ),
                    Text(
                      pass['price'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: pass['color'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(Map<String, dynamic> pass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${pass['title']}?'),
        content: Text('This will charge ${pass['price']} to your default payment method.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully subscribed to ${pass['title']}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pass['color'],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
