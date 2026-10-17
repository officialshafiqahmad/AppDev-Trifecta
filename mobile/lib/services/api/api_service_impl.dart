import '../../config/app_config.dart';
import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import 'api_service.dart';

/// Concrete API service implementation.
/// In production, network client packages (e.g. dio, http) are encapsulated here.
class ApiServiceImpl implements ApiService {
  ApiServiceImpl({required this.config});

  final AppConfig config;

  @override
  Future<Result<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      // Clean implementation placeholder returning simulated successful API response
      // or ready to attach Dio/Http without leaking into features.
      return const Success(<String, dynamic>{
        'status': 'ok',
        'data': <String, dynamic>{},
      });
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'network_error',
          userMessageKey: AppStrings.errorNetwork,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> post(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      return const Success(<String, dynamic>{
        'status': 'ok',
        'data': <String, dynamic>{},
      });
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'network_error',
          userMessageKey: AppStrings.errorNetwork,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> put(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      return const Success(<String, dynamic>{
        'status': 'ok',
        'data': <String, dynamic>{},
      });
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'network_error',
          userMessageKey: AppStrings.errorNetwork,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> delete(
    String endpoint,
  ) async {
    try {
      return const Success(<String, dynamic>{
        'status': 'ok',
      });
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'network_error',
          userMessageKey: AppStrings.errorNetwork,
          detail: e.toString(),
        ),
      );
    }
  }
}
