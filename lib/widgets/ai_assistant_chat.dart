import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AiAssistantChat extends StatefulWidget {
  final String? initialMessage;
  
  const AiAssistantChat({Key? key, this.initialMessage}) : super(key: key);

  @override
  _AiAssistantChatState createState() => _AiAssistantChatState();
}

class _AiAssistantChatState extends State<AiAssistantChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isExpanded = false;
  
  // OpenAI API configuration
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // Replace with your key
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    if (widget.initialMessage != null) {
      _addMessage(widget.initialMessage!, true);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('ai_chat_history') ?? [];
      
      setState(() {
        for (String msg in history.take(10)) { // Keep last 10 messages
          try {
            final data = json.decode(msg);
            _messages.add(ChatMessage(
              text: data['text'],
              isUser: data['isUser'],
              timestamp: DateTime.parse(data['timestamp']),
            ));
          } catch (e) {
            // Skip invalid messages
          }
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = _messages.map((msg) => json.encode({
        'text': msg.text,
        'isUser': msg.isUser,
        'timestamp': msg.timestamp.toIso8601String(),
      })).toList();
      
      await prefs.setStringList('ai_chat_history', history);
    } catch (e) {
      // Handle error silently
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _saveChatHistory();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addMessage(message, true);
    _controller.clear();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''Ești un asistent AI specializat în dans și fitness, 
              care ajută utilizatorii aplicației AIU Dance. 
              Răspunde în română și oferă sfaturi utile despre:
              - Tehnici de dans
              - Exerciții de fitness
              - Programe de antrenament
              - Nutriție pentru dansatori
              - Motivare și mentalitate
              Fii prietenos, profesionist și oferă răspunsuri practice.'''
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reply = data['choices'][0]['message']['content'];
        _addMessage(reply, false);
      } else {
        _addMessage('Îmi pare rău, am întâmpinat o problemă tehnica. Încearcă din nou.', false);
      }
    } catch (e) {
      _addMessage('Nu am putut procesa mesajul tău. Verifică conexiunea la internet.', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? MediaQuery.of(context).size.height * 0.6 : 80,
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with expand/collapse
            ListTile(
              leading: const Icon(Icons.smart_toy, color: Colors.purple),
              title: const Text(
                'Asistent AI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_isExpanded ? 'Chat complet' : 'Apasă pentru a extinde'),
              trailing: IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
            
            if (_isExpanded) ...[
              // Chat messages
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Începe o conversație cu AI-ul tău!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return MessageBubble(message: message);
                        },
                      ),
              ),
              
              // Loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('AI-ul scrie...'),
                    ],
                  ),
                ),
              
              // Input field
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Întreabă AI-ul tău...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                      icon: const Icon(Icons.send),
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}








