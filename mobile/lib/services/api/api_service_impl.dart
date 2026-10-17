import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/strings/app_strings.dart';
import '../../core/utils/api_error_mapper.dart';
import '../../core/utils/result.dart';
import '../settings/settings_service.dart';
import 'api_service.dart';

/// Concrete API service implementation backed by the http package.
/// Strictly follows INTEGRATION_PLAN.md Section 0:
/// - Builds URL from persisted Settings host
/// - Sets Content-Type: application/json
/// - On non-2xx parses { "error": { "code": "...", "message": "...", "details": {...} } }
/// - Maps error codes via ApiErrorMapper into AppStrings keys
class ApiServiceImpl implements ApiService {
  ApiServiceImpl({
    required this.settingsService,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final SettingsService settingsService;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  Future<Uri> _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) async {
    final settingsRes = await settingsService.getSettings();
    final baseUrl = settingsRes.dataOrNull?.baseUrl ?? 'https://astjq-203-99-61-238.free.pinggy.net';
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$baseUrl$cleanEndpoint';

    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...stringParams,
      });
    }
    return uri;
  }

  Map<String, String> _defaultHeaders(Map<String, String>? customHeaders) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (customHeaders != null) ...customHeaders,
    };
  }

  Result<dynamic> _handleResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Success(decoded ?? <String, dynamic>{});
    }

    // Parse backend error envelope: { "error": { "code": "...", "message": "...", "details": {...} } }
    String? code;
    String? message;
    if (decoded is Map<String, dynamic>) {
      if (decoded['error'] is Map<String, dynamic>) {
        code = decoded['error']['code'] as String?;
        message = decoded['error']['message'] as String?;
      } else {
        code = decoded['code'] as String?;
        message = decoded['message'] as String?;
      }
    }

    final messageKey = ApiErrorMapper.userMessageKeyForCode(code);
    return Failure(
      AppFailure(
        code: code ?? 'HTTP_${response.statusCode}',
        userMessageKey: messageKey,
        detail: message ?? response.body,
      ),
    );
  }

  Result<dynamic> _handleError(Object error) {
    return Failure(
      AppFailure(
        code: 'NETWORK_ERROR',
        userMessageKey: AppStrings.errNetwork,
        detail: error.toString(),
      ),
    );
  }

  @override
  Future<Result<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = await _buildUri(endpoint, queryParameters);
      final response = await _client.get(
        uri,
        headers: _defaultHeaders(headers),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Result<dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = await _buildUri(endpoint);
      final body = data != null ? jsonEncode(data) : null;
      final response = await _client.post(
        uri,
        headers: _defaultHeaders(headers),
        body: body,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Result<dynamic>> put(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = await _buildUri(endpoint);
      final body = data != null ? jsonEncode(data) : null;
      final response = await _client.put(
        uri,
        headers: _defaultHeaders(headers),
        body: body,
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Result<dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = await _buildUri(endpoint);
      final response = await _client.delete(
        uri,
        headers: _defaultHeaders(headers),
      ).timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
}
