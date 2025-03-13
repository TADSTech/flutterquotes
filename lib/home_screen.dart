import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterquotes/quote_model.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      quoteProvider.fetchQuote();
      quoteProvider.saveToCache();
    });
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      return MemoryImage(base64Decode(imageUrl.split(',').last));
    } else if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      return FileImage(File(imageUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quoteProvider = Provider.of<QuoteProvider>(context);
    final quote = quoteProvider.currentQuote;

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Quote', style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
      body: quote != null && quote.imageUrl.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _getImageProvider(quote.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: _QuoteCard(quote: quote, theme: theme),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote? quote;
  final ThemeData theme;

  const _QuoteCard({required this.quote, required this.theme});

  Future<Uint8List?> _generateCombinedImage(Quote quote, ThemeData theme) async {
    try {
      final response = await http.get(Uri.parse(quote.imageUrl));
      if (response.statusCode == 200) {
        final image = img.decodeImage(response.bodyBytes)!;
        final blurredImage = img.gaussianBlur(image, radius: 5);

        final ui.Image uiImage = await _convertImageToUiImage(blurredImage);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
            recorder, Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));

        final paint = Paint();
        canvas.drawImage(uiImage, Offset.zero, paint);

        final ByteData fontData = await rootBundle.load('fonts/budgeta_script/Budgeta Script.ttf');
        final fontLoader = FontLoader('BudgetaScript')..addFont(Future.value(fontData));
        await fontLoader.load();

        final textStyle = ui.TextStyle(
          color: ui.Color.fromARGB(255, 255, 255, 255),
          fontSize: 30,
          fontFamily: 'Arial',
          shadows: [ui.Shadow(blurRadius: 3, color: ui.Color.fromARGB(255, 0, 0, 0))],
        );

        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        ))
          ..pushStyle(textStyle)
          ..addText('"${quote.text}"\n- ${quote.author}');

        final paragraph = paragraphBuilder.build();
        paragraph.layout(ui.ParagraphConstraints(width: uiImage.width.toDouble()));
        final textOffset = ui.Offset(
          (uiImage.width.toDouble() - paragraph.width) / 2,
          (uiImage.height.toDouble() - paragraph.height) / 2,
        );
        canvas.drawParagraph(paragraph, textOffset);

        final picture = recorder.endRecording();
        final ui.Image finalUiImage = await picture.toImage(uiImage.width, uiImage.height);
        final ByteData? byteData = await finalUiImage.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Error generating image: $e');
    }
    return null;
  }

  Future<ui.Image> _convertImageToUiImage(img.Image image) async {
    final completer = Completer<ui.Image>();
    final rgbaBytes = image.getBytes(order: img.Format.rgba);

    ui.decodeImageFromPixels(
      rgbaBytes,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (ui.Image result) => completer.complete(result),
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = Provider.of<QuoteProvider>(context);
    final isCached = quote != null && quoteProvider.isCached(quote!);
    final isFavorite = quote != null && quoteProvider.isFavorite(quote!);

    return Card(
      color: theme.colorScheme.surface.withOpacity(0.9),
      margin: const EdgeInsets.all(20),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quote != null) ...[
              Text('"${quote!.text}"',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('- ${quote!.author}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: theme.colorScheme.secondary),
                    onPressed: () => isFavorite
                        ? quoteProvider.removeFromFavorites(quote!)
                        : quoteProvider.addToFavorites(),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                    onPressed: quoteProvider.fetchQuote,
                  ),
                  IconButton(
                    icon: Icon(Icons.download, color: theme.colorScheme.secondary),
                    onPressed: () async {
                      if (quote == null) return;
                      final imageBytes = await _generateCombinedImage(quote!, theme);
                      if (imageBytes == null) return;

                      final directory = await getApplicationDocumentsDirectory();
                      final filePath = '${directory.path}/${quote!.text.hashCode}.png';
                      await File(filePath).writeAsBytes(imageBytes);
                      await ImageGallerySaverPlus.saveFile(filePath);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Image saved!')));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: theme.colorScheme.primary),
                    onPressed: () async {
                      if (quote == null) return;
                      final imageBytes = await _generateCombinedImage(quote!, theme);
                      if (imageBytes == null) return;

                      final directory = await getApplicationDocumentsDirectory();
                      final filePath = '${directory.path}/${quote!.text.hashCode}.png';
                      await File(filePath).writeAsBytes(imageBytes);
                      await Share.shareFiles([filePath],
                          text: '"${quote!.text}" - ${quote!.author}');
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
