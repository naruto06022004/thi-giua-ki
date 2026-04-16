import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/news_provider.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(initial: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    final news = context.read<NewsProvider>();
    final hadArticles = news.articles.isNotEmpty;
    await news.loadPosts();
    if (!mounted) return;
    final err = news.error;
    if (err == null) return;

    // Có danh sách cũ (kéo refresh lỗi): SnackBar nổi để đủ yêu cầu đề + không trùng full-screen lỗi.
    if (hadArticles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_userFacingError(err)),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: () => _load(),
          ),
        ),
      );
    }
  }

  static String _userFacingError(Object? err) {
    var s = err?.toString() ?? 'Đã xảy ra lỗi.';
    if (s.startsWith('Exception: ')) {
      s = s.substring('Exception: '.length);
    }
    return s;
  }

  void _onSearchChanged(String value) {
    context.read<NewsProvider>().setSearchQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin tức'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Consumer<NewsProvider>(
            builder: (context, news, _) {
              if (news.loading && news.articles.isNotEmpty) {
                return const LinearProgressIndicator(minHeight: 3);
              }
              return const SizedBox.shrink();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tiêu đề…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: Consumer<NewsProvider>(
              builder: (context, news, _) {
                if (news.loading && news.articles.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải tin tức…'),
                      ],
                    ),
                  );
                }

                final err = news.error;
                if (err != null && news.articles.isEmpty) {
                  return _LoadErrorPane(
                    message: _userFacingError(err),
                    onRetry: () => _load(),
                  );
                }

                final items = news.filteredArticles;

                if (items.isEmpty && !news.loading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        news.searchQuery.trim().isEmpty
                            ? 'Chưa có dữ liệu. Kéo xuống để thử lại.'
                            : 'Không có bài viết khớp với từ khóa.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _load(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final article = items[index];
                      return _ArticleTile(
                        article: article,
                        dateFmt: dateFmt,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DetailScreen(article: article),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Thông báo lỗi ngay trên màn hình (mạng / RSS) + nút thử lại + kéo để refresh.
class _LoadErrorPane extends StatelessWidget {
  const _LoadErrorPane({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRetry,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 72,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tải được tin',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hoặc kéo xuống để tải lại',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.article,
    required this.dateFmt,
    required this.onTap,
  });

  final Article article;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateFmt.format(article.publishedAt),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
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
