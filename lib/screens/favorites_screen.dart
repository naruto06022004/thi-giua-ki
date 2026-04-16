import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu thích'),
        elevation: 0,
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, fav, _) {
          final list = fav.favorites;

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có bài viết yêu thích.\nMở chi tiết tin và chọn biểu tượng trái tim.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final article = list[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.article_outlined),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(dateFmt.format(article.publishedAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Bỏ yêu thích',
                  onPressed: () {
                    fav.removeFavorite(article.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa khỏi yêu thích'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DetailScreen(article: article),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
