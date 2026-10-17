import '../../core/utils/result.dart';

/// Pure service interface for Authentication operations.
abstract class AuthService {
  Future<Result<bool>> isAuthenticated();
  Future<Result<String?>> getAuthToken();
  Future<Result<void>> setAuthToken(String token);
  Future<Result<void>> logout();
}
