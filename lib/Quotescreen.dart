import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share/share.dart'; // Only import if not on web

import 'services.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  _QuoteScreenState createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final QuoteService _quoteService = QuoteService();
  Map<String, dynamic>? _quote;
  bool _isLoading = false;

  Future<void> _fetchRandomQuote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quote = await _quoteService.fetchRandomQuote();
      setState(() {
        _quote = quote;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch quote: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareQuote() {
    if (_quote != null) {
      if (!kIsWeb) {
        Share.share('${_quote!['content']} - ${_quote!['author']}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing is not supported on web.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRandomQuote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Quotes'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _quote?['content'] ?? 'No quote available',
                    style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _quote != null ? '- ${_quote!['author']}' : '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchRandomQuote,
                    child: Text('Get Random Quote'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_quote != null) {
                        final favoriteQuotes = FavoriteQuotes();
                        await favoriteQuotes.saveQuote(_quote!['content']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Quote saved to favorites!')),
                        );
                      }
                    },
                    child: Text('Save Quote'),
                  ),
                  SizedBox(height: 20),
                  if (!kIsWeb) // Only show the share button on non-web platforms
                    ElevatedButton(
                      onPressed: _shareQuote,
                      child: Text('Share Quote'),
                    ),
                ],
              ),
      ),
    );
  }
}
