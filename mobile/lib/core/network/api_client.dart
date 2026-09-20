import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  ApiResponse({required this.success, this.data, this.errorMessage});
}

class ApiClient {
  final String baseUrl;
  final http.Client _client = http.Client();

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await FirebaseService().getIdToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse<dynamic>> get(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = await _getHeaders();
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body['data']);
      } else {
        final err = body['error']?['message'] ?? 'Request failed with status ${response.statusCode}';
        return ApiResponse(success: false, errorMessage: err);
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> post(String path, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = await _getHeaders();
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body['data']);
      } else {
        final err = body['error']?['message'] ?? 'Request failed with status ${response.statusCode}';
        return ApiResponse(success: false, errorMessage: err);
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> put(String path, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = await _getHeaders();
      final response = await _client.put(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body['data']);
      } else {
        final err = body['error']?['message'] ?? 'Request failed with status ${response.statusCode}';
        return ApiResponse(success: false, errorMessage: err);
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> patch(String path, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = await _getHeaders();
      final response = await _client.patch(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body['data']);
      } else {
        final err = body['error']?['message'] ?? 'Request failed with status ${response.statusCode}';
        return ApiResponse(success: false, errorMessage: err);
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> delete(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = await _getHeaders();
      final response = await _client.delete(uri, headers: headers).timeout(const Duration(seconds: 8));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, data: body['data']);
      } else {
        final err = body['error']?['message'] ?? 'Request failed with status ${response.statusCode}';
        return ApiResponse(success: false, errorMessage: err);
      }
    } catch (e) {
      return ApiResponse(success: false, errorMessage: e.toString());
    }
  }
}
