import 'package:flutter/foundation.dart';
import '../models/match_state.dart';
import '../models/word_search_grid.dart';
import '../services/socket_service.dart';

enum MatchmakingStatus { idle, searching, found, active, ended }

class MatchEndInfo {
  final String? winnerId;
  final int myScore;
  final int opponentScore;
  final int myRatingDelta;
  final int myNewRating;
  final bool isWin;

  const MatchEndInfo({
    required this.winnerId,
    required this.myScore,
    required this.opponentScore,
    required this.myRatingDelta,
    required this.myNewRating,
    required this.isWin,
  });
}

/// Live multiplayer state, fed entirely by authoritative Socket.IO events.
/// The client never computes scores, winners, or the board itself — it only
/// renders what the server broadcasts.
class MatchProvider extends ChangeNotifier {
  final SocketService socketService;
  MatchProvider(this.socketService);

  MatchmakingStatus status = MatchmakingStatus.idle;
  String? matchId;
  String? myUid;
  MultiplayerMatchState? state;
  int startAt = 0;
  int endAt = 0;
  int durationSeconds = 90;
  bool opponentConnected = true;
  MatchEndInfo? endInfo;

  bool _listening = false;

  void startListening(String uid) {
    myUid = uid;
    if (_listening) return;
    _listening = true;
    socketService.on('matchmaking:queued', _onQueued);
    socketService.on('match:found', _onFound);
    socketService.on('match:start', _onStart);
    socketService.on('match:state', _onState);
    socketService.on('word:claimed', _onWordClaimed);
    socketService.on('player:disconnected', _onOpponentDisconnected);
    socketService.on('player:reconnected', _onOpponentReconnected);
    socketService.on('match:end', _onMatchEnd);
  }

  void reset() {
    status = MatchmakingStatus.idle;
    matchId = null;
    state = null;
    endInfo = null;
    opponentConnected = true;
    notifyListeners();
  }

  void joinMatchmaking() {
    reset();
    status = MatchmakingStatus.searching;
    notifyListeners();
    socketService.joinMatchmaking();
  }

  void cancelMatchmaking() {
    socketService.cancelMatchmaking();
    status = MatchmakingStatus.idle;
    notifyListeners();
  }

  void selectWord(List<GridPos> path) {
    final id = matchId;
    if (id == null) return;
    socketService.sendWordSelect(id, path.map((p) => {'row': p.row, 'col': p.col}).toList());
  }

  void rejoin(String id) {
    matchId = id;
    socketService.rejoinMatch(id);
  }

  Map<String, dynamic> _asMap(dynamic data) => Map<String, dynamic>.from(data as Map);

  WordSearchGrid _gridFromBoard(Map<String, dynamic> board, {List<FoundWordPath> foundWords = const []}) {
    return WordSearchGrid(
      rows: board['rows'] as int,
      cols: board['cols'] as int,
      grid: (board['grid'] as List).map((row) => (row as List).map((c) => c as String).toList()).toList(),
      targetWords: (board['targetWords'] as List).map((w) => w as String).toList(),
      foundWords: foundWords,
    );
  }

  void _onQueued(dynamic data) {
    status = MatchmakingStatus.searching;
    notifyListeners();
  }

  void _onFound(dynamic data) {
    status = MatchmakingStatus.found;
    notifyListeners();
  }

  void _onStart(dynamic data) {
    final json = _asMap(data);
    matchId = json['matchId'] as String;
    final board = _asMap(json['board']);
    final you = _asMap(json['you']);
    final opponent = _asMap(json['opponent']);

    state = MultiplayerMatchState(
      matchId: matchId!,
      player: MatchPlayer(
        id: you['uid'] as String,
        name: you['displayName'] as String,
        score: 0,
        rating: you['rating'] as int,
      ),
      opponent: MatchPlayer(
        id: opponent['uid'] as String,
        name: opponent['displayName'] as String,
        score: 0,
        rating: opponent['rating'] as int,
      ),
      grid: _gridFromBoard(board),
      recentFeed: const [],
      chatMessages: const [],
    );
    startAt = json['startAt'] as int;
    endAt = json['endAt'] as int;
    durationSeconds = json['durationSeconds'] as int;
    opponentConnected = true;
    status = MatchmakingStatus.active;
    notifyListeners();
  }

  void _onState(dynamic data) {
    if (state == null) return;
    final json = _asMap(data);
    final board = _asMap(json['board']);
    final claimed = (json['claimedWords'] as List).map((e) => _asMap(e));
    final foundWords = claimed.map((c) {
      final path =
          (c['path'] as List).map((p) => GridPos(_asMap(p)['row'] as int, _asMap(p)['col'] as int)).toList();
      final claimedBy = c['claimedBy'] as String;
      return FoundWordPath(word: c['word'] as String, path: path, claimedBy: claimedBy == myUid ? 'player' : 'opponent');
    }).toList();

    final scores = _asMap(json['scores']);
    state = state!.copyWith(
      grid: _gridFromBoard(board, foundWords: foundWords),
      player: state!.player.copyWith(score: scores[state!.player.id] as int? ?? state!.player.score),
      opponent: state!.opponent.copyWith(score: scores[state!.opponent.id] as int? ?? state!.opponent.score),
    );
    startAt = json['startAt'] as int;
    endAt = json['endAt'] as int;
    durationSeconds = json['durationSeconds'] as int;
    opponentConnected = json['opponentConnected'] as bool? ?? true;
    notifyListeners();
  }

  void _onWordClaimed(dynamic data) {
    if (state == null) return;
    final json = _asMap(data);
    final word = json['word'] as String;
    final claimedByUid = json['claimedBy'] as String;
    final path = (json['path'] as List).map((p) => GridPos(_asMap(p)['row'] as int, _asMap(p)['col'] as int)).toList();
    final scores = _asMap(json['scores']);

    final isMe = claimedByUid == myUid;
    final updatedFound = List<FoundWordPath>.from(state!.grid.foundWords)
      ..add(FoundWordPath(word: word, path: path, claimedBy: isMe ? 'player' : 'opponent'));
    final claimantName = isMe ? state!.player.name : state!.opponent.name;

    state = state!.copyWith(
      grid: state!.grid.copyWith(foundWords: updatedFound),
      player: state!.player.copyWith(score: scores[state!.player.id] as int? ?? state!.player.score),
      opponent: state!.opponent.copyWith(score: scores[state!.opponent.id] as int? ?? state!.opponent.score),
      recentFeed: ['$claimantName found $word (+${json['score']})', ...state!.recentFeed],
    );
    notifyListeners();
  }

  void _onOpponentDisconnected(dynamic data) {
    opponentConnected = false;
    notifyListeners();
  }

  void _onOpponentReconnected(dynamic data) {
    opponentConnected = true;
    notifyListeners();
  }

  void _onMatchEnd(dynamic data) {
    final uid = myUid;
    if (uid == null) return;
    final json = _asMap(data);
    final winnerId = json['winnerId'] as String?;
    final scores = _asMap(json['scores']);
    final deltas = _asMap(json['ratingDeltas']);
    final newRatings = _asMap(json['newRatings']);
    final opponentId = state?.opponent.id;

    endInfo = MatchEndInfo(
      winnerId: winnerId,
      myScore: scores[uid] as int? ?? 0,
      opponentScore: opponentId != null ? (scores[opponentId] as int? ?? 0) : 0,
      myRatingDelta: deltas[uid] as int? ?? 0,
      myNewRating: newRatings[uid] as int? ?? (state?.player.rating ?? 0),
      isWin: winnerId == uid,
    );
    status = MatchmakingStatus.ended;
    notifyListeners();
  }
}
