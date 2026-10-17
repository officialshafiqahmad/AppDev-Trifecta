import '../../core/utils/result.dart';

/// Pure service interface for API operations.
/// Features only ever depend on this interface, never concrete implementations.
abstract class ApiService {
  Future<Result<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  });

  Future<Result<Map<String, dynamic>>> post(
    String endpoint, {
    dynamic data,
  });

  Future<Result<Map<String, dynamic>>> put(
    String endpoint, {
    dynamic data,
  });

  Future<Result<Map<String, dynamic>>> delete(
    String endpoint,
  );
}
