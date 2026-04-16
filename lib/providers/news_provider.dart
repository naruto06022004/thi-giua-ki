import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  List<Article> _articles = [];
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  List<Article> get articles => _articles;

  /// Danh sách sau khi lọc theo tiêu đề (màn hình chính).
  List<Article> get filteredArticles {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List<Article>.from(_articles);
    return _articles
        .where((a) => a.title.toLowerCase().contains(q))
        .toList();
  }

  String get searchQuery => _searchQuery;
  bool get loading => _loading;
  String? get error => _error;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> loadPosts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _articles = await NewsService.fetchPosts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
