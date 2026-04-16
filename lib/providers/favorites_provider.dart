import 'package:flutter/foundation.dart';

import '../models/article.dart';

/// Lưu các bài đã đánh dấu "Yêu thích" (theo `id`).
class FavoritesProvider extends ChangeNotifier {
  final Map<int, Article> _byId = {};

  List<Article> get favorites {
    final list = _byId.values.toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  bool isFavorite(int articleId) => _byId.containsKey(articleId);

  void toggleFavorite(Article article) {
    if (_byId.containsKey(article.id)) {
      _byId.remove(article.id);
    } else {
      _byId[article.id] = article;
    }
    notifyListeners();
  }

  void removeFavorite(int articleId) {
    if (_byId.remove(articleId) != null) {
      notifyListeners();
    }
  }
}
