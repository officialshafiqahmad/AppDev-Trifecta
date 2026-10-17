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
      playerId: (json['player_id'] ?? json['playerId']) as String,
      name: (json['name']) as String,
      position: (json['position']) as String,
      role: (json['role']) as String? ?? 'Player',
      jerseyNumber: (json['jersey_number'] ?? json['jerseyNumber']) as int? ?? 10,
      squadId: (json['squad_id'] ?? json['squadId']) as String? ?? 'squad-alpha-1',
    );
  }

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'name': name,
        'position': position,
        'role': role,
        'jersey_number': jerseyNumber,
        'squad_id': squadId,
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
      name: (json['name']) as String,
      role: (json['role']) as String,
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
    this.tenantName = 'Punjab FA / Lahore District League',
    required this.name,
    required this.venueName,
    this.venueAddress = 'Lahore',
    required this.venueLat,
    required this.venueLng,
    required this.roster,
    required this.staff,
  });

  final String clubId;
  final String tenantId;
  final String tenantName;
  final String name;
  final String venueName;
  final String venueAddress;
  final double venueLat;
  final double venueLng;
  final List<Player> roster;
  final List<StaffMember> staff;

  /// Formatted venue presentation string adhering to UX rule C19:
  /// e.g. "Home Venue: A-01 Main Arena · Lahore (31.52° N, 74.36° E)"
  String get formattedVenue {
    final latStr = '${venueLat.abs().toStringAsFixed(2)}° ${venueLat >= 0 ? "N" : "S"}';
    final lngStr = '${venueLng.abs().toStringAsFixed(2)}° ${venueLng >= 0 ? "E" : "W"}';
    return '$venueName · $venueAddress ($latStr, $lngStr)';
  }

  factory ClubProfile.fromJson(Map<String, dynamic> json) {
    return ClubProfile(
      clubId: (json['club_id'] ?? json['clubId']) as String,
      tenantId: (json['tenant_id'] ?? json['tenantId']) as String,
      tenantName: (json['tenant_name'] ?? json['tenantName']) as String? ?? 'Punjab FA / Lahore District League',
      name: (json['name']) as String,
      venueName: (json['venue_name'] ?? json['venueName']) as String,
      venueAddress: (json['venue_address'] ?? json['venueAddress']) as String? ?? 'Lahore',
      venueLat: ((json['venue_lat'] ?? json['venueLat']) as num).toDouble(),
      venueLng: ((json['venue_lng'] ?? json['venueLng']) as num).toDouble(),
      roster: ((json['roster']) as List<dynamic>? ?? [])
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      staff: ((json['staff']) as List<dynamic>? ?? [])
          .map((s) => StaffMember.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'club_id': clubId,
        'tenant_id': tenantId,
        'tenant_name': tenantName,
        'name': name,
        'venue_name': venueName,
        'venue_address': venueAddress,
        'venue_lat': venueLat,
        'venue_lng': venueLng,
        'roster': roster.map((p) => p.toJson()).toList(),
        'staff': staff.map((s) => s.toJson()).toList(),
      };
}

/// Club service contract.
abstract class ClubService {
  Future<Result<ClubProfile>> getClubProfile(String clubId);
}
