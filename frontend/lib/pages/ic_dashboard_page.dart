import 'package:flutter/material.dart';
import 'payment_page.dart';

class ICDashboardPage extends StatefulWidget {
  const ICDashboardPage({super.key});

  @override
  State<ICDashboardPage> createState() => _ICDashboardPageState();
}

class _ICDashboardPageState extends State<ICDashboardPage> {
  // Mock Data
  double _balance = 154.50;
  final List<Map<String, dynamic>> _transactions = [
    {'title': 'Toll Payment (LDP)', 'date': 'Today, 8:30 AM', 'amount': '-RM 2.10', 'type': 'debit'},
    {'title': 'Reload via FPX', 'date': 'Yesterday, 6:00 PM', 'amount': '+RM 50.00', 'type': 'credit'},
    {'title': 'Toll Payment (Sprint)', 'date': 'Yesterday, 8:45 AM', 'amount': '-RM 2.50', 'type': 'debit'},
    {'title': 'Tealive Bangsar', 'date': '10 Dec, 1:20 PM', 'amount': '-RM 12.90', 'type': 'debit'},
    {'title': 'Parking (Mid Valley)', 'date': '09 Dec, 2:00 PM', 'amount': '-RM 5.00', 'type': 'debit'},
    {'title': 'Auto Reload', 'date': '08 Dec, 9:00 AM', 'amount': '+RM 100.00', 'type': 'credit'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Match app bg
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MyKad Balance',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTransactionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'IC Balance',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Image.asset('assets/images/nfc.webp', height: 24, color: Colors.white, errorBuilder: (_,__,___) => const Icon(Icons.nfc, color: Colors.white)),
            ],
          ),
          const Spacer(),
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${_balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              Image.asset('assets/images/TnG.png', height: 28, errorBuilder: (_,__,___) => const Text('TNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                label: 'Reload',
                icon: Icons.add,
                onTap: _showReloadOptions,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                label: 'Auto Debit',
                icon: Icons.autorenew,
                isOutlined: true,
                onTap: _showAutoDebitSettings, 
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Expanded(
      child: Material(
        color: isOutlined ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: isOutlined ? Colors.white : const Color(0xFF0052D4)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isOutlined ? Colors.white : const Color(0xFF0052D4),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isCredit = tx['type'] == 'credit';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
             boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCredit ? Colors.green[50] : Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx['date'],
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                tx['amount'],
                style: TextStyle(
                  color: isCredit ? Colors.green : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReloadOptions() {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Reload Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildAmountOption(10),
                const SizedBox(width: 12),
                _buildAmountOption(50),
                const SizedBox(width: 12),
                _buildAmountOption(100),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Default to 50 if nothing selected logic could be added, 
                // but for now let's just push PaymentPage with default or selected
                 Navigator.pop(context); // Close sheet
                 _navigateToPayment('50.00'); // Default for demo
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052D4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reload RM 50.00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAmountOption(int amount) {
      return Expanded(
        child: InkWell(
            onTap: () {
                 Navigator.pop(context);
                _navigateToPayment('$amount.00');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text('RM $amount', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ),
        ),
      );
  }

  void _navigateToPayment(String amount) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PaymentPage(
                paymentDetails: {'task': 'TnG Reload', 'amount': 'RM $amount'},
                onPaymentComplete: (success) {
                    if (success) {
                        setState(() {
                             _balance += double.parse(amount);
                             _transactions.insert(0, {
                                'title': 'Manual Reload', 
                                'date': 'Just now', 
                                'amount': '+RM $amount', 
                                'type': 'credit'
                             });
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reload Successful!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
                        );
                    }
                },
            ),
        ),
      );
  }

  void _showAutoDebitSettings() {
      // Mock Auto Debit Setup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Auto Debit'),
            content: const Text('Link your bank account to automatically reload when balance is low.'),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                         Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Auto Debit Enabled!'), backgroundColor: Colors.green)
                        );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052D4)),
                    child: const Text('Enable', style: TextStyle(color: Colors.white)),
                ),
            ],
        ),
      );
  }
}
