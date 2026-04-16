import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/favorites_provider.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Quay lại',
        ),
        title: const Text('Chi tiết'),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, fav, _) {
              final isFav = fav.isFavorite(article.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? theme.colorScheme.error : null,
                ),
                tooltip: 'Yêu thích',
                onPressed: () {
                  fav.toggleFavorite(article);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        fav.isFavorite(article.id)
                            ? 'Đã thêm vào yêu thích'
                            : 'Đã bỏ khỏi yêu thích',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 56,
                    color: theme.colorScheme.outline,
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
                    article.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng ngày ${dateFmt.format(article.publishedAt)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Divider(height: 28),
                  SelectableText(
                    article.body,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
