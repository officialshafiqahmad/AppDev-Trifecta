import '../../core/utils/result.dart';

/// Pure service interface for API operations.
/// Features only ever depend on this interface, never concrete implementations.
abstract class ApiService {
  Future<Result<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<Result<dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
  });

  Future<Result<dynamic>> put(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
  });

  Future<Result<dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  });
}
