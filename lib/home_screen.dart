import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterquotes/quote_model.dart';
import 'package:flutterquotes/quote_provider.dart';
import 'package:flutterquotes/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'General';
  bool _isLoading = false;
  bool _isProcessingAction = false;
  final GlobalKey _quoteCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadInitialQuote();
  }

  Future<void> _loadInitialQuote() async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    if (quoteProvider.currentQuote == null) {
      await _fetchQuoteWithLoading();
    }
  }

  Future<void> _fetchQuoteWithLoading() async {
    setState(() => _isLoading = true);
    try {
      final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
      await quoteProvider.fetchQuote(category: _selectedCategory);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: isLargeScreen
          ? null
          : AppBar(
              title:
                  Text('FlutterQuotes', style: theme.textTheme.headlineSmall),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : quote != null
              ? _buildQuoteContent(theme, quoteProvider, quote, isLargeScreen)
              : _buildErrorRetryWidget(quoteProvider),
      floatingActionButton: isLargeScreen
          ? null
          : FloatingActionButton.extended(
              onPressed: _fetchQuoteWithLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('New Quote'),
              tooltip: 'Get a new quote',
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
    );
  }

  Widget _buildQuoteContent(ThemeData theme, QuoteProvider quoteProvider,
      Quote quote, bool isLargeScreen) {
    return Stack(
      children: [
        // Background Image with gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            child: Image(
              image: _getImageProvider(quote.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Content
        Column(
          children: [
            // App Bar for large screens
            if (isLargeScreen) _buildLargeScreenAppBar(theme),
            // Category Selector
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                isLargeScreen ? 16 : 16,
                16,
                8,
              ),
              child: Container(
                constraints:
                    isLargeScreen ? const BoxConstraints(maxWidth: 400) : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: theme.colorScheme.surface,
                  icon: const Icon(Icons.arrow_drop_down),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  items: quoteProvider.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                      _fetchQuoteWithLoading();
                    }
                  },
                ),
              ),
            ),
            // Quote Card
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: isLargeScreen
                        ? const BoxConstraints(maxWidth: 800)
                        : const BoxConstraints(),
                    child: _QuoteCard(
                      key: _quoteCardKey,
                      quote: quote,
                      theme: theme,
                      currentCategory: _selectedCategory,
                      isFavorite: quoteProvider.isFavorite(quote),
                      isCached: quoteProvider.isCached(quote),
                      onFavoritePressed: () =>
                          _toggleFavorite(quoteProvider, quote),
                      onSavePressed: () =>
                          quoteProvider.saveQuoteImage(quote, theme),
                      onSharePressed: () =>
                          quoteProvider.shareQuote(quote, theme),
                      onCachePressed: () => _saveToCache(quoteProvider, quote),
                      isProcessing: _isProcessingAction,
                      isLargeScreen: isLargeScreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildLargeScreenAppBar(ThemeData theme) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: AppBar(
        title: Text('FlutterQuotes', style: theme.textTheme.headlineSmall),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: _fetchQuoteWithLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('New Quote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRetryWidget(QuoteProvider quoteProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load quote',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchQuoteWithLoading,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(QuoteProvider quoteProvider, Quote quote) async {
    setState(() => _isProcessingAction = true);
    try {
      if (quoteProvider.isFavorite(quote)) {
        await quoteProvider.removeFromFavorites(quote);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from favorites'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => quoteProvider.addToFavorites(),
            ),
          ),
        );
      } else {
        await quoteProvider.addToFavorites();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _saveToCache(QuoteProvider quoteProvider, Quote quote) async {
    setState(() => _isProcessingAction = true);
    try {
      await quoteProvider.saveToCache(category: _selectedCategory);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $_selectedCategory collection'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final ThemeData theme;
  final String currentCategory;
  final bool isFavorite;
  final bool isCached;
  final VoidCallback onFavoritePressed;
  final VoidCallback onSavePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onCachePressed;
  final bool isProcessing;
  final bool isLargeScreen;

  const _QuoteCard({
    super.key,
    required this.quote,
    required this.theme,
    required this.currentCategory,
    required this.isFavorite,
    required this.isCached,
    required this.onFavoritePressed,
    required this.onSavePressed,
    required this.onSharePressed,
    required this.onCachePressed,
    required this.isProcessing,
    required this.isLargeScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(isLargeScreen ? 24 : 16),
      child: Card(
        color: theme.colorScheme.surface.withOpacity(0.9),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 32 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quote Text
              Text(
                '"${quote.text}"',
                style: isLargeScreen
                    ? theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      )
                    : theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargeScreen ? 24 : 20),
              // Author
              Text(
                '- ${quote.author}',
                style: isLargeScreen
                    ? theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      )
                    : theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargeScreen ? 40 : 32),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    tooltip:
                        isFavorite ? 'Remove favorite' : 'Add to favorites',
                    onPressed: isProcessing ? null : onFavoritePressed,
                    isLargeScreen: isLargeScreen,
                  ),
                  _buildActionButton(
                    icon: Icons.save,
                    color: theme.colorScheme.primary,
                    tooltip: 'Save to gallery',
                    onPressed: isProcessing ? null : onSavePressed,
                    isLargeScreen: isLargeScreen,
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    color: theme.colorScheme.secondary,
                    tooltip: 'Share quote',
                    onPressed: isProcessing ? null : onSharePressed,
                    isLargeScreen: isLargeScreen,
                  ),
                  _buildActionButton(
                    icon: isCached ? Icons.bookmark_added : Icons.bookmark_add,
                    color: isCached
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                    tooltip: isCached
                        ? 'Already saved'
                        : 'Save to $currentCategory collection',
                    onPressed: isProcessing ? null : onCachePressed,
                    isLargeScreen: isLargeScreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool isLargeScreen,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: isLargeScreen ? 32 : 28),
        color: color,
        onPressed: onPressed,
        splashRadius: isLargeScreen ? 28 : 24,
      ),
    );
  }
}
