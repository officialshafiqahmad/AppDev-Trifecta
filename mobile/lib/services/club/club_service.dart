import '../../core/utils/result.dart';

/// Player representation within a club roster.
class Player {
  const Player({
    required this.playerId,
    required this.name,
    required this.position,
    required this.role,
    required this.jerseyNumber,
    this.squadId = 'squad-alpha-1',
  });

  final String playerId;
  final String name;
  final String position;
  final String role;
  final int jerseyNumber;
  final String squadId;

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      role: json['role'] as String? ?? 'Player',
      jerseyNumber: json['jerseyNumber'] as int? ?? 10,
      squadId: json['squadId'] as String? ?? 'squad-alpha-1',
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'name': name,
        'position': position,
        'role': role,
        'jerseyNumber': jerseyNumber,
        'squadId': squadId,
      };
}

/// Staff member representation.
class StaffMember {
  const StaffMember({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
      };
}

/// Club profile representation.
class ClubProfile {
  const ClubProfile({
    required this.clubId,
    required this.tenantId,
    required this.name,
    required this.venueName,
    required this.venueLat,
    required this.venueLng,
    required this.roster,
    required this.staff,
  });

  final String clubId;
  final String tenantId;
  final String name;
  final String venueName;
  final double venueLat;
  final double venueLng;
  final List<Player> roster;
  final List<StaffMember> staff;

  factory ClubProfile.fromJson(Map<String, dynamic> json) {
    return ClubProfile(
      clubId: json['clubId'] as String,
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      venueName: json['venueName'] as String,
      venueLat: (json['venueLat'] as num).toDouble(),
      venueLng: (json['venueLng'] as num).toDouble(),
      roster: (json['roster'] as List<dynamic>? ?? [])
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      staff: (json['staff'] as List<dynamic>? ?? [])
          .map((s) => StaffMember.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'clubId': clubId,
        'tenantId': tenantId,
        'name': name,
        'venueName': venueName,
        'venueLat': venueLat,
        'venueLng': venueLng,
        'roster': roster.map((p) => p.toJson()).toList(),
        'staff': staff.map((s) => s.toJson()).toList(),
      };
}

/// Club service contract.
abstract class ClubService {
  Future<Result<ClubProfile>> getClubProfile(String clubId);
}
