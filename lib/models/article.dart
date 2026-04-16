/// Bài viết lấy từ RSS tiếng Việt (VnExpress).
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    required this.link,
    this.sourceImageUrl,
  });

  /// Ổn định theo URL (dùng cho yêu thích).
  final int id;
  final String title;
  /// Nội dung hiển thị (đoạn dẫn từ RSS; bài đầy đủ mở trên trình duyệt).
  final String body;
  final DateTime publishedAt;
  final String link;
  final String? sourceImageUrl;

  String get imageUrl =>
      (sourceImageUrl != null && sourceImageUrl!.isNotEmpty)
          ? sourceImageUrl!
          : 'https://picsum.photos/seed/${id}vn/400/200';

  String get summary {
    final t = body.trim();
    if (t.length <= 140) return t;
    return '${t.substring(0, 140)}…';
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      link: json['link'] as String,
      sourceImageUrl: json['sourceImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'publishedAt': publishedAt.toIso8601String(),
        'link': link,
        'sourceImageUrl': sourceImageUrl,
      };
}
