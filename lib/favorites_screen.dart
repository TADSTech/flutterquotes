import 'package:flutter/material.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quoteProvider = Provider.of<QuoteProvider>(context);
    final favorites = quoteProvider.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites', style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
      body: favorites.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                final imageHeight = constraints.maxHeight * 0.2;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 24 : 8,
                    vertical: 8,
                  ),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final quote = favorites[index];
                      return Card(
                        elevation: 2,
                        color: theme.colorScheme.surface,
                        margin: const EdgeInsets.all(4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {}, // Add tap functionality if needed
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    quote.imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      return progress == null
                                          ? child
                                          : Center(
                                              child: CircularProgressIndicator(
                                                value: progress.expectedTotalBytes != null
                                                    ? progress.cumulativeBytesLoaded /
                                                        progress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: theme.colorScheme.surface,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            '"${quote.text}"',
                                            style: theme.textTheme.bodyMedium!.copyWith(
                                              color: theme.colorScheme.onSurface,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '- ${quote.author}',
                                        style: theme.textTheme.bodySmall!.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      IconButton(
                                        iconSize: 28,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.delete_outline,
                                            color: theme.colorScheme.error),
                                        onPressed: () => quoteProvider.removeFromFavorites(quote),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite quotes yet',
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
