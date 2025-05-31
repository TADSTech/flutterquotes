import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterquotes/http_service.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quote_model.dart';

class QuoteProvider with ChangeNotifier {
  static const _cachedQuotesKey = 'cachedQuotes';
  static const _favoritesKey = 'favorites';
  static const _categoriesKey = 'categories';
  static const _imageWidth = 800;
  static const _imageHeight = 600;
  static const _watermarkText = 'FlutterQuotes';

  static const List<String> defaultCategories = [
    'General',
    'Inspiration',
    'Motivation',
    'Love',
    'Life',
    'Wisdom',
    'Funny'
  ];

  final SharedPreferences prefs;
  Quote? _currentQuote;
  List<Quote> _cachedQuotes = [];
  List<Quote> _favorites = [];
  List<String> _categories = [];
  bool _isLoading = false; // Added _isLoading flag

  QuoteProvider(this.prefs) {
    _initializeData();
  }

  Quote? get currentQuote => _currentQuote;
  List<Quote> get cachedQuotes => List.unmodifiable(_cachedQuotes);
  List<Quote> get favorites => List.unmodifiable(_favorites);
  List<String> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading; // Getter for isLoading

  bool isCached(Quote quote) => _cachedQuotes.any((q) => q.text == quote.text);
  bool isFavorite(Quote quote) => _favorites.any((q) => q.text == quote.text);

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        loadCategories(),
        _loadCachedQuotes(),
        _loadFavorites(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Initialization error: $e');
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final savedCategories = prefs.getStringList(_categoriesKey);
      _categories = savedCategories != null
          ? List<String>.from(savedCategories)
          : List<String>.from(defaultCategories);
    } catch (e) {
      _categories = List<String>.from(defaultCategories);
      await prefs.setStringList(_categoriesKey, _categories);
    }
  }

  Future<void> addCategory(String category) async {
    final trimmedCategory = category.trim();
    if (trimmedCategory.isEmpty || _categories.contains(trimmedCategory)) {
      return;
    }

    // Create a new modifiable list from the current categories
    final newCategories = List<String>.from(_categories);
    newCategories.add(trimmedCategory);

    // Assign back to the private field
    _categories = newCategories;

    await prefs.setStringList(_categoriesKey, _categories);
    notifyListeners();
    debugPrint('Saved categories: $_categories');
  }

  Future<void> removeCategory(String category) async {
    if (!_categories.contains(category) ||
        defaultCategories.contains(category)) {
      return;
    }

    // Create a new modifiable list from the current categories
    final newCategories = List<String>.from(_categories);
    newCategories.remove(category);

    // Assign back to the private field
    _categories = newCategories;

    await prefs.setStringList(_categoriesKey, _categories);
    notifyListeners();
  }

  Future<void> fetchQuote({String? category}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://your-vercel-app.vercel.app/api/quote'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Handle both successful and fallback responses
        final quoteData = jsonData['success'] == true
            ? jsonData['quote']
            : jsonData['fallbackQuote'] ??
                _createFallbackQuote(category).toJson();

        _currentQuote = Quote(
          text:
              quoteData['text'] ?? quoteData['content'] ?? 'No quote available',
          author: quoteData['author'] ?? 'Unknown',
          gradientColors: _generateVisualAppealingColors(),
          imageUrl: _generateRandomImageUrl(),
          category: quoteData['category'] ?? category ?? 'general',
        );

        if (!isCached(_currentQuote!)) {
          await saveToCache(category: _currentQuote!.category);
        }
      } else {
        throw Exception(
            'API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching quote: $e');
      _currentQuote = _createFallbackQuote(category);

      // Optionally log the error to your backend or analytics
      // await _logError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Helper method to create a fallback quote
  Quote _createFallbackQuote(String? category) {
    return Quote(
      text:
          "The greatest glory in living lies not in never falling, but in rising every time we fall.",
      author: "Nelson Mandela",
      gradientColors: _generateVisualAppealingColors(),
      imageUrl: _generateRandomImageUrl(),
      category: category ?? 'General',
    );
  }

  String _generateRandomImageUrl() {
    final Random random = Random();
    final int randomImageId =
        random.nextInt(1000); // Or use your existing randomId logic
    return 'https://picsum.photos/$_imageWidth/$_imageHeight?random=$randomImageId';
  }

  Future<Uint8List> _captureQuoteWidget(Quote quote, ThemeData theme,
      {bool forShare = false}) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // Try to load the background image first
      try {
        if (kIsWeb) {
          // For web, use a different approach to load images
          final image = await _loadImageForWeb(quote.imageUrl);
          final src = Rect.fromLTWH(
              0, 0, image.width.toDouble(), image.height.toDouble());
          final dst = Rect.fromLTWH(
              0, 0, _imageWidth.toDouble(), _imageHeight.toDouble());
          canvas.drawImageRect(image, src, dst, paint);
        } else {
          final imageResponse = await http.get(Uri.parse(quote.imageUrl));
          if (imageResponse.statusCode == 200) {
            final image = await decodeImageFromList(imageResponse.bodyBytes);
            final src = Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble());
            final dst = Rect.fromLTWH(
                0, 0, _imageWidth.toDouble(), _imageHeight.toDouble());
            canvas.drawImageRect(image, src, dst, paint);
          } else {
            throw Exception('Failed to load image');
          }
        }
      } catch (e) {
        debugPrint('Using gradient fallback: $e');
        // Fallback to gradient background
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(quote.gradientColors[0]),
            Color(quote.gradientColors[1]),
          ],
        );
        final rect = Rect.fromLTWH(
            0, 0, _imageWidth.toDouble(), _imageHeight.toDouble());
        canvas.drawRect(rect, paint..shader = gradient.createShader(rect));
      }

      // Add a semi-transparent overlay for better text readability
      canvas.drawRect(
        Rect.fromLTWH(0, 0, _imageWidth.toDouble(), _imageHeight.toDouble()),
        paint..color = Colors.black.withOpacity(0.3),
      );

      // Load font
      final fontLoader = FontLoader('QuoteFont')
        ..addFont(
            rootBundle.load('assets/fonts/budgeta_script/Budgeta_Script.ttf'));
      await fontLoader.load();

      // Draw quote text with better spacing
      final quoteParagraph = _buildTextParagraph(
        text: '"${quote.text}"',
        style: TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontFamily: 'QuoteFont',
          height: 1.5,
          shadows: [
            Shadow(
              blurRadius: 6,
              color: Colors.black.withOpacity(0.5),
              offset: Offset(2, 2),
            ),
          ],
        ),
        maxWidth: _imageWidth * 0.8,
      );
      canvas.drawParagraph(
          quoteParagraph, Offset(_imageWidth * 0.1, _imageHeight * 0.3));

      // Draw author text with more space from the quote
      final authorParagraph = _buildTextParagraph(
        text: '- ${quote.author}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 28,
          fontFamily: 'QuoteFont',
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withOpacity(0.5),
              offset: Offset(1, 1),
            ),
          ],
        ),
        maxWidth: _imageWidth * 0.8,
      );
      canvas.drawParagraph(
          authorParagraph, Offset(_imageWidth * 0.1, _imageHeight * 0.65));

      // Add watermark if sharing on Android
      if (forShare && !kIsWeb && Platform.isAndroid) {
        final watermarkParagraph = _buildTextParagraph(
          text: _watermarkText,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
          maxWidth: _imageWidth.toDouble(),
        );
        canvas.drawParagraph(
          watermarkParagraph,
          Offset(
            _imageWidth - watermarkParagraph.width - 20,
            _imageHeight - watermarkParagraph.height - 20,
          ),
        );
      }

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(_imageWidth, _imageHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw ImageCaptureException('Failed to convert image to bytes');
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Image capture error: $e');
      throw ImageCaptureException('Failed to capture quote image');
    }
  }

  ui.Paragraph _buildTextParagraph({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: style.fontSize,
        fontFamily: style.fontFamily,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        height: style.height,
      ),
    )
      ..pushStyle(style.getTextStyle())
      ..addText(text);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    return paragraph;
  }

  List<int> _generateVisualAppealingColors() {
    final random = Random();
    final color = Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );

    final hsl = HSLColor.fromColor(color);
    return [
      hsl.withLightness(0.4).toColor().value,
      hsl.withLightness(0.6).toColor().value,
    ];
  }

  Future<ui.Image> _loadImageForWeb(String imageUrl) async {
    final completer = Completer<ui.Image>();
    final img.Image? image = await _loadWebImage(imageUrl);
    if (image == null) {
      throw Exception('Failed to load web image');
    }

    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(img.encodePng(image)),
    );
    final frame = await codec.getNextFrame();
    completer.complete(frame.image);
    return completer.future;
  }

  Future<img.Image?> _loadWebImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return img.decodeImage(response.bodyBytes);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading web image: $e');
      return null;
    }
  }

  Future<void> _loadCachedQuotes() async {
    try {
      final quotesJson = prefs.getStringList(_cachedQuotesKey) ?? [];
      _cachedQuotes =
          quotesJson.map((json) => Quote.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      await prefs.remove(_cachedQuotesKey);
      _cachedQuotes = [];
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favsJson = prefs.getStringList(_favoritesKey) ?? [];
      _favorites =
          favsJson.map((json) => Quote.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      await prefs.remove(_favoritesKey);
      _favorites = [];
    }
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
      return await compute(_downloadAndSaveImageIsolate, imageUrl);
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return imageUrl;
    }
  }

  static Future<String> _downloadAndSaveImageIsolate(String imageUrl) async {
    if (kIsWeb) {
      // For web, we'll return the original URL as we can't save files locally
      return imageUrl;
    } else {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/${imageUrl.hashCode}.jpg';
        await File(filePath).writeAsBytes(response.bodyBytes);
        return filePath;
      }
      throw Exception('Failed to download image');
    }
  }

  Future<String> saveQuoteImage(Quote quote, ThemeData theme) async {
    try {
      final imageBytes = await _captureQuoteWidget(quote, theme);

      if (kIsWeb) {
        return 'data:image/png;base64,${base64Encode(imageBytes)}';
      } else {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/${quote.text.hashCode}.png';
        await File(filePath).writeAsBytes(imageBytes);
        await ImageGallerySaverPlus.saveFile(filePath);
        return filePath;
      }
    } on ImageCaptureException catch (e) {
      debugPrint('Save quote image error: ${e.message}');
      throw QuoteSaveException('Failed to create quote image');
    } catch (e) {
      debugPrint('Unexpected save error: $e');
      throw QuoteSaveException('Failed to save quote');
    }
  }

  Future<void> shareQuote(Quote quote, ThemeData theme) async {
    try {
      // For cached quotes with local images, we need to handle them differently
      String imagePath = quote.imageUrl;

      if (!kIsWeb && !quote.imageUrl.startsWith('http')) {
        // For mobile with local image, we need to create a shareable version
        final imageBytes = await File(quote.imageUrl).readAsBytes();
        final tempDir = await getTemporaryDirectory();
        imagePath =
            '${tempDir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
        await File(imagePath).writeAsBytes(imageBytes);
      }

      final imageBytes =
          await _captureQuoteWidget(quote, theme, forShare: true);
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(imageBytes);

      if (kIsWeb) {
        await Share.share(
          '"${quote.text}" - ${quote.author}',
          subject: 'Inspirational Quote',
        );
      } else {
        await Share.shareFiles(
          [filePath],
          text: '"${quote.text}" - ${quote.author}',
        );
      }
    } catch (e) {
      debugPrint('Share failed: $e');
      throw QuoteShareException('Failed to share quote');
    }
  }

  List<Quote> getQuotesByCategory(String category) {
    return _cachedQuotes.where((quote) => quote.category == category).toList();
  }

  Future<void> saveToCache({String category = 'General'}) async {
    if (_currentQuote == null || isCached(_currentQuote!)) return;

    try {
      // Download and save the image first
      String localImagePath;
      if (_currentQuote!.imageUrl.startsWith('http')) {
        localImagePath = await _downloadAndSaveImage(_currentQuote!.imageUrl);
      } else {
        // If it's already a local path, use it directly
        localImagePath = _currentQuote!.imageUrl;
      }

      // Create the cached quote with local image path
      final cachedQuote = Quote(
        text: _currentQuote!.text,
        author: _currentQuote!.author,
        gradientColors: _currentQuote!.gradientColors,
        imageUrl: localImagePath,
        category: category,
      );

      _cachedQuotes.add(cachedQuote);
      await _persistCachedQuotes();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cache quote: $e');
      throw QuoteSaveException('Failed to save quote to cache');
    }
  }
}

class QuoteFetchException implements Exception {
  final String message;
  final int? statusCode;

  QuoteFetchException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ImageCaptureException implements Exception {
  final String message;
  ImageCaptureException(this.message);

  @override
  String toString() => message;
}

class QuoteSaveException implements Exception {
  final String message;
  QuoteSaveException(this.message);

  @override
  String toString() => message;
}

class QuoteShareException implements Exception {
  final String message;
  QuoteShareException(this.message);

  @override
  String toString() => message;
}
