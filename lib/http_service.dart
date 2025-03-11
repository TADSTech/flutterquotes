import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class HttpService {
  static Future<http.Client> get client async {
    if (kIsWeb) return http.Client();

    final HttpClient client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    return IOClient(client);
  }

  static String getProxyUrl(String url) {
    const proxyUrl = 'https://cors-anywhere.herokuapp.com/';
    return kIsWeb ? '$proxyUrl$url' : url;
  }
}
