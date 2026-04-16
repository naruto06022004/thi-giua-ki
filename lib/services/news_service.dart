import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/article.dart';

class NewsService {
  NewsService._();

  static const String _postsUrl =
      'https://jsonplaceholder.typicode.com/posts';

  static Future<List<Article>> fetchPosts() async {
    late final http.Response res;
    try {
      res = await http.get(Uri.parse(_postsUrl)).timeout(
        const Duration(seconds: 15),
      );
    } on SocketException {
      throw Exception('Không có kết nối mạng. Vui lòng kiểm tra Wi‑Fi hoặc dữ liệu di động.');
    } on HttpException catch (e) {
      throw Exception('Lỗi HTTP: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tải dữ liệu: $e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API trả về lỗi (mã ${res.statusCode}).');
    }

    final decoded = json.decode(res.body);
    if (decoded is! List) {
      throw Exception('Định dạng dữ liệu không hợp lệ.');
    }

    return decoded
        .map((e) => Article.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
