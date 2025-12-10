import 'package:flutter/material.dart';
import 'widgets/glassy_button.dart';

class JPJPage extends StatefulWidget {
  const JPJPage({super.key});

  @override
  State<JPJPage> createState() => _JPJPageState();
}

class _JPJPageState extends State<JPJPage> {
  // Mock Data
  final List<Map<String, dynamic>> _branches = [
    {'name': 'JPJ Wangsa Maju', 'dist': '2.5 km'},
    {'name': 'JPJ Padang Jawa', 'dist': '15.0 km'},
    {'name': 'UTC Pudu Sentral', 'dist': '8.2 km'},
    {'name': 'UTC Keramat', 'dist': '5.1 km'},
    {'name': 'JPJ Bandar Sri Permaisuri', 'dist': '10.5 km'},
  ];

  final List<Map<String, dynamic>> _services = [
    {'icon': Icons.search, 'name': 'License Enquiry', 'price': 'Free', 'type': 'appointment'},
    {'icon': Icons.badge, 'name': 'Renew License', 'price': 'RM 60.00', 'type': 'online'},
    {'icon': Icons.warning, 'name': 'Lost License', 'price': 'RM 20.00', 'type': 'standard'},
    {'icon': Icons.receipt, 'name': 'Pay Saman', 'price': 'Check', 'type': 'online'},
    {'icon': Icons.directions_car, 'name': 'Road Tax Renew', 'price': 'RM 90.00', 'type': 'standard'},
    {'icon': Icons.assignment, 'name': 'Transfer Ownership', 'price': 'RM 100.00', 'type': 'appointment'},
  ];

  // State
  Map<String, dynamic> _selectedBranch = {'name': 'JPJ Wangsa Maju', 'dist': '2.5 km'};
  Map<String, dynamic>? _selectedService;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  bool get _isToday => 
      _selectedDate.year == DateTime.now().year && 
      _selectedDate.month == DateTime.now().month && 
      _selectedDate.day == DateTime.now().day;

  // Logic: Queue only available today starting 6am
  bool get _canJoinQueue {
    if (!_isToday) return false;
    final now = TimeOfDay.now();
    return (now.hour >= 6); 
  }

  void _showBranchPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Branch',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[200]),
              ..._branches.map((branch) => ListTile(
                leading: const Icon(Icons.location_on, color: Colors.red),
                title: Text(branch['name']),
                subtitle: Text('${branch['dist']} away'),
                trailing: _selectedBranch['name'] == branch['name'] 
                    ? const Icon(Icons.check, color: Colors.blue) 
                    : null,
                onTap: () {
                  setState(() => _selectedBranch = branch);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time on date change
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (_isToday && picked.hour < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue opens at 6:00 AM daily.')),
        );
        return;
      }
      setState(() => _selectedTime = picked);
    }
  }

  void _handleBooking() {
    if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service first.')),
        );
        return;
    }

    // Online Service Flow
    if (_selectedService!['type'] == 'online') {
      _showOnlineDialog();
      return;
    }
    
    // Standard/Appointment Flow
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(
              _canJoinQueue && _isToday ? 'Queue Ticket Issued' : 'Appointment Set',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
             Text(
              'Branch: ${_selectedBranch['name']}', 
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
             Text('Service: ${_selectedService!['name']}'),
             Text('Date: ${_selectedDate.toString().split(' ')[0]}'),
             if (_selectedTime != null) Text('Time: ${_selectedTime!.format(context)}'),
             const SizedBox(height: 16),
             if (_canJoinQueue && _isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Your Number: JPJ-1088',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Service Page
            }, 
            child: const Text('Done'),
          )
        ],
      )
    );
  }

  void _showOnlineDialog() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.public, color: Colors.blue[600], size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text(
              'Online Service',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
             Text(
              'You are about to proceed to the online ${_selectedService!['name']} portal.', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          GlassyButton(
            onPressed: () {
              Navigator.pop(context);
              // Launch URL logic here in real app
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening online portal...')),
              );
            }, 
            child: const Text('Proceed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          )
        ],
      )
    );
  }

  String _getButtonText() {
    if (_selectedService == null) return 'Select a Service';
    if (_selectedService!['type'] == 'online') return 'Proceed Online';
    if (_isToday && _canJoinQueue) return 'Join Queue Now';
    return 'Book Appointment';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Branch Selection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'JPJ Services',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showBranchPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedBranch['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${_selectedBranch['dist']} away",
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DATE & TIME (Moved to Top)
                    const Text(
                      'Date & Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDateTimePickerRow(
                            Icons.calendar_today, 
                            'Date', 
                            "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}",
                            _selectDate,
                          ),
                          const Divider(height: 24),
                          _buildDateTimePickerRow(
                            Icons.access_time, 
                            'Time', 
                            _selectedTime?.format(context) ?? 'Select Time',
                            _selectTime,
                          ),
                        ],
                      ),
                    ),
                    if (_isToday && !_canJoinQueue)
                       Container(
                         margin: const EdgeInsets.only(top: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.red[50],
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.red[100]!),
                         ),
                         child: Row(
                           children: [
                             Icon(Icons.info_outline, color: Colors.red[700], size: 18),
                             const SizedBox(width: 8),
                             Expanded(child: Text('Queue opens at 6:00 AM daily.', style: TextStyle(color: Colors.red[800], fontSize: 12))),
                           ],
                         ),
                       ),

                    const SizedBox(height: 24),

                    // SERVICES GRID
                    const Text(
                      'Select Service',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        final isSelected = _selectedService == service;
                        final isOnline = service['type'] == 'online';
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedService = service),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.orange : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.blue[50] : Colors.orange[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(service['icon'], color: isOnline ? Colors.blue : Colors.orange, size: 28),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  service['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isOnline) 
                                      Icon(Icons.language, size: 10, color: Colors.grey[600]),
                                    if (isOnline) const SizedBox(width: 4),
                                    Text(
                                      isOnline ? 'Online' : service['price'],
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // 3. Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: GlassyButton(
                  onPressed: _selectedService == null ? null : _handleBooking,
                  child: Text(
                    _getButtonText(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePickerRow(IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
}
