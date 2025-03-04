import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteService {
  final String _baseUrl = "https://api.quotable.io";

  Future<Map<String, dynamic>> fetchRandomQuote() async {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;

    final client = IOClient(httpClient);

    try {
      final response = await client.get(Uri.parse("$_baseUrl/random"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load quote');
      }
    } finally {
      client.close();
    }
  }
}

class FavoriteQuotes {
  static const _key = 'favoriteQuotes';

  Future<void> saveQuote(String quote) async {
    final prefs = await SharedPreferences.getInstance();
    final quotes = prefs.getStringList(_key) ?? [];

    if (!quotes.contains(quote)) {
      quotes.add(quote);
      await prefs.setStringList(_key, quotes);
    }
  }

  Future<List<String>> getQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
