import 'dart:convert';

import 'package:http/http.dart' as http;

// Windows/Chrome di komputer yang sama: http://127.0.0.1:8000
// Android Emulator: http://10.0.2.2:8000
// HP fisik: ganti dengan IPv4 komputer, contoh http://192.168.1.10:8000
const String apiBaseUrl = 'http://127.0.0.1:8000';

class ApiService {
  ApiService._();

  static String? accessToken;

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    late final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception(
        'Tidak dapat terhubung ke backend. Pastikan FastAPI aktif dan apiBaseUrl benar.',
      );
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } on FormatException {
      // Respons bukan JSON; tampilkan pesan umum di bawah.
    }

    if (response.statusCode == 200) {
      final token = data['access_token'];
      if (token is String && token.isNotEmpty) {
        accessToken = token;
        return;
      }
      throw Exception('Respons login tidak berisi access_token.');
    }

    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      throw Exception(detail);
    }
    throw Exception('Login gagal (HTTP ${response.statusCode}).');
  }

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
}
