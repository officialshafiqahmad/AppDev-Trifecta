import '../../core/utils/result.dart';

/// User roles supported by Trifecta platform.
enum UserRole {
  superAdmin,
  organizer,
  clubManager,
  player,
  viewer,
}

/// Authenticated user session model.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.role,
    required this.tenantId,
    required this.name,
    this.clubId,
    this.leagueId,
  });

  final String id;
  final String email;
  final UserRole role;
  final String tenantId;
  final String name;
  final String? clubId;
  final String? leagueId;

  bool get isOrganizer => role == UserRole.organizer || role == UserRole.superAdmin;
  bool get isClubManager => role == UserRole.clubManager || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.viewer,
      ),
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      clubId: json['clubId'] as String?,
      leagueId: json['leagueId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.name,
        'tenantId': tenantId,
        'name': name,
        'clubId': clubId,
        'leagueId': leagueId,
      };
}

abstract class AuthService {
  SessionUser? get currentUser;

  Future<Result<SessionUser>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<SessionUser?>> getCurrentUser();

  Future<Result<bool>> isAuthenticated();

  Future<Result<String?>> getSessionToken();
}
