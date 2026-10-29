import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'chat_frames.dart';

class ChatLink {
  ChatLink({required this.frames, required this.sendText, required this.close});

  final Stream<Map<String, dynamic>> frames;
  final void Function(String payload) sendText;
  final Future<void> Function() close;

  void send(Map<String, dynamic> payload) {
    sendText(jsonEncode(payload));
  }
}

typedef ChatConnector = ChatLink Function(Uri uri);

ChatLink connectLiveChat(Uri uri) {
  final channel = WebSocketChannel.connect(uri);
  return ChatLink(
    frames: channel.stream.map(decodeChatFrame),
    sendText: channel.sink.add,
    close: () async {
      await channel.sink.close();
    },
  );
}
