import '../../core/utils/result.dart';

/// Pure service interface for local key-value and offline storage.
abstract class StorageService {
  Future<Result<void>> setString(String key, String value);
  Future<Result<String?>> getString(String key);
  Future<Result<void>> remove(String key);
  Future<Result<void>> clear();
}
