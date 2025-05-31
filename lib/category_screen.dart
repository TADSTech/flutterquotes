import 'package:flutter/material.dart';
import 'package:flutterquotes/quote_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutterquotes/quote_provider.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quoteProvider = Provider.of<QuoteProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () => _showAddCategoryDialog(context, quoteProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await quoteProvider.loadCategories();
          return Future.value();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildCategoryList(quoteProvider, colorScheme, theme),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
      QuoteProvider provider, ColorScheme colorScheme, ThemeData theme) {
    if (provider.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category,
              size: 48,
              color: colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first category',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: provider.categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        final quoteCount = provider.getQuotesByCategory(category).length;
        final isDefault = QuoteProvider.defaultCategories.contains(category);

        return _CategoryCard(
          category: category,
          quoteCount: quoteCount,
          isDefault: isDefault,
          color: _getCategoryColor(index, colorScheme),
          onTap: () => _openCategoryQuotes(context, category, provider),
          onDelete: isDefault
              ? null
              : () => _confirmDeleteCategory(context, provider, category),
        );
      },
    );
  }

  Future<void> _confirmDeleteCategory(
      BuildContext context, QuoteProvider provider, String category) async {
    final quotesInCategory = provider.getQuotesByCategory(category).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          quotesInCategory > 0
              ? 'This category contains $quotesInCategory quotes. Deleting it will remove these quotes from the category.'
              : 'Are you sure you want to delete this category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.removeCategory(category);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$category" deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getCategoryColor(int index, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
    ];
    return colors[index % colors.length];
  }

  void _openCategoryQuotes(
      BuildContext context, String category, QuoteProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(category),
            centerTitle: true,
          ),
          body: _CategoryQuotesList(
            category: category,
            provider: provider,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, QuoteProvider provider) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Happiness, Success',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a category name';
              }
              if (provider.categories
                  .any((c) => c.toLowerCase() == value.trim().toLowerCase())) {
                return 'Category already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final category = controller.text.trim();
                await provider.addCategory(category);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$category" added'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final int quoteCount;
  final bool isDefault;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CategoryCard({
    required this.category,
    required this.quoteCount,
    required this.isDefault,
    required this.color,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quoteCount ${quoteCount == 1 ? 'quote' : 'quotes'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDefault)
                IconButton(
                  icon: Icon(
                    Icons.delete_outlined,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete Category',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryQuotesList extends StatelessWidget {
  final String category;
  final QuoteProvider provider;

  const _CategoryQuotesList({
    required this.category,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final quotes = provider.getQuotesByCategory(category);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return quotes.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote,
                  size: 48,
                  color: colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No quotes in this category yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListView.separated(
              itemCount: quotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final quote = quotes[index];
                return _QuoteCard(
                  quote: quote,
                  color: _getQuoteColor(index, colorScheme),
                );
              },
            ),
          );
  }

  Color _getQuoteColor(int index, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final colors = isDark
        ? [
            colorScheme.surface,
            colorScheme.surfaceVariant,
            colorScheme.surface.withOpacity(0.9),
          ]
        : [
            colorScheme.surface,
            colorScheme.surfaceVariant,
            colorScheme.primaryContainer.withOpacity(0.2),
          ];
    return colors[index % colors.length];
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final Color color;

  const _QuoteCard({
    required this.quote,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () {
          Clipboard.setData(ClipboardData(
            text: '"${quote.text}" - ${quote.author}',
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quote copied to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '"${quote.text}"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: isDark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '- ${quote.author}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.8),
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
