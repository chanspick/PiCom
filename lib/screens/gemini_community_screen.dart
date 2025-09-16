import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiCommunityScreen extends StatefulWidget {
  const GeminiCommunityScreen({super.key});

  @override
  State<GeminiCommunityScreen> createState() => _GeminiCommunityScreenState();
}

class _GeminiCommunityScreenState extends State<GeminiCommunityScreen> {
  final Gemini _gemini = Gemini.instance;
  final ChatUser _currentUser = ChatUser(id: '0', firstName: 'User');
  final ChatUser _geminiUser = ChatUser(id: '1', firstName: 'Gemini');
  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini 커뮤니티')),
      body: DashChat(
        currentUser: _currentUser,
        onSend: _sendMessage,
        messages: _messages,
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      _messages.insert(0, chatMessage);
    });

    try {
      String question = chatMessage.text;
      _gemini.streamGenerateContent(question).listen((event) {
        String response =
            event.content?.parts?.fold(
              "",
              (previous, current) => "\$previous\${current.text}",
            ) ??
            "";

        // Find the index of the last message from Gemini
        int geminiMessageIndex = _messages.indexWhere(
          (m) => m.user.id == _geminiUser.id,
        );

        if (geminiMessageIndex != -1 &&
            _messages[geminiMessageIndex].user.id == _geminiUser.id) {
          // Update existing message
          final updatedMessage = ChatMessage(
            user: _geminiUser,
            createdAt: _messages[geminiMessageIndex].createdAt,
            text: _messages[geminiMessageIndex].text + response,
          );
          setState(() {
            _messages[geminiMessageIndex] = updatedMessage;
          });
        } else {
          // Add new message
          ChatMessage message = ChatMessage(
            user: _geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            _messages.insert(0, message);
          });
        }
      });
    } catch (e) {
      // Handle error
      ChatMessage errorMessage = ChatMessage(
        user: _geminiUser,
        createdAt: DateTime.now(),
        text: "Error: \${e.toString()}",
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
    }
  }
}
