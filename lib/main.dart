import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pages/chat_page.dart';
import 'consts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        title: 'AceBot',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: ChatPage(),
      ),
    );
  }
}

class ChatProvider with ChangeNotifier {
  String apiKey = OPENAI_API_KEY;
  List<String> messages = [];
  List<String> jokeHistory = [];
  List<String> jokes = [
    "Why don't scientists trust atoms? Because they make up everything!",
    "What do you call fake spaghetti? An impasta!",
    "Why did the scarecrow win an award? Because he was outstanding in his field!",
    "Why don't skeletons fight each other? They don't have the guts!"
  ];

  Future<void> sendMessage(String message) async {
    messages.add("User: $message");
    notifyListeners();

    if (message.toLowerCase().contains('joke')) {
      String joke = await fetchJoke();
      messages.add("Bot: $joke");
      notifyListeners();
      return;
    }

    if (message.toLowerCase().contains('helpline') || message.toLowerCase().contains('support')) {
      String helplines = "Here are some helplines you can contact:\n- National Suicide Prevention Lifeline: 1-800-273-8255\n- Crisis Text Line: Text HOME to 741741";
      messages.add("Bot: $helplines");
      notifyListeners();
      return;
    }

    if (message.toLowerCase().contains('quote')) {
      String quote = await fetchQuote();
      messages.add("Bot: $quote");
      notifyListeners();
      return;
    }

    if (message.toLowerCase().contains('news')) {
      String news = await fetchNews();
      messages.add("Bot: $news");
      notifyListeners();
      return;
    }

    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {'role': 'user', 'content': message},
        ],
        'max_tokens': 150,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data['choices'][0]['message']['content'].trim();
        messages.add("Bot: $reply");
      } else {
        messages.add("Bot: Error in response - ${response.statusCode}");
      }
    } catch (e) {
      messages.add("Bot: Failed to connect to the server");
      print("Exception: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<String> fetchJoke() async {
    if (jokes.isEmpty) {
      jokes = jokeHistory;
      jokeHistory = [];
    }
    String joke = jokes.removeAt(0);
    jokeHistory.add(joke);
    return joke;
  }

  Future<String> fetchQuote() async {
    try {
      final url = Uri.parse('https://api.quotable.io/random');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return "${data['content']} - ${data['author']}";
      } else {
        return "Error fetching quote.";
      }
    } catch (e) {
      print("Error fetching quote: $e");
      return "Failed to fetch quote.";
    }
  }

  Future<String> fetchNews() async {
    try {
      final url = Uri.parse('https://newsapi.org/v2/top-headlines?country=us&apiKey=$NEWS_API_KEY');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return "Latest news: ${data['articles'][0]['title']}";
      } else {
        return "Error fetching news.";
      }
    } catch (e) {
      print("Error fetching news: $e");
      return "Failed to fetch news.";
    }
  }
}