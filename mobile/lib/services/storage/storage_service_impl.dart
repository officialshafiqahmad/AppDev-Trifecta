import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import 'storage_service.dart';

/// Filesystem-persisted storage implementation for settings, tokens, and client preferences.
/// Separate from cacheService so clearCache never deletes settings or persistent state.
class StorageServiceImpl implements StorageService {
  StorageServiceImpl() {
    _initDisk();
  }

  final Map<String, String> _memoryStore = <String, String>{};
  File? _storageFile;
  bool _initialized = false;

  Future<void> _initDisk() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _storageFile = File('${appDir.path}/trifecta_persistent_storage.json');
      if (await _storageFile!.exists()) {
        final content = await _storageFile!.readAsString();
        if (content.isNotEmpty) {
          final Map<String, dynamic> decoded = jsonDecode(content);
          decoded.forEach((key, value) {
            _memoryStore[key] = value.toString();
          });
        }
      }
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<void> _flush() async {
    try {
      if (_storageFile != null) {
        await _storageFile!.writeAsString(jsonEncode(_memoryStore), flush: true);
      }
    } catch (_) {}
  }

  @override
  Future<Result<void>> setString(String key, String value) async {
    try {
      if (!_initialized) await _initDisk();
      _memoryStore[key] = value;
      await _flush();
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
      if (!_initialized) await _initDisk();
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
      if (!_initialized) await _initDisk();
      _memoryStore.remove(key);
      await _flush();
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
      if (!_initialized) await _initDisk();
      _memoryStore.clear();
      await _flush();
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
