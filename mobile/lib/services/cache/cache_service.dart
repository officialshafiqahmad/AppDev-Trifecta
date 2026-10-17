import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/result.dart';

/// Local database cache service for offline-first reads.
abstract class CacheService {
  Future<Result<void>> put(String key, Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>?>> get(String key);
  Future<Result<void>> clear();
}

/// Filesystem-backed persistent cache service.
class CacheServiceImpl implements CacheService {
  Directory? _cacheDir;

  Future<Directory> _getDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/trifecta_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _cacheDir = cacheDir;
    return cacheDir;
  }

  File _fileForKey(Directory dir, String key) {
    final sanitized = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${dir.path}/$sanitized.json');
  }

  @override
  Future<Result<void>> put(String key, Map<String, dynamic> data) async {
    try {
      final dir = await _getDir();
      final file = _fileForKey(dir, key);
      await file.writeAsString(jsonEncode(data), flush: true);
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'CACHE_WRITE_ERROR',
          userMessageKey: 'err_default',
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> get(String key) async {
    try {
      final dir = await _getDir();
      final file = _fileForKey(dir, key);
      if (!await file.exists()) {
        return const Success(null);
      }
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return Success(decoded);
    } catch (e) {
      return const Success(null);
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      final dir = await _getDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'CACHE_CLEAR_ERROR',
          userMessageKey: 'err_default',
          detail: e.toString(),
        ),
      );
    }
  }
}
