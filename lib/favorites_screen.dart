import 'package:flutter/material.dart';
import 'package:flutterquotes/quote_model.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: const Text('Are you sure you want to remove this quote from favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      Provider.of<QuoteProvider>(context, listen: false).removeFromFavorites(quote);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quoteProvider = Provider.of<QuoteProvider>(context);
    final favorites = quoteProvider.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: favorites.isNotEmpty
          ? _buildGridLayout(context, theme, favorites)
          : _buildEmptyState(theme),
    );
  }

  Widget _buildGridLayout(BuildContext context, ThemeData theme, List<Quote> favorites) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) => _FavoriteQuoteCard(
              quote: favorites[index],
              onDelete: () => _confirmDelete(context, favorites[index]),
            ),
          ),
        );
      },
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
            'No Favorites Yet',
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon to save quotes here',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FavoriteQuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onDelete;

  const _FavoriteQuoteCard({
    required this.quote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1))),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {}, // Add navigation to detail view if needed
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildImage(theme),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 8),
                    Text(
                      '- ${quote.author}',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    IconButton(
                      icon: Icon(Icons.favorite, color: theme.colorScheme.error),
                      onPressed: onDelete,
                      tooltip: 'Remove from favorites',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return Image.network(
      quote.imageUrl,
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
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 32, color: theme.colorScheme.onSurface),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
