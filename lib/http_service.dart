import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:http/http.dart' as http;

class HttpService {
  static const _maxRetries = 2;
  static const _retryDelay = Duration(seconds: 1);
  static const _cloudFunctionUrl =
      'https://quote-mm8e66itp-michaels-projects-7f79288b.vercel.app/api/quote';

  static Future<Map<String, dynamic>> fetchQuote() async {
    try {
      final response = await http.get(Uri.parse(_cloudFunctionUrl));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch quote');
    } catch (e) {
      debugPrint('Error fetching quote: $e');
      return {
        'success': false,
        'quote': {
          'text': 'Fallback quote when API fails',
          'author': 'Unknown',
          'category': 'general'
        }
      };
    }
  }

  static Future<http.Response> _fetchWithRetry(
    String url, {
    int retryCount = 0,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response;
      }

      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return _fetchWithRetry(url, retryCount: retryCount + 1);
      }

      throw QuoteFetchException(
        'Request failed with status ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay);
        return _fetchWithRetry(url, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  static Map<String, dynamic> parseQuoteResponse(http.Response response) {
    try {
      final jsonData = json.decode(response.body);

      if (jsonData['success'] == true) {
        return {
          'text': jsonData['quote']['text'],
          'author': jsonData['quote']['author'],
          'category': jsonData['quote']['category'],
          'source': jsonData['source'],
        };
      } else if (jsonData['fallbackQuote'] != null) {
        return jsonData['fallbackQuote'];
      }

      throw Exception('API returned unsuccessful response');
    } catch (e) {
      debugPrint('Failed to parse quote response: $e');
      throw QuoteFetchException('Failed to parse API response', 0);
    }
  }
}
