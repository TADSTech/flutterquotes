// Conditional Imports
import 'dart:async';
import 'dart:convert';
// Conditional imports for web vs. mobile
import 'dart:html' as html if (dart.library.io) 'dart:ui'; // Isolate web-only imports
import 'dart:io' if (dart.library.html) 'dart:ui'; // Isolate mobile-only imports
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle, ByteData, etc.
import 'package:flutterquotes/http_service.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'
    if (dart.library.html) 'dart:ui';
import 'package:path_provider/path_provider.dart' if (dart.library.html) 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quote_model.dart';

class QuoteProvider with ChangeNotifier {
  static const _cachedQuotesKey = 'cachedQuotes';
  static const _favoritesKey = 'favorites';
  static const _colorRange = 200;
  static const _imageWidth = 800;
  static const _imageHeight = 600;

  final SharedPreferences prefs;
  Quote? _currentQuote;
  List<Quote> _cachedQuotes = [];
  List<Quote> _favorites = [];

  QuoteProvider(this.prefs) {
    _initializeData();
  }

  Quote? get currentQuote => _currentQuote;
  List<Quote> get cachedQuotes => List.unmodifiable(_cachedQuotes);
  List<Quote> get favorites => List.unmodifiable(_favorites);

  bool isCached(Quote quote) => _cachedQuotes.any((q) => q.text == quote.text);
  bool isFavorite(Quote quote) => _favorites.any((q) => q.text == quote.text);

  Future<void> _initializeData() async {
    await _loadCachedQuotes();
    await _loadFavorites();
    notifyListeners();
  }

  Future<void> fetchQuote() async {
    try {
      final client = await HttpService.client;
      final response = await client.get(
        Uri.parse(HttpService.getProxyUrl('https://zenquotes.io/api/random')),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        final randomImageId = Random().nextInt(1000);
        _currentQuote = Quote(
          text: data['q'] ?? '',
          author: data['a'] ?? 'Unknown',
          gradientColors: _generateVisualAppealingColors(),
          imageUrl: 'https://picsum.photos/$_imageWidth/$_imageHeight?random=$randomImageId',
        );
        notifyListeners();
      } else {
        throw http.ClientException('Failed to fetch quote: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('HTTP Client Exception: ${e.toString()}');
      throw Exception('Network error, please check your connection');
    } on FormatException catch (e) {
      debugPrint('JSON Format Exception: ${e.toString()}');
      throw Exception('Data format error');
    } catch (e) {
      debugPrint('General Exception: ${e.toString()}');
      throw Exception('Failed to fetch quote: $e');
    }
  }

  List<int> _generateVisualAppealingColors() {
    final random = Random();
    final hsl = HSLColor.fromColor(
      Color.fromARGB(
        255,
        random.nextInt(_colorRange),
        random.nextInt(_colorRange),
        random.nextInt(_colorRange),
      ),
    );

    return [
      hsl.withLightness(0.4).toColor().value,
      hsl.withLightness(0.6).toColor().value,
    ];
  }

  Future<void> _loadCachedQuotes() async {
    try {
      final quotesJson = prefs.getStringList(_cachedQuotesKey) ?? [];
      _cachedQuotes = quotesJson.map((json) => Quote.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      await prefs.remove(_cachedQuotesKey);
      _cachedQuotes = [];
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favsJson = prefs.getStringList(_favoritesKey) ?? [];
      _favorites = favsJson.map((json) => Quote.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      await prefs.remove(_favoritesKey);
      _favorites = [];
    }
  }

  Future<void> saveToCache() async {
    if (_currentQuote == null || isCached(_currentQuote!)) return;

    final localImagePath = await _downloadAndSaveImage(_currentQuote!.imageUrl);
    final cachedQuote = Quote(
      text: _currentQuote!.text,
      author: _currentQuote!.author,
      gradientColors: _currentQuote!.gradientColors,
      imageUrl: localImagePath,
    );

    _cachedQuotes.add(cachedQuote);
    await _persistCachedQuotes();
    notifyListeners();
  }

  Future<void> removeFromCache(Quote quote) async {
    _cachedQuotes.removeWhere((q) => q.text == quote.text);
    await _persistCachedQuotes();
    notifyListeners();
  }

  Future<void> addToFavorites() async {
    if (_currentQuote == null || isFavorite(_currentQuote!)) return;

    _favorites.add(_currentQuote!);
    await _persistFavorites();
    notifyListeners();
  }

  Future<void> removeFromFavorites(Quote quote) async {
    _favorites.removeWhere((q) => q.text == quote.text);
    await _persistFavorites();
    notifyListeners();
  }

  Future<void> _persistCachedQuotes() async {
    await prefs.setStringList(
      _cachedQuotesKey,
      _cachedQuotes.map((quote) => jsonEncode(quote.toJson())).toList(),
    );
  }

  Future<void> _persistFavorites() async {
    await prefs.setStringList(
      _favoritesKey,
      _favorites.map((quote) => jsonEncode(quote.toJson())).toList(),
    );
  }

  Future<String> _downloadAndSaveImage(String imageUrl) async {
    try {
      if (kIsWeb) {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final base64Image = base64Encode(response.bodyBytes);
          return 'data:image/jpeg;base64,$base64Image';
        }
      } else {
        return await compute(_downloadAndSaveImageIsolate, imageUrl);
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return imageUrl;
  }

  static Future<String> _downloadAndSaveImageIsolate(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${imageUrl.hashCode}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    }
    return imageUrl;
  }

  Future<String> saveQuoteImage(Quote quote) async {
    try {
      final response = await http.get(Uri.parse(quote.imageUrl));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        var image = img.decodeImage(imageBytes);
        if (image == null) throw Exception('Failed to decode image');

        // Apply blur effect
        image = img.gaussianBlur(image, radius: 10);

        // Convert the image to a format compatible with `dart:ui`
        final ui.Image uiImage = await _convertImageToUiImage(image);

        // Create a canvas to draw the text
        final recorder = ui.PictureRecorder();
        final canvas =
            Canvas(recorder, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));

        // Draw the blurred image onto the canvas
        final paint = Paint();
        canvas.drawImage(uiImage, Offset.zero, paint);

        // Load a custom font (e.g., Arial)
        final ByteData fontData = await rootBundle.load('fonts/budgeta_script/Budgeta Script.ttf');
        final fontLoader = FontLoader('BudgetaScript')..addFont(Future.value(fontData));
        await fontLoader.load();

        // Draw the shadow text
        final shadowTextStyle = ui.TextStyle(
          color: ui.Color.fromARGB(100, 0, 0, 0), // Semi-transparent black
          fontSize: 48,
          fontFamily: 'Arial',
        );
        final shadowParagraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
          ..pushStyle(shadowTextStyle)
          ..addText('"${quote.text}"');
        final shadowParagraph = shadowParagraphBuilder.build();
        shadowParagraph.layout(ui.ParagraphConstraints(width: image.width.toDouble()));
        canvas.drawParagraph(shadowParagraph, ui.Offset(20, 20));

        // Draw the main text
        final textStyle = ui.TextStyle(
          color: ui.Color.fromARGB(255, 255, 255, 255), // White
          fontSize: 48,
          fontFamily: 'Arial',
        );
        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
          ..pushStyle(textStyle)
          ..addText('"${quote.text}"');
        final paragraph = paragraphBuilder.build();
        paragraph.layout(ui.ParagraphConstraints(width: image.width.toDouble()));
        canvas.drawParagraph(paragraph, ui.Offset(23, 23));

        // Draw the author text
        final authorTextStyle = ui.TextStyle(
          color: ui.Color.fromARGB(255, 255, 255, 255), // White
          fontSize: 24,
          fontFamily: 'Arial',
        );
        final authorParagraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
          ..pushStyle(authorTextStyle)
          ..addText('- ${quote.author}');
        final authorParagraph = authorParagraphBuilder.build();
        authorParagraph.layout(ui.ParagraphConstraints(width: image.width.toDouble()));
        canvas.drawParagraph(authorParagraph, ui.Offset(20, 100));

        // Convert the canvas to an image
        final picture = recorder.endRecording();
        final ui.Image finalUiImage = await picture.toImage(image.width, image.height);
        final ByteData? byteData = await finalUiImage.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Save the image
        if (kIsWeb) {
          // Web: Use Blob and AnchorElement
          final blob = html.Blob([pngBytes], 'image/jpeg');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'quote.jpg')
            ..click();
          html.Url.revokeObjectUrl(url);
          return url;
        } else {
          // Mobile: Save to gallery
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/${quote.text.hashCode}.jpg';
          final file = File(filePath);
          await file.writeAsBytes(pngBytes);
          await ImageGallerySaverPlus.saveFile(filePath);
          return filePath;
        }
      }
    } catch (e) {
      debugPrint('Error saving quote image: $e');
    }
    return quote.imageUrl;
  }

  Future<ui.Image> _convertImageToUiImage(img.Image image) async {
    final ByteData rgbaData = ByteData(image.width * image.height * 4);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final color = ((pixel.a as int) << 24) |
            ((pixel.r as int) << 16) |
            ((pixel.g as int) << 8) |
            (pixel.b as int);
        rgbaData.setUint32((y * image.width + x) * 4, color);
      }
    }
    final codec = await ui.instantiateImageCodec(rgbaData.buffer.asUint8List());
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<void> shareQuote(Quote quote) async {
    try {
      final imagePath = await saveQuoteImage(quote);
      if (!kIsWeb) {
        await Share.shareFiles([imagePath], text: '"${quote.text}" - ${quote.author}');
      } else {
        await Share.share('"${quote.text}" - ${quote.author}\n${quote.imageUrl}');
      }
    } catch (e) {
      debugPrint('Error sharing quote: $e');
    }
  }
}
