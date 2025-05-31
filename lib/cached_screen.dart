import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterquotes/quote_model.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart' as io;

class CachedQuotesScreen extends StatelessWidget {
  const CachedQuotesScreen({super.key});

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      return MemoryImage(base64Decode(imageUrl.split(',').last));
    } else if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else if (kIsWeb) {
      return const AssetImage('assets/fallback_image.png');
    } else {
      try {
        return FileImage(io.File(imageUrl));
      } catch (e) {
        return const AssetImage('assets/fallback_image.png');
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: const Text('Are you sure you want to delete this quote?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      Provider.of<QuoteProvider>(context, listen: false).removeFromCache(quote);
    }
  }

  Future<void> _shareQuote(BuildContext context, Quote quote) async {
    final theme = Theme.of(context);
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);

    try {
      await quoteProvider.shareQuote(quote, theme);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share quote: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quoteProvider = Provider.of<QuoteProvider>(context);
    final cachedQuotes = quoteProvider.cachedQuotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Quotes'),
        centerTitle: true,
      ),
      body: cachedQuotes.isNotEmpty
          ? _buildQuotesList(context, theme, cachedQuotes)
          : _buildEmptyState(theme),
    );
  }

  Widget _buildQuotesList(
      BuildContext context, ThemeData theme, List<Quote> quotes) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return _buildQuoteCard(context, theme, quote);
      },
    );
  }

  Widget _buildQuoteCard(BuildContext context, ThemeData theme, Quote quote) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (quote.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image(
                image: _getImageProvider(quote.imageUrl),
                height: 180,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 48, color: theme.colorScheme.onSurface),
                      const SizedBox(height: 8),
                      Text('Failed to load image',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${quote.text}"',
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  '- ${quote.author}',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.share, color: theme.colorScheme.primary),
                      onPressed: () => _shareQuote(context, quote),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error),
                      onPressed: () => _confirmDelete(context, quote),
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_mosaic,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Quotes',
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved quotes will appear here',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
