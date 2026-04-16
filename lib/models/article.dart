/// Bài viết map từ [JSONPlaceholder](https://jsonplaceholder.typicode.com/posts).
/// Ảnh và ngày đăng được suy ra vì API gốc không có các trường này.
class Article {
  const Article({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;

  /// Ảnh minh họa qua Picsum (ổn định theo `id`).
  String get imageUrl => 'https://picsum.photos/seed/${id}news/400/200';

  /// Ngày đăng giả lập (đa dạng theo `id`).
  DateTime get publishedAt =>
      DateTime(2024, 1, ((id - 1) % 28) + 1).add(Duration(days: id % 120));

  String get summary {
    final t = body.trim();
    if (t.length <= 140) return t;
    return '${t.substring(0, 140)}…';
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: (json['title'] as String).trim(),
      body: (json['body'] as String).trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };
}
