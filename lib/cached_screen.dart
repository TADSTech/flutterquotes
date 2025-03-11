import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:provider/provider.dart';

class CachedQuotesScreen extends StatelessWidget {
  const CachedQuotesScreen({super.key});

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
    final cachedQuotes = quoteProvider.cachedQuotes;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cached Quotes', style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
      body: cachedQuotes.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cachedQuotes.length,
              itemBuilder: (context, index) {
                final quote = cachedQuotes[index];
                return Card(
                  color: theme.colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (quote.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image(
                            image: _getImageProvider(quote.imageUrl),
                            height: 150,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: theme.colorScheme.surface,
                              child: const Icon(Icons.broken_image),
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
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '- ${quote.author}',
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(Icons.delete, color: theme.colorScheme.error),
                                onPressed: () => quoteProvider.removeFromCache(quote),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cached,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cached quotes yet',
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
