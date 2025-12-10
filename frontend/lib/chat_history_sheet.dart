import 'package:flutter/material.dart';
import 'models/agentic_models.dart';

/// Modal sheet for viewing and selecting chat history
class ChatHistorySheet extends StatelessWidget {
  final List<ChatSession> sessions;
  final Function(ChatSession) onSelectSession;
  final Function(String sessionId) onDeleteSession;
  final VoidCallback onClearAll;
  final bool isLoading;

  const ChatHistorySheet({
    super.key,
    required this.sessions,
    required this.onSelectSession,
    required this.onDeleteSession,
    required this.onClearAll,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chat History',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (sessions.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showClearAllConfirmation(context),
                    icon: Icon(
                      Icons.delete_sweep,
                      size: 18,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    label: Text(
                      'Clear All',
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
          ),
          
          // Content
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : sessions.isEmpty
                    ? _buildEmptyState()
                    : _buildSessionList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Colors.white.withOpacity(0.6),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading history...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'No chat history',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your conversations with Journey will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(context, session);
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, ChatSession session) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete,
          color: Colors.red.withOpacity(0.8),
        ),
      ),
      confirmDismiss: (direction) => _confirmDelete(context, session),
      onDismissed: (direction) => onDeleteSession(session.id),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          onSelectSession(session);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Chat icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat,
                  color: Colors.blue.withOpacity(0.8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              
              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.preview.isNotEmpty
                          ? session.preview
                          : 'Conversation',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.formattedDate,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.message,
                          size: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.messageCount} messages',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, ChatSession session) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete conversation?',
          style: TextStyle(color: Colors.white.withOpacity(0.95)),
        ),
        content: Text(
          'This conversation will be permanently deleted.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear all history?',
          style: TextStyle(color: Colors.white.withOpacity(0.95)),
        ),
        content: Text(
          'All ${sessions.length} conversations will be permanently deleted.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClearAll();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
