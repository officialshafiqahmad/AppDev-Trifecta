import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import '../storage/storage_service.dart';
import 'auth_service.dart';

/// Concrete authentication service using StorageService.
class AuthServiceImpl implements AuthService {
  AuthServiceImpl({required this.storageService});

  final StorageService storageService;
  static const String _authTokenKey = 'trifecta_auth_token';

  @override
  Future<Result<bool>> isAuthenticated() async {
    final tokenResult = await storageService.getString(_authTokenKey);
    return switch (tokenResult) {
      Success(:final value) => Success(value != null && value.isNotEmpty),
      Failure(:final failure) => Failure(failure),
    };
  }

  @override
  Future<Result<String?>> getAuthToken() async {
    return storageService.getString(_authTokenKey);
  }

  @override
  Future<Result<void>> setAuthToken(String token) async {
    return storageService.setString(_authTokenKey, token);
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await storageService.remove(_authTokenKey);
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'logout_failed',
          userMessageKey: AppStrings.errorDefault,
          detail: e.toString(),
        ),
      );
    }
  }
}
