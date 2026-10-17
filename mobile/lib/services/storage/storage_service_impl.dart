import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import 'storage_service.dart';

/// In-memory / persistent storage implementation.
class StorageServiceImpl implements StorageService {
  final Map<String, String> _memoryStore = <String, String>{};

  @override
  Future<Result<void>> setString(String key, String value) async {
    try {
      _memoryStore[key] = value;
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'storage_write_error',
          userMessageKey: AppStrings.errorDefault,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<String?>> getString(String key) async {
    try {
      return Success(_memoryStore[key]);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'storage_read_error',
          userMessageKey: AppStrings.errorDefault,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<void>> remove(String key) async {
    try {
      _memoryStore.remove(key);
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'storage_remove_error',
          userMessageKey: AppStrings.errorDefault,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      _memoryStore.clear();
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'storage_clear_error',
          userMessageKey: AppStrings.errorDefault,
          detail: e.toString(),
        ),
      );
    }
  }
}
