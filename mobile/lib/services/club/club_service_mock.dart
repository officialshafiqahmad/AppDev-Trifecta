import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import 'club_service.dart';

/// Mock ClubService with local cache and mutable in-memory roster.
class ClubServiceMock implements ClubService {
  ClubServiceMock({required this.cacheService});

  final CacheService cacheService;

  static final List<Player> _canonicalRoster = [
    const Player(
      playerId: 'player-alpha-1',
      name: 'Marcus Rashford',
      position: 'Forward / Striker',
      role: 'Captain',
      jerseyNumber: 10,
      squadId: 'squad-alpha-1',
    ),
    const Player(
      playerId: 'player-alpha-2',
      name: 'Bruno Fernandes',
      position: 'Midfielder',
      role: 'Vice Captain',
      jerseyNumber: 8,
      squadId: 'squad-alpha-1',
    ),
    const Player(
      playerId: 'player-alpha-3',
      name: 'Rasmus Hojlund',
      position: 'Forward / Striker',
      role: 'Player',
      jerseyNumber: 9,
      squadId: 'squad-alpha-1',
    ),
    const Player(
      playerId: 'player-alpha-4',
      name: 'Lisandro Martinez',
      position: 'Defender (Centre Back)',
      role: 'Player',
      jerseyNumber: 6,
      squadId: 'squad-alpha-1',
    ),
    const Player(
      playerId: 'player-alpha-5',
      name: 'Andre Onana',
      position: 'Goalkeeper',
      role: 'Player',
      jerseyNumber: 1,
      squadId: 'squad-alpha-1',
    ),
  ];

  static final List<StaffMember> _canonicalStaff = [
    const StaffMember(name: 'Erik ten Hag', role: 'Head Coach'),
    const StaffMember(name: 'Shafiq Ahmad', role: 'Club Operations Manager'),
    const StaffMember(name: 'Dr. Bilal Qureshi', role: 'Physiotherapist'),
  ];

  void addPlayerLocally(Player player) {
    _canonicalRoster.add(player);
  }

  @override
  Future<Result<ClubProfile>> getClubProfile(String clubId) async {
    final profile = ClubProfile(
      clubId: clubId,
      tenantId: 'tenant-alpha',
      tenantName: 'Punjab FA / Lahore District League',
      name: 'Lahore FC',
      venueName: 'A-01 Main Arena',
      venueAddress: 'Lahore',
      venueLat: 31.5204,
      venueLng: 74.3587,
      staff: _canonicalStaff,
      roster: List.unmodifiable(_canonicalRoster),
    );

    return Success(profile);
  }
}
