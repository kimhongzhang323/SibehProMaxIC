/// Agentic task data model
class AgenticTask {
  final String id;
  final String type;
  final String name;
  final String icon;
  final String description;
  final List<TaskStep> steps;
  int currentStep;
  final int totalSteps;
  String status; // in_progress, completed, cancelled
  final String createdAt;
  String updatedAt;
  final List<String> documents;

  AgenticTask({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.description,
    required this.steps,
    required this.currentStep,
    required this.totalSteps,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.documents = const [],
  });

  factory AgenticTask.fromJson(Map<String, dynamic> json) {
    return AgenticTask(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📋',
      description: json['description'] ?? '',
      steps: (json['steps'] as List?)
              ?.map((s) => TaskStep.fromJson(s))
              .toList() ??
          [],
      currentStep: json['current_step'] ?? 1,
      totalSteps: json['total_steps'] ?? 1,
      status: json['status'] ?? 'in_progress',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      documents: (json['documents'] as List?)?.cast<String>() ?? [],
    );
  }

  double get progressPercentage => currentStep / totalSteps;
  
  TaskStep? get currentStepDetails => 
    currentStep > 0 && currentStep <= steps.length 
      ? steps[currentStep - 1] 
      : null;

  bool get isActive => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

/// Task step data model with links and autofill support
class TaskStep {
  final int id;
  final String title;
  final String description;
  final bool requiresUpload;
  final String? conditional;
  final String? url;
  final String? action;
  final String? actionLabel;
  final List<String>? autofillFields;
  final List<String>? checklist;
  final String? helpText;
  final List<Map<String, dynamic>>? feeBreakdown;
  final List<String>? requiredDocs;

  TaskStep({
    required this.id,
    required this.title,
    required this.description,
    this.requiresUpload = false,
    this.conditional,
    this.url,
    this.action,
    this.actionLabel,
    this.autofillFields,
    this.checklist,
    this.helpText,
    this.feeBreakdown,
    this.requiredDocs,
  });

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requiresUpload: json['requires_upload'] ?? false,
      conditional: json['conditional'],
      url: json['url'],
      action: json['action'],
      actionLabel: json['action_label'],
      autofillFields: (json['autofill_fields'] as List?)?.cast<String>(),
      checklist: (json['checklist'] as List?)?.cast<String>(),
      helpText: json['help_text'],
      feeBreakdown: (json['fee_breakdown'] as List?)?.cast<Map<String, dynamic>>(),
      requiredDocs: (json['required_docs'] as List?)?.cast<String>(),
    );
  }

  bool get hasLink => url != null && url!.isNotEmpty;
  bool get hasAutofill => autofillFields != null && autofillFields!.isNotEmpty;
  bool get hasChecklist => checklist != null && checklist!.isNotEmpty;
}

/// Chat session for history
class ChatSession {
  final String id;
  final String preview;
  final int messageCount;
  final String createdAt;
  final String updatedAt;
  final List<Map<String, dynamic>>? messages;

  ChatSession({
    required this.id,
    required this.preview,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
    this.messages,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      preview: json['preview'] ?? '',
      messageCount: json['message_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      messages: (json['messages'] as List?)?.cast<Map<String, dynamic>>(),
    );
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(updatedAt);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}

/// Agentic service info
class AgenticService {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int stepsCount;
  final String website;

  AgenticService({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.stepsCount,
    required this.website,
  });

  factory AgenticService.fromJson(Map<String, dynamic> json) {
    return AgenticService(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📋',
      description: json['description'] ?? '',
      stepsCount: json['steps_count'] ?? 0,
      website: json['website'] ?? '',
    );
  }
}
