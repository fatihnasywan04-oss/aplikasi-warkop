
import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

class ApiService {
  ApiService._();

  static String? accessToken;

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    late final http.Response response;

    try {
      response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception('Tidak dapat terhubung ke backend.');
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } on FormatException {
      // Respons bukan JSON.
    }

    if (response.statusCode == 200) {
      final token = data['access_token'];
      if (token is String && token.isNotEmpty) {
        accessToken = token;
        return;
      }
      throw Exception('Respons login tidak berisi access_token.');
    }

    throw Exception(
      data['detail']?.toString() ?? 'Login gagal.',
    );
  }

  // Menu publik: tidak memerlukan login admin.
  static Future<List<Map<String, dynamic>>> getPublicMenus() async {
    final response = await http
        .get(Uri.parse('$apiBaseUrl/api/public/menus'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil menu dari server.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Format data menu tidak sesuai.');
    }

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Pesanan publik: tidak mengirim token admin.
  static Future<Map<String, dynamic>> createPublicOrder({
    required String customerName,
    String? customerPhone,
    required String tableNumber,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/public/orders'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customer_name': customerName.trim(),
        'customer_phone': customerPhone?.trim().isNotEmpty == true
            ? customerPhone!.trim()
            : null,
        'table_number': tableNumber,
        'items': items,
      }),
    ).timeout(const Duration(seconds: 15));

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } on FormatException {
      // Respons bukan JSON.
    }

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['detail']?.toString() ?? 'Pesanan gagal dikirim.',
    );
  }

  // Header khusus endpoint admin.
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (accessToken != null)
      'Authorization': 'Bearer $accessToken',
  };
}
