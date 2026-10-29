import 'dart:convert';

class ChatTurnState {
  const ChatTurnState({
    this.assistantText = '',
    this.error,
    this.done = false,
    this.threadId,
  });

  final String assistantText;
  final String? error;
  final bool done;
  final String? threadId;

  ChatTurnState apply(Map<String, dynamic> frame) {
    final type = frame['type']?.toString() ?? '';
    switch (type) {
      case 'token':
        return ChatTurnState(
          assistantText: assistantText + _tokenText(frame['content']),
          error: error,
          done: done,
          threadId: threadId,
        );
      case 'error':
        final message = frame['message']?.toString().trim();
        return ChatTurnState(
          assistantText: assistantText,
          error: message == null || message.isEmpty ? '模型失败' : message,
          done: done,
          threadId: threadId,
        );
      case 'done':
        return ChatTurnState(
          assistantText: assistantText,
          error: error,
          done: true,
          threadId: threadId,
        );
      case 'turn.started':
      case 'turn.resumed':
        final nextThread = frame['thread_id']?.toString();
        return ChatTurnState(
          assistantText: assistantText,
          error: error,
          done: done,
          threadId:
              nextThread == null || nextThread.isEmpty ? threadId : nextThread,
        );
      default:
        return this;
    }
  }
}

String _tokenText(Object? content) {
  if (content is String) return content;
  if (content is Map) {
    final text = content['text'] ?? content['content'];
    if (text is String) return text;
  }
  return '';
}

Map<String, dynamic> userTurnPayload({
  required String text,
  String? threadId,
}) {
  return <String, dynamic>{
    'type': 'user_turn',
    'text': text,
    'delivery': 'auto',
    if (threadId != null && threadId.isNotEmpty) 'thread_id': threadId,
    'messages': <Map<String, String>>[
      <String, String>{'role': 'user', 'content': text},
    ],
  };
}

Map<String, dynamic> decodeChatFrame(Object? event) {
  final String text;
  if (event is String) {
    text = event;
  } else if (event is List<int>) {
    text = utf8.decode(event);
  } else {
    throw const FormatException('frame');
  }
  final decoded = jsonDecode(text);
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  throw const FormatException('frame');
}
