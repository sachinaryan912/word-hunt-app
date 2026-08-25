import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leaderboard_entry.dart';
import '../models/player_profile.dart';
import '../models/word_search_grid.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode: $message)';
}

class DailyGiftStatus {
  final bool freeClaimed;
  final bool adClaimed;
  const DailyGiftStatus({required this.freeClaimed, required this.adClaimed});

  factory DailyGiftStatus.fromJson(Map<String, dynamic> json) => DailyGiftStatus(
        freeClaimed: json['freeClaimed'] as bool? ?? false,
        adClaimed: json['adClaimed'] as bool? ?? false,
      );
}

class AvatarEntry {
  final String id;
  final int cost;
  final bool unlocked;
  const AvatarEntry({required this.id, required this.cost, required this.unlocked});

  factory AvatarEntry.fromJson(Map<String, dynamic> json) => AvatarEntry(
        id: json['id'] as String,
        cost: json['cost'] as int,
        unlocked: json['unlocked'] as bool? ?? false,
      );
}

class AvatarCatalog {
  final String? equipped;
  final List<AvatarEntry> avatars;
  const AvatarCatalog({required this.equipped, required this.avatars});

  factory AvatarCatalog.fromJson(Map<String, dynamic> json) => AvatarCatalog(
        equipped: json['equipped'] as String?,
        avatars: (json['avatars'] as List).map((e) => AvatarEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class LeaderboardResult {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry me;
  const LeaderboardResult({required this.entries, required this.me});
}

class SoloCompleteResult {
  final int score;
  final int accuracy;
  final PlayerProfile profile;
  const SoloCompleteResult({required this.score, required this.accuracy, required this.profile});
}

class DailyChallengeDto {
  final String date;
  final int puzzleNumber;
  final WordSearchGrid board;
  final int? timeLimitSeconds;
  final int? personalBest;
  final int? globalRankToday;
  final int totalParticipantsToday;

  const DailyChallengeDto({
    required this.date,
    required this.puzzleNumber,
    required this.board,
    required this.timeLimitSeconds,
    required this.personalBest,
    required this.globalRankToday,
    required this.totalParticipantsToday,
  });

  factory DailyChallengeDto.fromJson(Map<String, dynamic> json) {
    return DailyChallengeDto(
      date: json['date'] as String,
      puzzleNumber: json['puzzleNumber'] as int,
      board: WordSearchGrid.fromJson(json['board'] as Map<String, dynamic>),
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      personalBest: json['personalBest'] as int?,
      globalRankToday: json['globalRankToday'] as int?,
      totalParticipantsToday: json['totalParticipantsToday'] as int? ?? 0,
    );
  }
}

class DailyCompleteResult {
  final int score;
  final int bestScore;
  final int accuracy;
  final int rankToday;
  final int xpBonus;
  final PlayerProfile profile;
  const DailyCompleteResult({
    required this.score,
    required this.bestScore,
    required this.accuracy,
    required this.rankToday,
    required this.xpBonus,
    required this.profile,
  });
}

class FriendEntry {
  final String uid;
  final String displayName;
  final int rating;
  const FriendEntry({required this.uid, required this.displayName, required this.rating});

  factory FriendEntry.fromJson(Map<String, dynamic> json) => FriendEntry(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? 'Player',
        rating: json['rating'] as int? ?? 0,
      );
}

class FriendRequestEntry {
  final String id;
  final String fromUid;
  final String fromDisplayName;
  const FriendRequestEntry({required this.id, required this.fromUid, required this.fromDisplayName});

  factory FriendRequestEntry.fromJson(Map<String, dynamic> json) => FriendRequestEntry(
        id: json['id'] as String,
        fromUid: json['fromUid'] as String,
        fromDisplayName: json['fromDisplayName'] as String? ?? 'Player',
      );
}

class UserSearchResult {
  final String uid;
  final String displayName;
  final int rating;
  const UserSearchResult({required this.uid, required this.displayName, required this.rating});

  factory UserSearchResult.fromJson(Map<String, dynamic> json) => UserSearchResult(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? 'Player',
        rating: json['rating'] as int? ?? 0,
      );
}

class AppConfig {
  final int latestVersionCode;
  final int minSupportedVersionCode;
  final String updateUrl;
  const AppConfig({
    required this.latestVersionCode,
    required this.minSupportedVersionCode,
    required this.updateUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final android = json['android'] as Map<String, dynamic>;
    return AppConfig(
      latestVersionCode: android['latestVersionCode'] as int,
      minSupportedVersionCode: android['minSupportedVersionCode'] as int,
      updateUrl: android['updateUrl'] as String,
    );
  }
}

class AchievementDto {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  const AchievementDto({required this.id, required this.title, required this.description, required this.isUnlocked});

  factory AchievementDto.fromJson(Map<String, dynamic> json) => AchievementDto(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
      );
}

/// Thin REST wrapper around the Node backend. Every call attaches a fresh
/// Firebase ID token — the backend is the sole source of truth for profile,
/// leaderboard, and solo-completion data.
class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://word-hunt-backend-62164525100.us-central1.run.app',
  );

  final AuthService authService;
  ApiClient(this.authService);

  Future<Map<String, String>> _headers() async {
    final token = await authService.idToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    return _decode(res);
  }

  Future<dynamic> _post(String path, [Map<String, dynamic> body = const {}]) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> _delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers());
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// Unauthenticated — safe to call before sign-in (e.g. from the splash screen).
  Future<AppConfig> getAppConfig() async {
    final json = await _get('/v1/app-config') as Map<String, dynamic>;
    return AppConfig.fromJson(json);
  }

  Future<PlayerProfile> getMe() async {
    final json = await _get('/v1/me');
    return PlayerProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<PlayerProfile> patchMe({String? displayName}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    final json = await _patch('/v1/me', body);
    return PlayerProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateFcmToken(String token) async {
    await _patch('/v1/me', {'fcmToken': token});
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    await _patch('/v1/me', {'notificationsEnabled': enabled});
  }

  Future<LeaderboardResult> getLeaderboard({
    int limit = 100,
    String period = 'global',
    String scope = 'all',
  }) async {
    final json = await _get('/v1/leaderboards?limit=$limit&period=$period&scope=$scope') as Map<String, dynamic>;
    final entries = (json['entries'] as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final me = LeaderboardEntry.fromJson(json['me'] as Map<String, dynamic>);
    return LeaderboardResult(entries: entries, me: me);
  }

  Future<SoloCompleteResult> soloComplete({
    required int level,
    required int wordsFound,
    required int targetWordCount,
    required int timeSeconds,
    required int hintsUsed,
  }) async {
    final json = await _post('/v1/solo/complete', {
      'level': level,
      'wordsFound': wordsFound,
      'targetWordCount': targetWordCount,
      'timeSeconds': timeSeconds,
      'hintsUsed': hintsUsed,
    }) as Map<String, dynamic>;
    return SoloCompleteResult(
      score: json['score'] as int,
      accuracy: json['accuracy'] as int,
      profile: PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> getMatch(String matchId) async {
    final json = await _get('/v1/matches/$matchId');
    return json as Map<String, dynamic>;
  }

  Future<DailyChallengeDto> getDailyChallenge() async {
    final json = await _get('/v1/daily-challenge') as Map<String, dynamic>;
    return DailyChallengeDto.fromJson(json);
  }

  Future<DailyCompleteResult> completeDailyChallenge({
    required int wordsFound,
    required int timeSeconds,
    required int hintsUsed,
  }) async {
    final json = await _post('/v1/daily-challenge/complete', {
      'wordsFound': wordsFound,
      'timeSeconds': timeSeconds,
      'hintsUsed': hintsUsed,
    }) as Map<String, dynamic>;
    return DailyCompleteResult(
      score: json['score'] as int,
      bestScore: json['bestScore'] as int,
      accuracy: json['accuracy'] as int,
      rankToday: json['rankToday'] as int? ?? 0,
      xpBonus: json['xpBonus'] as int? ?? 0,
      profile: PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }

  Future<List<AchievementDto>> getAchievements() async {
    final json = await _get('/v1/achievements') as Map<String, dynamic>;
    return (json['achievements'] as List).map((e) => AchievementDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    final json = await _get('/v1/users/search?q=${Uri.encodeQueryComponent(query)}') as Map<String, dynamic>;
    return (json['users'] as List).map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FriendEntry>> getFriends() async {
    final json = await _get('/v1/friends') as Map<String, dynamic>;
    return (json['friends'] as List).map((e) => FriendEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FriendRequestEntry>> getFriendRequests() async {
    final json = await _get('/v1/friends/requests') as Map<String, dynamic>;
    return (json['requests'] as List).map((e) => FriendRequestEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendFriendRequest(String toUid) async {
    await _post('/v1/friends/requests', {'toUid': toUid});
  }

  Future<void> acceptFriendRequest(String id) async {
    await _post('/v1/friends/requests/$id/accept');
  }

  Future<void> declineFriendRequest(String id) async {
    await _post('/v1/friends/requests/$id/decline');
  }

  Future<void> removeFriend(String uid) async {
    await _delete('/v1/friends/$uid');
  }

  Future<void> reportPlayer({required String targetUid, required String reason, String? matchId}) async {
    await _post('/v1/reports', {
      'targetUid': targetUid,
      'reason': reason,
      if (matchId != null) 'matchId': matchId,
    });
  }

  Future<void> blockUser(String targetUid) async {
    await _post('/v1/blocks', {'targetUid': targetUid});
  }

  Future<void> unblockUser(String targetUid) async {
    await _delete('/v1/blocks/$targetUid');
  }

  Future<int> claimAdReward() async {
    final json = await _post('/v1/ads/reward') as Map<String, dynamic>;
    return json['xpAwarded'] as int;
  }

  Future<DailyGiftStatus> getDailyGiftStatus() async {
    final json = await _get('/v1/daily-gift/status') as Map<String, dynamic>;
    return DailyGiftStatus.fromJson(json);
  }

  Future<int> claimDailyGiftFree() async {
    final json = await _post('/v1/daily-gift/claim-free') as Map<String, dynamic>;
    return json['xpAwarded'] as int;
  }

  Future<int> claimDailyGiftAd() async {
    final json = await _post('/v1/daily-gift/claim-ad') as Map<String, dynamic>;
    return json['xpAwarded'] as int;
  }

  Future<AvatarCatalog> getAvatars() async {
    final json = await _get('/v1/avatars') as Map<String, dynamic>;
    return AvatarCatalog.fromJson(json);
  }

  Future<PlayerProfile> unlockAvatar(String id) async {
    final json = await _post('/v1/avatars/$id/unlock') as Map<String, dynamic>;
    return PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>);
  }

  Future<PlayerProfile> equipAvatar(String id) async {
    final json = await _post('/v1/avatars/$id/equip') as Map<String, dynamic>;
    return PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>);
  }
}
