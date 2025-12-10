import 'dart:async';
import 'dart:convert';
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'widgets/glassy_button.dart';
import 'widgets/task_sidebar.dart';
import 'chat_history_sheet.dart';
import 'models/agentic_models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class ChatMessage {
  final String content;
  final bool isUser;
  final String type;
  final List<ChecklistItem>? checklist;
  final List<String>? quickActions;
  final String? url;
  final String? label;
  final String? service;
  final List<Map<String, dynamic>>? locations;
  final double? mapLat;
  final double? mapLng;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    this.type = 'text',
    this.checklist,
    this.quickActions,
    this.url,
    this.label,
    this.service,
    this.locations,
    this.mapLat,
    this.mapLng,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChecklistItem {
  String title;
  bool isChecked;
  ChecklistItem({required this.title, this.isChecked = false});
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isVoiceMode = false;
  bool _isSpeaking = false;
  bool _showSuggestions = true;
  int _mapCounter = 0;
  String? _googleMapsApiKey;
  
  // State for tasks and history
  List<AgenticTask> _activeTasks = [];
  List<ChatSession> _chatHistory = [];
  String _currentSessionId = '';
  bool _isHistoryLoading = false;
  
  String _selectedLanguage = 'english';
  final Map<String, String> _languages = {
    'english': '🇬🇧 English',
    'malay': '🇲🇾 Malay',
    'chinese': '🇨🇳 Chinese',
    'tamil': '🇮🇳 Tamil',
  };

  static const String _backendUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _fetchApiKey();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _fetchActiveTasks();
  }

  Future<void> _fetchApiKey() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/config'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _googleMapsApiKey = data['google_maps_api_key']);
      }
    } catch (e) {
      // Use fallback - maps won't work without key
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessages = {
      'english': "Hi! I'm Journey, your Government Services Assistant. Ask me about IC, passport, tax, or find nearby offices!",
      'malay': "Hai! Saya Journey, pembantu perkhidmatan kerajaan. Tanya pasal IC, pasport, cukai, atau cari pejabat berdekatan!",
      'chinese': "你好！我是Journey，政府服务助手。问我关于IC、护照、税务，或找附近的办事处！",
      'tamil': "வணக்கம்! நான் Journey, அரசு சேவை உதவியாளர். IC, பாஸ்போர்ட், வரி பற்றி கேளுங்கள்!",
    };
    
    _messages.clear();
    _messages.add(ChatMessage(
      content: welcomeMessages[_selectedLanguage]!,
      isUser: false,
      quickActions: _getQuickActions(),
    ));
  }

  void _startNewChat() {
    // Save current session if there are user messages
    final hasUserMessages = _messages.any((m) => m.isUser);
    if (hasUserMessages) {
      _saveCurrentSession();
    }
    // Start fresh
    setState(() {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _showSuggestions = true;
      _addWelcomeMessage();
    });
    _showSnackBar('New chat started');
  }

  Future<void> _saveCurrentSession() async {
    if (_messages.isEmpty) return;
    try {
      final title = _messages.firstWhere((m) => m.isUser, orElse: () => _messages.first).content;
      await http.post(
        Uri.parse('$_backendUrl/history/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': _currentSessionId,
          'user_id': 'default',
          'title': title.length > 50 ? '${title.substring(0, 47)}...' : title,
          'messages': _messages.map((m) => {
            'content': m.content,
            'isUser': m.isUser,
            'timestamp': DateTime.now().toIso8601String(),
          }).toList(),
        }),
      );
    } catch (e) {
      debugPrint('Save session error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<String> _getQuickActions() {
    final actions = {
      'english': ["🪪 I lost my IC", "📍 Find nearest JPN", "🌐 JPN Website", "📘 Lost passport"],
      'malay': ["🪪 IC saya hilang", "📍 Cari JPN", "🌐 Laman web JPN", "📘 Pasport hilang"],
      'chinese': ["🪪 IC不见了", "📍 找附近JPN", "🌐 JPN网站", "📘 护照丢了"],
      'tamil': ["🪪 IC காணாமல்", "📍 JPN கண்டுபிடி", "🌐 JPN இணையம்", "📘 பாஸ்போர்ட்"],
    };
    return actions[_selectedLanguage]!;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _speakText(String text) async {
    if (!_isVoiceMode || text.isEmpty) return;
    setState(() => _isSpeaking = true);
    
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'language': _selectedLanguage}),
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'audio/mpeg');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final audio = html.AudioElement(url);
        audio.onEnded.listen((_) { html.Url.revokeObjectUrl(url); if (mounted) setState(() => _isSpeaking = false); });
        audio.onError.listen((_) { html.Url.revokeObjectUrl(url); if (mounted) setState(() => _isSpeaking = false); });
        await audio.play();
      } else {
        setState(() => _isSpeaking = false);
      }
    } catch (e) {
      setState(() => _isSpeaking = false);
    }
  }

  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

  String _registerMapView(double lat, double lng, String query) {
    final viewId = 'google-map-${_mapCounter++}';
    final iframe = html.IFrameElement()
      ..src = 'https://www.google.com/maps/embed/v1/search?key=$_googleMapsApiKey&q=$query&center=$lat,$lng&zoom=13'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;
    
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) => iframe);
    return viewId;
  }

  Future<void> _findNearbyOffice(String service) async {
    setState(() => _isLoading = true);
    
    try {
      final position = await html.window.navigator.geolocation.getCurrentPosition();
      final lat = position.coords!.latitude!;
      final lng = position.coords!.longitude!;
      
      final response = await http.post(
        Uri.parse('$_backendUrl/find-office'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'service': service, 'latitude': lat, 'longitude': lng}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List).map((e) => e as Map<String, dynamic>).toList();
        
        setState(() {
          _messages.add(ChatMessage(
            content: "Found ${results.length} nearby ${service.toUpperCase()} offices:",
            isUser: false,
            type: 'locations',
            locations: results,
            mapLat: lat.toDouble(),
            mapLng: lng.toDouble(),
            url: data['website'],
            label: 'Visit Official Website',
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'API error');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(content: "Error: $e", isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _sendMessage([String? overrideMessage]) async {
    final text = overrideMessage ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _isLoading = true;
      _showSuggestions = false;
    });
    _controller.clear();
    _scrollToBottom();

    // Check for agentic task triggers
    final lowerText = text.toLowerCase();
    String? agenticTaskType;
    
    if (lowerText.contains('visa') || lowerText.contains('apply for visa')) {
      agenticTaskType = 'visa_application';
    } else if (lowerText.contains('foreign worker') || lowerText.contains('worker permit')) {
      agenticTaskType = 'foreign_worker_permit';
    } else if (lowerText.contains('renew') && lowerText.contains('passport')) {
      agenticTaskType = 'passport_renewal';
    } else if ((lowerText.contains('lost') || lowerText.contains('replace')) && lowerText.contains('ic')) {
      agenticTaskType = 'ic_replacement';
    } else if (lowerText.contains('tax') && (lowerText.contains('file') || lowerText.contains('filing') || lowerText.contains('pay'))) {
      agenticTaskType = 'tax_filing';
    }

    if (agenticTaskType != null) {
      setState(() => _isLoading = false);
      await _startAgenticTask(agenticTaskType);
      return;
    }

    try {
      final responseData = await _apiService.chat(text, language: _selectedLanguage);
      final responseText = responseData['response'] ?? 'No response';
      final type = responseData['type'] ?? 'text';

      if (type == 'location' && responseData['service'] != null) {
        setState(() {
          _messages.add(ChatMessage(content: responseText, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
        await _findNearbyOffice(responseData['service']);
        return;
      }

      List<ChecklistItem>? checklistItems;
      if (type == 'checklist' && responseData['checklist'] != null) {
        checklistItems = (responseData['checklist'] as List).map((item) => ChecklistItem(title: item.toString())).toList();
      }

      setState(() {
        _messages.add(ChatMessage(
          content: responseText,
          isUser: false,
          type: type,
          checklist: checklistItems,
          url: responseData['url'],
          label: responseData['label'],
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      if (_isVoiceMode) _speakText(responseText);
      
      // Auto-save to history after each exchange
      _saveChatHistory();
    } catch (e) {
      setState(() { _messages.add(ChatMessage(content: "Unable to connect: $e", isUser: false)); _isLoading = false; });
      _scrollToBottom();
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ..._languages.entries.map((e) => ListTile(
              leading: Text(e.value.split(' ')[0], style: const TextStyle(fontSize: 28)),
              title: Text(e.value.split(' ')[1]),
              trailing: _selectedLanguage == e.key ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () { setState(() { _selectedLanguage = e.key; _addWelcomeMessage(); }); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUserMessages = _messages.any((m) => m.isUser);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main chat area
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeroHeader(),
                  if (_showSuggestions && !hasUserMessages) _buildSuggestionChips(),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessage(_messages[index]),
                    ),
                  ),
                  if (_isLoading) _buildTyping(),
                  _buildInput(),
                ],
              ),
            ),
          ),
          // Floating task button
          TaskButton(
            tasks: _activeTasks,
            onCancelTask: _cancelTask,
            onAdvanceTask: _advanceTask,
            onSelectTask: _selectTask,
          ),
        ],
      ),
    );
  }

  /// Build formatted text with emoji colors, bold (**text**), and italic (*text*)
  Widget _buildFormattedText(String text, bool isUser) {
    final List<InlineSpan> spans = [];
    final baseStyle = TextStyle(
      color: isUser ? Colors.white : Colors.black87,
      fontSize: 16,
      height: 1.5,
      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
    );
    
    // Pattern for **bold**, *italic*, and emojis
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*)|'  // **bold**
      r'(\*[^*]+\*)|'       // *italic*
      r'([\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FAD0}-\u{1FAFF}]+)|'  // emojis
      r'([^*\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FAD0}-\u{1FAFF}]+)',  // regular text
      unicode: true,
    );
    
    final matches = pattern.allMatches(text);
    
    for (final match in matches) {
      final matchedText = match.group(0) ?? '';
      
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        // Bold text
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.w800),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length > 2) {
        // Italic text
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (_isEmoji(matchedText)) {
        // Emoji - don't apply color override, let native emoji colors show
        spans.add(TextSpan(
          text: matchedText,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ));
      } else {
        // Regular text
        spans.add(TextSpan(text: matchedText, style: baseStyle));
      }
    }
    
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
  
  bool _isEmoji(String text) {
  return RegExp(
    r'^[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1FAD0}-\u{1FAFF}]+$',
    unicode: true,
  ).hasMatch(text);
}

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: msg.isUser ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(msg.content, msg.isUser),
                  if (msg.checklist != null) ...[
                    const SizedBox(height: 12),
                    ...msg.checklist!.map((item) => _buildCheckItem(item)),
                  ],
                  if (msg.locations != null && msg.mapLat != null && msg.mapLng != null) ...[
                    const SizedBox(height: 12),
                    _buildEmbeddedMap(msg.mapLat!, msg.mapLng!, msg.service ?? 'JPN'),
                  ],
                  if (msg.locations != null) ...[
                    const SizedBox(height: 12),
                    ...msg.locations!.take(3).map((loc) => _buildLocationCard(loc)),
                  ],
                  if (msg.url != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openUrl(msg.url!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              msg.label ?? 'Open Link',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (msg.quickActions != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: msg.quickActions!
                      .map(
                        (a) => GestureDetector(
                          onTap: () => _sendMessage(a.replaceAll(RegExp(r'[^\w\s\u4e00-\u9fff\u0B80-\u0BFF]'), '').trim()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(a, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedMap(double lat, double lng, String query) {
    final viewId = _registerMapView(lat, lng, query);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: HtmlElementView(viewType: viewId),
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> loc) {
    return GestureDetector(
      onTap: () => _openUrl(loc['maps_url'] ?? ''),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.location_on, color: Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(loc['address'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            if (loc['rating'] != null) Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text('${loc['rating']}', style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
          ])),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildCheckItem(ChecklistItem item) {
    return GestureDetector(
      onTap: () => setState(() => item.isChecked = true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isChecked ? Colors.green : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: item.isChecked ? Colors.green : Colors.white.withOpacity(0.3), width: 2),
              ),
              child: item.isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(item.isChecked ? 0.5 : 0.95),
                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: _selectedLanguage == 'malay'
                        ? 'Taip mesej...'
                        : _selectedLanguage == 'chinese'
                            ? '输入信息...'
                            : 'Ask Journey anything...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                setState(() => _isVoiceMode = !_isVoiceMode);
                _showSnackBar(_isVoiceMode ? '🎤 Voice ON' : '🔇 Voice OFF');
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isVoiceMode ? Colors.grey[200] : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(_isVoiceMode ? Icons.mic : Icons.mic_none, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Journey AI',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    child: const Text(
                      'beta',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              // New Chat & History buttons
              Row(
                children: [
                  // New Chat button
                  GestureDetector(
                    onTap: _startNewChat,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(
                        Icons.add_comment,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // History button
                  GestureDetector(
                    onTap: _showChatHistory,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(
                        Icons.history,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask Journey about government services, payments, identity, and more.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      '🪪 I lost my IC',
      '💳 How do I pay tax?',
      '📄 Renew my passport',
      '🛂 Apply for visa',
      '👷 Foreign worker permit',
      '📍 Find nearest JPN',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final s = suggestions[index];
            return GlassyButton(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              borderRadius: BorderRadius.circular(14),
              onPressed: () => _sendMessage(s),
              child: Text(
                s,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============== TASK MANAGEMENT METHODS ==============

  Future<void> _fetchActiveTasks() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/tasks'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasksList = (data['tasks'] as List)
            .map((t) => AgenticTask.fromJson(t))
            .where((t) => t.isActive)
            .toList();
        setState(() => _activeTasks = tasksList);
      }
    } catch (e) {
      // Silent fail - tasks are optional
    }
  }

  Future<void> _startAgenticTask(String taskType) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/task/start-with-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task_type': taskType}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if validation failed
        if (data['success'] == false) {
          // Show what's missing
          String content = "⚠️ Cannot start this task yet\n\n";
          
          final validation = data['validation'];
          final missingFields = data['missing_info']['fields'] as List? ?? [];
          final missingDocs = data['missing_info']['documents'] as List? ?? [];
          final securityIssues = validation?['security_issues'] as List? ?? [];
          
          // Show security level issues first
          if (securityIssues.isNotEmpty) {
            content += "🔒 Security Level Required:\n";
            for (var issue in securityIssues) {
              if (issue['issue'] == 'insufficient_security_level') {
                content += "  Current: ${issue['current_level']} → Required: ${issue['required_level']}\n";
              } else if (issue['issue'] == 'missing_security_requirement') {
                content += "  ⚡ Need: ${issue['label']}\n";
              }
            }
            content += "\n";
          }
          
          // Show missing fields
          if (missingFields.isNotEmpty) {
            content += "📋 Missing Information:\n";
            for (var field in missingFields) {
              content += "  ❌ ${field['label']}\n";
            }
            content += "\n";
          }
          
          // Show missing documents
          if (missingDocs.isNotEmpty) {
            content += "📄 Missing Documents:\n";
            for (var doc in missingDocs) {
              content += "  📎 ${doc['label']}\n";
            }
            content += "\n";
          }
          
          // Show auto-verification results if available
          final autoVerification = data['auto_verification'];
          if (autoVerification != null) {
            final results = autoVerification['results'] as List? ?? [];
            if (results.isNotEmpty) {
              content += "🤖 Agent Verification Results:\n";
              for (var result in results) {
                content += "  ${result['message']}\n";
              }
              content += "\n";
              final summary = autoVerification['summary'];
              if (summary != null) {
                content += "📊 Checks: ${summary['passed']}/${summary['total_checks']} passed";
                if (summary['warnings'] > 0) {
                  content += " (${summary['warnings']} warnings)";
                }
                content += "\n";
              }
            }
          } else if (validation != null) {
            content += "📊 Profile completion: ${validation['completion_percentage']}%";
          }
          
          content += "\nPlease update your profile in the ID page to continue.";
          
          setState(() {
            _messages.add(ChatMessage(content: content, isUser: false));
          });
          _scrollToBottom();
          return;
        }
        
        // Task created successfully - show verification summary
        final task = AgenticTask.fromJson(data['task']);
        final autoVerification = data['auto_verification'];
        
        String successContent = "${task.icon} Started: ${task.name}\n\n";
        
        // Show what was auto-verified
        if (autoVerification != null) {
          successContent += "🤖 Agent Auto-Verified:\n";
          final results = autoVerification['results'] as List? ?? [];
          for (var result in results) {
            successContent += "${result['message']}\n";
          }
          final summary = autoVerification['summary'];
          if (summary != null) {
            successContent += "\n✅ All ${summary['total_checks']} checks passed!\n";
          }
        }
        
        // Show skipped step info
        if (data['skipped_step'] != null) {
          successContent += "\n⏭️ ${data['skipped_step']}\n";
        }
        
        // Show current step
        final currentStep = data['current_step'];
        if (currentStep != null) {
          successContent += "\n📍 Now at: ${currentStep['title']}\n${currentStep['description'] ?? ''}\n";
        }
        
        successContent += "\nClick the task button to track progress 📋";
        
        setState(() {
          _activeTasks.add(task);
          _messages.add(ChatMessage(
            content: successContent,
            isUser: false,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showSnackBar('Failed to start task: $e');
    }
  }

  Future<void> _cancelTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/task/$taskId/cancel'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _activeTasks.removeWhere((t) => t.id == taskId);
        });
        _showSnackBar('Task cancelled');
      }
    } catch (e) {
      _showSnackBar('Failed to cancel task: $e');
    }
  }

  Future<void> _advanceTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/task/$taskId/advance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task_id': taskId}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['completed'] == true) {
          setState(() {
            _activeTasks.removeWhere((t) => t.id == taskId);
            _messages.add(ChatMessage(
              content: "🎉 ${data['message']}",
              isUser: false,
            ));
          });
          _scrollToBottom();
        } else {
          final task = AgenticTask.fromJson(data['task']);
          setState(() {
            final index = _activeTasks.indexWhere((t) => t.id == taskId);
            if (index >= 0) {
              _activeTasks[index] = task;
            }
          });
          
          // Add progress message
          final nextStep = data['next_step'];
          if (nextStep != null) {
            setState(() {
              _messages.add(ChatMessage(
                content: "✅ ${data['message']}\n\n${nextStep['description'] ?? ''}",
                isUser: false,
              ));
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      _showSnackBar('Failed to advance task: $e');
    }
  }

  void _selectTask(String taskId) {
    final task = _activeTasks.firstWhere((t) => t.id == taskId, orElse: () => _activeTasks.first);
    final step = task.currentStepDetails;
    
    if (step != null) {
      String content = "${task.icon} ${task.name}\n\n";
      content += "📍 Step ${task.currentStep}: ${step.title}\n";
      content += "${step.description}\n";
      
      // Show autofill info
      if (step.hasAutofill) {
        content += "\n✨ Your info will be auto-filled from your digital ID";
      }
      
      // Show checklist
      if (step.hasChecklist) {
        content += "\n\n📋 Required:\n";
        for (var item in step.checklist!) {
          content += "  • $item\n";
        }
      }
      
      // Show required docs
      if (step.requiredDocs != null) {
        content += "\n📎 Documents needed:\n";
        for (var doc in step.requiredDocs!) {
          content += "  • $doc\n";
        }
      }

      setState(() {
        _messages.add(ChatMessage(
          content: content,
          isUser: false,
          url: step.url,
          label: step.actionLabel ?? 'Open Portal',
        ));
      });
      _scrollToBottom();
    }
  }

  // ============== HISTORY MANAGEMENT METHODS ==============

  Future<void> _fetchChatHistory() async {
    setState(() => _isHistoryLoading = true);
    
    try {
      final response = await http.get(Uri.parse('$_backendUrl/history'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = (data['sessions'] as List)
            .map((s) => ChatSession.fromJson(s))
            .toList();
        setState(() {
          _chatHistory = sessions;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _saveChatHistory() async {
    if (_messages.isEmpty) return;
    
    try {
      final messagesData = _messages.map((m) => {
        'content': m.content,
        'isUser': m.isUser,
        'type': m.type,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList();
      
      await http.post(
        Uri.parse('$_backendUrl/history/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': _currentSessionId,
          'messages': messagesData,
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  void _showChatHistory() async {
    await _fetchChatHistory();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatHistorySheet(
        sessions: _chatHistory,
        isLoading: _isHistoryLoading,
        onSelectSession: _loadChatSession,
        onDeleteSession: _deleteHistorySession,
        onClearAll: _clearAllHistory,
      ),
    );
  }

  Future<void> _loadChatSession(ChatSession session) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/history/${session.id}'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List).map((m) => ChatMessage(
          content: m['content'] ?? '',
          isUser: m['isUser'] ?? false,
          type: m['type'] ?? 'text',
        )).toList();
        
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _currentSessionId = session.id;
          _showSuggestions = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showSnackBar('Failed to load session');
    }
  }

  Future<void> _deleteHistorySession(String sessionId) async {
    try {
      await http.delete(Uri.parse('$_backendUrl/history/$sessionId'));
      setState(() {
        _chatHistory.removeWhere((s) => s.id == sessionId);
      });
    } catch (e) {
      _showSnackBar('Failed to delete session');
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      await http.delete(Uri.parse('$_backendUrl/history'));
      setState(() => _chatHistory.clear());
      _showSnackBar('History cleared');
    } catch (e) {
      _showSnackBar('Failed to clear history');
    }
  }

  // Auto-save when sending messages
  @override
  void dispose() {
    _saveChatHistory();
    super.dispose();
  }
}
