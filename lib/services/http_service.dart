import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutterquotes/quote_provider.dart';

class HttpService {
  static const _maxRetries = 2;
  static const _retryDelay = Duration(seconds: 1);

  // List of fallback APIs
  static final _quoteApis = [
    'https://api.quotable.io/random',
    'https://zenquotes.io/api/random',
    'https://dune-api.herokuapp.com/api/quotes/random',
  ];

  static Future<http.Client> get _client async {
    if (kIsWeb) {
      return http.Client(); // Web doesn't need custom client
    }

    final ioClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return IOClient(ioClient);
  }

  static Future<http.Response> fetchQuote() async {
    http.Client client = await _client;

    // Try each API until one succeeds
    for (final apiUrl in _quoteApis) {
      try {
        final response = await _fetchWithRetry(client, apiUrl);
        if (response.statusCode == 200) {
          return response;
        }
      } catch (e) {
        debugPrint('Failed to fetch from $apiUrl: $e');
      }
    }

    throw QuoteFetchException('All quote APIs failed', 0);
  }

  static Future<http.Response> _fetchWithRetry(
    http.Client client,
    String url, {
    int retryCount = 0,
  }) async {
    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response;
      }

      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return _fetchWithRetry(client, url, retryCount: retryCount + 1);
      }

      throw QuoteFetchException(
        'API request failed with status ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return _fetchWithRetry(client, url, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  static Map<String, dynamic> parseQuoteResponse(http.Response response) {
    try {
      final jsonData = jsonDecode(response.body);

      // Handle different API response formats
      if (response.request?.url.toString().contains('quotable.io') ?? false) {
        return {
          'text': jsonData['content'],
          'author': jsonData['author'],
          'category': jsonData['tags']?.isNotEmpty == true
              ? jsonData['tags'][0]
              : 'general',
        };
      } else if (response.request?.url.toString().contains('zenquotes.io') ??
          false) {
        return {
          'text': jsonData[0]['q'],
          'author': jsonData[0]['a'],
          'category': 'general',
        };
      } else if (response.request?.url.toString().contains('dune-api') ??
          false) {
        return {
          'text': jsonData['quote'],
          'author': jsonData['author'],
          'category': jsonData['category'] ?? 'dune',
        };
      }

      throw Exception('Unknown API response format');
    } catch (e) {
      debugPrint('Failed to parse quote response: $e');
      throw QuoteFetchException('Failed to parse API response', 0);
    }
  }
}
