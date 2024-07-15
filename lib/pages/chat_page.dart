import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../main.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = '';
  bool _hasSentMessage = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  void _sendMessage() {
    String message = _controller.text.trim();
    if (message.isEmpty || _hasSentMessage) {
      return;
    }
    _hasSentMessage = true;
    Provider.of<ChatProvider>(context, listen: false).sendMessage(message);
    _controller.clear();
    _hasSentMessage = false;
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() {
              _isListening = false;
            });
            if (_controller.text.isNotEmpty) {
              _sendMessage();
            }
          }
        },
        onError: (val) {
          setState(() {
            _isListening = false;
          });
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _hasSentMessage = false;
        });
        _speech.listen(
          onResult: (val) => setState(() {
            if (_isListening && val.recognizedWords != _controller.text) {
              _text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _controller.text = _text;
              }
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _handlePrompt(String prompt) {
    _controller.text = prompt;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AceBot'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    bool isUserMessage = chatProvider.messages[index].startsWith("User:");
                    String message = isUserMessage
                        ? chatProvider.messages[index].substring(6)
                        : chatProvider.messages[index].substring(5);
                    return Align(
                      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4.0),
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isUserMessage ? Colors.deepPurple.shade100 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: isUserMessage ? FontWeight.normal : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _handlePrompt('Hello Acebot'),
                      child: Text('Hello Acebot'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePrompt('Tell me a joke'),
                      child: Text('Tell me a joke'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePrompt('What is Generative AI?'),
                      child: Text('What is Generative AI?'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePrompt('Suggest Fictional Novels'),
                      child: Text('Suggest Fictional Novels'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePrompt('Mental Health Support'),
                      child: Text('Mental Health Support'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePrompt('Give me a quote'),
                      child: Text('Give me a quote'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handlePrompt('Give me the latest news'),
                      child: Text('Give me the latest news'),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _listen,
                    ),
                    Flexible(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Enter your message',
                        ),
                        onSubmitted: (value) {
                          _sendMessage();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}