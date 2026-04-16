import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import '../models/article.dart';

class NewsService {
  NewsService._();

  /// RSS tin nổi bật — nội dung tiếng Việt, không cần API key.
  /// Nguồn: [VnExpress RSS](https://vnexpress.net/rss/tin-noi-bat.rss).
  static const String rssUrl =
      'https://vnexpress.net/rss/tin-noi-bat.rss';

  /// Trên Web, dùng [rss2json.com](https://rss2json.com) để nhận JSON (CORS ổn định hơn proxy raw).
  static final Uri _rss2JsonUri = Uri.parse(
    'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(rssUrl)}',
  );

  static final _rfc822 = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z', 'en');

  static Future<List<Article>> fetchPosts() async {
    try {
      if (kIsWeb) {
        return await _fetchPostsWeb();
      }
      return await _fetchPostsNativeXml();
    } on SocketException {
      throw Exception(
        'Không có kết nối mạng. Vui lòng kiểm tra Wi‑Fi hoặc dữ liệu di động.',
      );
    } on HttpException catch (e) {
      throw Exception('Lỗi HTTP: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tải dữ liệu: $e');
    }
  }

  /// Web: JSON (rss2json) → nếu lỗi thì RSS XML qua vài proxy CORS dự phòng.
  static Future<List<Article>> _fetchPostsWeb() async {
    try {
      final res = await http
          .get(
            _rss2JsonUri,
            headers: const {
              'User-Agent': 'Mozilla/5.0 (compatible; NewsApp/1.0)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          res.body.trim().isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded['status'] == 'ok') {
          final fromJson = _articlesFromRss2Json(decoded);
          if (fromJson.isNotEmpty) {
            return fromJson;
          }
        }
      }
    } catch (_) {
      // Thử proxy XML bên dưới
    }

    final xmlBody = await _fetchRssXmlThroughProxies();
    return _parseRssXmlToArticles(xmlBody);
  }

  /// Android / iOS / desktop: gọi trực tiếp RSS XML.
  static Future<List<Article>> _fetchPostsNativeXml() async {
    final res = await http
        .get(
          Uri.parse(rssUrl),
          headers: const {
            'User-Agent': 'Mozilla/5.0 (compatible; NewsApp/1.0; +edu)',
            'Accept': 'application/rss+xml, application/xml, text/xml, */*',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Máy chủ RSS trả về lỗi (mã ${res.statusCode}).');
    }

    final body = res.body;
    if (body.trim().isEmpty) {
      throw Exception('Không nhận được nội dung RSS.');
    }

    return _parseRssXmlToArticles(body);
  }

  static List<Article> _articlesFromRss2Json(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      return [];
    }

    final list = <Article>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final title = (m['title'] as String?)?.trim() ?? '';
      final link = (m['link'] as String?)?.trim() ?? '';
      if (title.isEmpty || link.isEmpty) continue;

      final desc = m['description'] as String? ?? '';
      final plain = _plainTextFromHtml(desc);

      String? imageUrl;
      final enc = m['enclosure'];
      if (enc is Map) {
        final l = enc['link'] as String?;
        if (l != null && l.isNotEmpty) {
          imageUrl = l.replaceAll('&amp;', '&');
        }
      }
      final thumb = (m['thumbnail'] as String?)?.trim();
      if (thumb != null && thumb.isNotEmpty) {
        imageUrl ??= thumb;
      }
      imageUrl ??= _firstImgSrc(desc);

      final pubRaw = m['pubDate'] as String? ?? '';
      final published = _parseRss2JsonPubDate(pubRaw);

      final id = Object.hash(link, title) & 0x7fffffff;

      list.add(
        Article(
          id: id == 0 ? 1 : id,
          title: title,
          body: plain.isNotEmpty ? plain : title,
          publishedAt: published,
          link: link,
          sourceImageUrl: imageUrl,
        ),
      );
    }

    return list;
  }

  static DateTime _parseRss2JsonPubDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return DateTime.now();
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2} \d').hasMatch(s)) {
        return DateTime.parse(s.replaceFirst(' ', 'T'));
      }
    } catch (_) {}
    return _parsePubDate(s);
  }

  static Future<String> _fetchRssXmlThroughProxies() async {
    final urls = <String>[
      'https://corsproxy.io/?${Uri.encodeComponent(rssUrl)}',
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(rssUrl)}',
      'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(rssUrl)}',
    ];

    Object? lastError;
    for (final url in urls) {
      try {
        final res = await http
            .get(
              Uri.parse(url),
              headers: const {
                'User-Agent': 'Mozilla/5.0 (compatible; NewsApp/1.0; +edu)',
                'Accept': 'application/rss+xml, application/xml, text/xml, */*',
              },
            )
            .timeout(const Duration(seconds: 25));
        if (res.statusCode >= 200 &&
            res.statusCode < 300 &&
            res.body.trim().isNotEmpty) {
          return res.body;
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('Không tải được RSS qua proxy.');
  }

  static List<Article> _parseRssXmlToArticles(String body) {
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(body);
    } catch (e) {
      throw Exception('Không đọc được định dạng RSS: $e');
    }

    final items = doc.findAllElements('item');
    final list = <Article>[];

    for (final item in items) {
      final title = _elText(item, 'title');
      final link = _elText(item, 'link');
      if (title.isEmpty || link.isEmpty) continue;

      final rawDesc = _descriptionHtml(item);
      final plain = _plainTextFromHtml(rawDesc);

      final enclosureUrl = item
          .getElement('enclosure')
          ?.getAttribute('url')
          ?.replaceAll('&amp;', '&');

      final pubRaw = _elText(item, 'pubDate');
      final published = _parsePubDate(pubRaw);

      final id = Object.hash(link, title) & 0x7fffffff;

      list.add(
        Article(
          id: id == 0 ? 1 : id,
          title: title,
          body: plain.isNotEmpty ? plain : title,
          publishedAt: published,
          link: link,
          sourceImageUrl: (enclosureUrl != null && enclosureUrl.isNotEmpty)
              ? enclosureUrl
              : _firstImgSrc(rawDesc),
        ),
      );
    }

    if (list.isEmpty) {
      throw Exception('RSS không có bài viết nào.');
    }

    return list;
  }

  static String _elText(XmlElement parent, String name) {
    return parent.getElement(name)?.innerText.trim() ?? '';
  }

  /// Nội dung thẻ &lt;description&gt; (CDATA chứa HTML).
  static String _descriptionHtml(XmlElement item) {
    final el = item.getElement('description');
    if (el == null) return '';
    final parts = <String>[];
    for (final c in el.children) {
      if (c is XmlCDATA) {
        parts.add(c.value);
      } else if (c is XmlText) {
        parts.add(c.value);
      }
    }
    return parts.join();
  }

  static String _plainTextFromHtml(String html) {
    if (html.trim().isEmpty) return '';
    final doc = html_parser.parse(html);
    final text = doc.body?.text ?? '';
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _firstImgSrc(String html) {
    final re = RegExp(
      '''<img[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    );
    final m = re.firstMatch(html);
    if (m == null) return null;
    return m.group(1)?.replaceAll('&amp;', '&');
  }

  static DateTime _parsePubDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return DateTime.now();
    try {
      return HttpDate.parse(s);
    } catch (_) {
      try {
        return _rfc822.parse(s);
      } catch (_) {
        try {
          return DateTime.parse(s);
        } catch (_) {
          return DateTime.now();
        }
      }
    }
  }
}
