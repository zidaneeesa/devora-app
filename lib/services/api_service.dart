import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiService {
  // Hanya membaca dari file .env. URL gagal dimuat jika terjadi masalah dengan file .env
  static String get baseUrl => ApiConfig.baseUrl;
  static const String _authTokenKey = 'auth_token';
  static String? _sessionToken;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _sessionToken ?? prefs.getString(_authTokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> _saveToken(
    Map<String, dynamic> responseData, {
    bool keepSignedIn = true,
  }) async {
    final token = responseData['access_token']?.toString();

    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = token;

      if (keepSignedIn) {
        await prefs.setString(_authTokenKey, token);
      } else {
        // Mode sekali login: token hanya hidup selama app masih berjalan.
        // Setelah task/app ditutup total, user akan diminta login ulang.
        await prefs.remove(_authTokenKey);
      }
    }
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<bool> hasSavedToken() async {
    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = null;
    await prefs.remove(_authTokenKey);
  }

  // --- AUTH --- //

  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool keepSignedIn = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data, keepSignedIn: keepSignedIn);
    }
    return {'status': response.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await _saveToken(data);
    }
    return {'status': response.statusCode, 'data': data};
  }

  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      );
    } catch (_) {
      // Tetap hapus token lokal walaupun server sedang tidak bisa dihubungi.
    }

    await clearSavedToken();
  }

  static Future<Map<String, dynamic>> registerSendOtp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/send-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      }),
    );

    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> registerVerifyOtp({
    required String email,
    required String phone,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/verify-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({'email': email, 'phone': phone, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      await _saveToken(data);
    }

    return {'status': response.statusCode, 'data': data};
  }

  // --- MEMBER PROFILE --- //

  /// Upload foto avatar ke /member/profile/avatar (multipart)
  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/member/profile/avatar'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.files.add(
      await http.MultipartFile.fromPath('avatar', imageFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);
    return {'status': response.statusCode, 'data': data};
  }

  /// Update nomor HP
  static Future<Map<String, dynamic>> updatePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.put(
      Uri.parse('$baseUrl/member/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'phone': phone}),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  /// Ganti password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/member/change-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  /// Kirim OTP ke email user yang sedang login
  static Future<Map<String, dynamic>> sendOtp() async {
    final response = await http.post(
      Uri.parse('$baseUrl/member/send-otp'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  /// Reset password menggunakan OTP
  static Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/member/reset-password-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'otp': otp,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      }),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // --- FORGOT PASSWORD --- //

  static Future<Map<String, dynamic>> forgotSendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/send-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({'email': email}),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> forgotVerifyOtp(
    String email,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/verify-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> forgotResetPassword(
    String email,
    String resetToken,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/reset'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': password,
      }),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // --- CLAIM ACCOUNT --- //

  static Future<Map<String, dynamic>> claimLookup(String nisNip) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/claim-lookup'),
      headers: await _getHeaders(),
      body: jsonEncode({'nis_nip': nisNip}),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> claimActivateSendOtp({
    required int memberId,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/claim-activate/send-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'member_id': memberId,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> claimActivateVerifyOtp({
    required int memberId,
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/claim-activate/verify-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({'member_id': memberId, 'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _saveToken(data);
    }

    return {'status': response.statusCode, 'data': data};
  }
  // --- APP FEATURES --- //

  static Future<Map<String, dynamic>> getBooks({
    int page = 1,
    String q = '',
    String sort = '',
  }) async {
    final queryParams = <String>[];
    queryParams.add('page=$page');
    if (q.isNotEmpty) queryParams.add('q=$q');
    if (sort.isNotEmpty && sort != 'Semua') queryParams.add('sort=$sort');

    final queryString = queryParams.join('&');
    final response = await http.get(
      Uri.parse('$baseUrl/books?$queryString'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getBookDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/books/$id'),
      headers: await _getHeaders(),
    );

    return {
      'status': response.statusCode,
      'data': jsonDecode(response.body)['data'],
    };
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getLoans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/loans'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  // --- BOOK COLLECTIONS --- //

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return {'status': response.statusCode, ...decoded};
      }

      return {'status': response.statusCode, 'data': decoded};
    } catch (_) {
      return {
        'status': response.statusCode,
        'message': response.body.isNotEmpty
            ? response.body
            : 'Response tidak valid dari server',
      };
    }
  }

  static String _bookIdFromMap(Map<String, dynamic> book) {
    final id =
        book['id'] ??
        book['book_id'] ??
        book['id_buku'] ??
        book['isbn'] ??
        book['title'];

    return id?.toString() ?? '';
  }

  static Future<Map<String, dynamic>> getBookCollections(String nik) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/book-collections?nik=${Uri.encodeQueryComponent(nik)}',
        ),
        headers: await _getHeaders(),
      );

      return _decodeResponse(response);
    } catch (e) {
      return {
        'status': 500,
        'message': 'Gagal mengambil koleksi buku: $e',
        'data': [],
      };
    }
  }

  static Future<Map<String, dynamic>> addBookCollection({
    required String nik,
    required Map<String, dynamic> book,
    String collectionType = 'catalog',
  }) async {
    try {
      final bookId = _bookIdFromMap(book);

      if (bookId.isEmpty) {
        return {'status': 422, 'message': 'ID buku tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/book-collections'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'nik': nik,
          'book_id': bookId,
          'title': book['title']?.toString() ?? 'Tanpa Judul',
          'author': book['author']?.toString() ?? '-',
          'cover_image': book['cover_image']?.toString(),
          'collection_type': collectionType,
          'book_data': {...book, 'collection_type': collectionType},
        }),
      );

      return _decodeResponse(response);
    } catch (e) {
      return {'status': 500, 'message': 'Gagal menyimpan buku: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteBookCollection({
    required String nik,
    required String bookId,
    String collectionType = 'catalog',
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$baseUrl/book-collections/${Uri.encodeComponent(bookId)}'
          '?nik=${Uri.encodeQueryComponent(nik)}'
          '&collection_type=${Uri.encodeQueryComponent(collectionType)}',
        ),
        headers: await _getHeaders(),
      );

      return _decodeResponse(response);
    } catch (e) {
      return {'status': 500, 'message': 'Gagal menghapus koleksi buku: $e'};
    }
  }

  // --- NOTIFICATIONS --- //

  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> markNotificationRead(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<void> saveFcmToken(String token, String device) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/member/fcm-token'),
        headers: await _getHeaders(),
        body: jsonEncode({'token': token, 'device': device}),
      );
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getEbooks(
    String query, {
    String source = 'all',
    int page = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/ebooks/search').replace(
        queryParameters: {
          'q': query.trim(),
          'source': source,
          'page': page.toString(),
        },
      );

      final response = await http.get(uri, headers: await _getHeaders());

      final decoded = jsonDecode(response.body);

      return {
        'status': response.statusCode,
        'data': decoded['data'] ?? [],
        'message': decoded['message'] ?? '',
      };
    } catch (e) {
      return {
        'status': 500,
        'data': [],
        'message': 'Gagal mengambil ebook: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getEbookDetail(
    String id, {
    String source = 'internet_archive',
  }) async {
    try {
      final safeSource = Uri.encodeComponent(source);
      final safeId = Uri.encodeComponent(id);

      final response = await http.get(
        Uri.parse('$baseUrl/ebooks/$safeSource/$safeId'),
        headers: await _getHeaders(),
      );

      final decoded = _decodeResponse(response);

      return {
        'status': response.statusCode,
        'data': decoded['data'],
        'message': decoded['message'] ?? '',
      };
    } catch (e) {
      return {
        'status': 500,
        'data': null,
        'message': 'Gagal mengambil detail ebook: $e',
      };
    }
  }

  static Future<List<dynamic>> getAllReadingProgress() async {
    final res = await http.get(
      Uri.parse('$baseUrl/reading-progress'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  }
  // --- CHATBOT --- //

  static Future<Map<String, dynamic>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/conversations'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> createConversation() async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/conversations'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> deleteConversation(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/chatbot/conversations/$id'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getMessages(int conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chatbot/conversations/$conversationId/messages'),
      headers: await _getHeaders(),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    int conversationId,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chatbot/send'),
      headers: await _getHeaders(),
      body: jsonEncode({'conversation_id': conversationId, 'message': message}),
    );
    return {'status': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>> getReadingProgress(String ebookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reading-progress/$ebookId'),
        headers: await _getHeaders(),
      );

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      final progressData = decoded is Map && decoded['data'] != null
          ? decoded['data']
          : decoded;

      return {'status': response.statusCode, 'data': progressData};
    } catch (e) {
      return {
        'status': 500,
        'data': null,
        'message': 'Gagal mengambil progress: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateReadingProgress(
    String ebookId,
    double progress,
    int currentPage,
    int totalPage,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reading-progress/update'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'ebook_id': ebookId,
          'progress': progress,
          'current_page': currentPage,
          'total_page': totalPage,
        }),
      );

      print('UPDATE PROGRESS RESPONSE: ${res.body}');

      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {
        'status': 500,
        'data': null,
        'message': 'Gagal update progress: $e',
      };
    }
  }
}
