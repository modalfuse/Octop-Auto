enum MessageRole {
  user,
  assistant,
  system,
  tool;

  static MessageRole fromString(String value) {
    return MessageRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => MessageRole.assistant,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming,
    this.error,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool? isStreaming;
  final String? error;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return ChatMessage(
      id: rawId == null ? 'msg-${json.hashCode}' : rawId.toString(),
      role: MessageRole.fromString(json['role'] as String? ?? 'assistant'),
      content: textFromContent(json['content']),
      timestamp: DateTime.now(),
    );
  }

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    String? error,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
    );
  }
}

/// History content is either a string or a list of content blocks.
String textFromContent(Object? content) {
  if (content == null) return '';
  if (content is String) return content;
  if (content is Map) {
    final text = content['text'] ?? content['content'];
    if (text is String) return text;
    return '';
  }
  if (content is List) {
    final buffer = StringBuffer();
    for (final item in content) {
      if (item is String) {
        buffer.write(item);
      } else if (item is Map) {
        final type = item['type'];
        if (type == 'text' || type == null) {
          final text = item['text'] ?? item['content'];
          if (text is String) buffer.write(text);
        }
      }
    }
    return buffer.toString();
  }
  return '';
}
