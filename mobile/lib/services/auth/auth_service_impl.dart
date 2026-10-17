import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/strings/app_strings.dart';
import '../../core/utils/result.dart';
import 'auth_service.dart';

/// Secure-storage backed authentication service with mock accounts.
class AuthServiceImpl implements AuthService {
  AuthServiceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _keyToken = 'auth_session_token';
  static const String _keyUser = 'auth_session_user';

  // Demo accounts definition from FRONTEND_BRIEF.md
  static const Map<String, (String password, SessionUser user)> _demoUsers = {
    'admin@nascon.test': (
      'Nascon@26',
      SessionUser(
        id: 'usr-admin-1',
        email: 'admin@nascon.test',
        role: UserRole.superAdmin,
        tenantId: 'tenant-alpha',
        name: 'Platform Super-Admin',
      ),
    ),
    'organizer@nascon.test': (
      'Nascon@26',
      SessionUser(
        id: 'usr-org-1',
        email: 'organizer@nascon.test',
        role: UserRole.organizer,
        tenantId: 'tenant-alpha',
        name: 'League Organizer',
        leagueId: 'league-alpha-1',
      ),
    ),
    'manager@nascon.test': (
      'Nascon@26',
      SessionUser(
        id: 'usr-mgr-1',
        email: 'manager@nascon.test',
        role: UserRole.clubManager,
        tenantId: 'tenant-alpha',
        name: 'Club Manager',
        clubId: 'club-alpha-1',
      ),
    ),
    'player@nascon.test': (
      'Nascon@26',
      SessionUser(
        id: 'usr-player-1',
        email: 'player@nascon.test',
        role: UserRole.player,
        tenantId: 'tenant-alpha',
        name: 'Player',
        clubId: 'club-alpha-1',
      ),
    ),
    'viewer@nascon.test': (
      'Nascon@26',
      SessionUser(
        id: 'usr-viewer-1',
        email: 'viewer@nascon.test',
        role: UserRole.viewer,
        tenantId: 'tenant-alpha',
        name: 'General Viewer',
      ),
    ),
  };

  @override
  Future<Result<SessionUser>> login({
    required String email,
    required String password,
  }) async {
    final entry = _demoUsers[email.trim().toLowerCase()];
    if (entry == null || entry.$1 != password) {
      return const Failure(
        AppFailure(
          code: 'UNAUTHENTICATED',
          userMessageKey: AppStrings.loginInvalidCreds,
        ),
      );
    }

    final user = entry.$2;
    final token = 'mock_jwt_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _storage.write(key: _keyToken, value: token);
      await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
      return Success(user);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'STORAGE_ERROR',
          userMessageKey: AppStrings.errDefault,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyUser);
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure(
          code: 'LOGOUT_FAILED',
          userMessageKey: AppStrings.errDefault,
          detail: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Result<SessionUser?>> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: _keyUser);
      if (userJson == null) return const Success(null);
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return Success(SessionUser.fromJson(map));
    } catch (e) {
      return const Success(null);
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final token = await _storage.read(key: _keyToken);
      return Success(token != null && token.isNotEmpty);
    } catch (e) {
      return const Success(false);
    }
  }

  @override
  Future<Result<String?>> getSessionToken() async {
    try {
      final token = await _storage.read(key: _keyToken);
      return Success(token);
    } catch (e) {
      return const Success(null);
    }
  }
}
