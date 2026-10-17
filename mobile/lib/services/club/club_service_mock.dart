import '../../core/utils/result.dart';
import '../cache/cache_service.dart';
import 'club_service.dart';

/// Mock ClubService with local cache.
class ClubServiceMock implements ClubService {
  ClubServiceMock({required this.cacheService});

  final CacheService cacheService;

  static final ClubProfile _mockClub = ClubProfile(
    clubId: 'club-alpha-1',
    tenantId: 'tenant-alpha',
    name: 'Alpha FC',
    venueName: 'A-01 Main Arena (Islamabad)',
    venueLat: 33.6844,
    venueLng: 73.0479,
    staff: const [
      StaffMember(name: 'Farhan Zaidi', role: 'Head Coach'),
      StaffMember(name: 'Shafiq Ahmad', role: 'Club Manager'),
      StaffMember(name: 'Dr. Bilal Qureshi', role: 'Physiotherapist'),
    ],
    roster: const [
      Player(
        playerId: 'player-alpha-1',
        name: 'Tariq Al-Mansoor',
        position: 'Forward / Striker',
        role: 'Captain',
        jerseyNumber: 9,
      ),
      Player(
        playerId: 'player-alpha-2',
        name: 'Hamza Malik',
        position: 'Midfielder',
        role: 'Vice Captain',
        jerseyNumber: 8,
      ),
      Player(
        playerId: 'player-alpha-3',
        name: 'Zeeshan Arshad',
        position: 'Defender (Centre Back)',
        role: 'Player',
        jerseyNumber: 4,
      ),
      Player(
        playerId: 'player-alpha-4',
        name: 'Danyal Khan',
        position: 'Goalkeeper',
        role: 'Player',
        jerseyNumber: 1,
      ),
      Player(
        playerId: 'player-alpha-5',
        name: 'Usman Ghani',
        position: 'Winger',
        role: 'Player',
        jerseyNumber: 11,
      ),
    ],
  );

  @override
  Future<Result<ClubProfile>> getClubProfile(String clubId) async {
    final cacheKey = 'cache_club_profile_$clubId';

    // 1. Try cache
    try {
      final cachedRes = await cacheService.get(cacheKey);
      final cached = cachedRes.dataOrNull;
      if (cached != null) {
        return Success(ClubProfile.fromJson(cached));
      }
    } catch (_) {}

    // 2. Fallback to mock and save to cache
    await cacheService.put(cacheKey, _mockClub.toJson());
    return Success(_mockClub);
  }
}
