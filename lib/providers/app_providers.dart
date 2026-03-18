import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

// ─── Service Providers ──────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

// ─── Auth State ─────────────────────────────────────────
class AuthState {
  final bool isClerkSignedIn;
  final String? clerkUserId;
  final bool isRiotLinked;
  final String? riotPuuid;
  final String? riotToken;
  final bool isPremium;

  const AuthState({
    this.isClerkSignedIn = false,
    this.clerkUserId,
    this.isRiotLinked = false,
    this.riotPuuid,
    this.riotToken,
    this.isPremium = false,
  });

  AuthState copyWith({
    bool? isClerkSignedIn,
    String? clerkUserId,
    bool? isRiotLinked,
    String? riotPuuid,
    String? riotToken,
    bool? isPremium,
  }) {
    return AuthState(
      isClerkSignedIn: isClerkSignedIn ?? this.isClerkSignedIn,
      clerkUserId: clerkUserId ?? this.clerkUserId,
      isRiotLinked: isRiotLinked ?? this.isRiotLinked,
      riotPuuid: riotPuuid ?? this.riotPuuid,
      riotToken: riotToken ?? this.riotToken,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final CacheService _cache;

  AuthNotifier(this._api, this._cache) : super(const AuthState()) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = _cache.getRiotAuth();
    if (cached != null) {
      state = state.copyWith(
        isRiotLinked: true,
        riotPuuid: cached['puuid'],
        riotToken: cached['token'],
      );
    }
  }

  void setClerkUser(String userId) {
    _api.setClerkUserId(userId);
    state = state.copyWith(isClerkSignedIn: true, clerkUserId: userId);
    _syncAuthData(userId);
  }

  Future<void> _syncAuthData(String clerkId) async {
    try {
      final res = await _api.checkUserAuth(clerkId);
      final isLinked = res['is_linked'] == true || res['puuid'] != null || res['riot_puuid'] != null;
      final puuid = res['puuid']?.toString() ?? res['riot_puuid']?.toString();
      final name = res['name']?.toString() ?? res['riot_name']?.toString();
      final tag = res['tag']?.toString() ?? res['riot_tag']?.toString();
      
      state = state.copyWith(
        isRiotLinked: isLinked || state.isRiotLinked,
        riotPuuid: puuid ?? state.riotPuuid,
      );

      if (isLinked && puuid != null) {
        // Just save what we know
        await _cache.saveRiotAuth(
          puuid: puuid, 
          token: state.riotToken ?? '',
          name: name,
          tag: tag,
        );
      }
    } catch (e) {
      debugPrint('Failed to sync riot auth: $e');
    }
    
    // Also sync premium status
    await checkPremiumStatus(clerkId);
  }

  void clearClerkUser() {
    _api.setClerkUserId(null);
    state = state.copyWith(isClerkSignedIn: false, clerkUserId: null);
  }

  Future<void> linkRiotAccount(String puuid, String token) async {
    await _cache.saveRiotAuth(puuid: puuid, token: token);
    state = state.copyWith(
      isRiotLinked: true,
      riotPuuid: puuid,
      riotToken: token,
    );
  }

  Future<void> checkPremiumStatus(String clerkId) async {
    try {
      final res = await _api.syncPremiumStatus(clerkId);
      final isPrem = res['is_premium'] == true;
      state = state.copyWith(isPremium: isPrem);
    } catch (e) {
      debugPrint('Failed to sync premium: $e');
    }
  }

  Future<void> unlinkRiot() async {
    await _cache.clearRiotAuth();
    state = state.copyWith(
      isRiotLinked: false,
      riotPuuid: null,
      riotToken: null,
    );
  }

  void signOut() {
    _api.setClerkUserId(null);
    _cache.clearAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(cacheServiceProvider),
  );
});

// ─── Player Stats State ─────────────────────────────────
class PlayerStatsState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final String? searchedName;
  final String? searchedTag;

  const PlayerStatsState({
    this.isLoading = false,
    this.data,
    this.error,
    this.searchedName,
    this.searchedTag,
  });

  PlayerStatsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    String? searchedName,
    String? searchedTag,
  }) {
    return PlayerStatsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
      searchedName: searchedName ?? this.searchedName,
      searchedTag: searchedTag ?? this.searchedTag,
    );
  }
}

class PlayerStatsNotifier extends StateNotifier<PlayerStatsState> {
  final ApiService _api;
  final CacheService _cache;

  PlayerStatsNotifier(this._api, this._cache) : super(const PlayerStatsState());

  Future<void> searchPlayer(String name, String tag, {String region = 'ap'}) async {
    state = PlayerStatsState(
      isLoading: true,
      searchedName: name,
      searchedTag: tag,
    );

    // Check cache first
    final cacheKey = '${CacheService.playerStatsKey}_${name}_${tag}_$region';
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      state = state.copyWith(isLoading: false, data: cached);
      return;
    }

    try {
      final data = await _api.getPlayerStats(name: name, tag: tag, region: region);
      await _cache.saveJson(cacheKey, data);
      state = state.copyWith(isLoading: false, data: data);
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.response?.data?['details'] ?? e.message ?? 'Network error';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const PlayerStatsState();
  }
}

final playerStatsProvider =
    StateNotifierProvider<PlayerStatsNotifier, PlayerStatsState>((ref) {
  return PlayerStatsNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(cacheServiceProvider),
  );
});

// ─── Bottom Nav Index ───────────────────────────────────
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ─── Player Analysis State ──────────────────────────────
class PlayerAnalysisState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const PlayerAnalysisState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  PlayerAnalysisState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return PlayerAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class PlayerAnalysisNotifier extends StateNotifier<PlayerAnalysisState> {
  final ApiService _api;

  PlayerAnalysisNotifier(this._api) : super(const PlayerAnalysisState());

  Future<void> fetchAnalysis({
    required String name,
    required String tag,
    String region = 'ap',
    String mode = 'competitive',
    String platform = 'pc',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getPlayerAnalysis(
        name: name,
        tag: tag,
        region: region,
        mode: mode,
        platform: platform,
      );
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const PlayerAnalysisState();
  }
}

final playerAnalysisProvider = StateNotifierProvider<PlayerAnalysisNotifier, PlayerAnalysisState>((ref) {
  return PlayerAnalysisNotifier(ref.watch(apiServiceProvider));
});

// ─── Match Analysis State ───────────────────────────────
class MatchAnalysisState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const MatchAnalysisState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  MatchAnalysisState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return MatchAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class MatchAnalysisNotifier extends StateNotifier<MatchAnalysisState> {
  final ApiService _api;

  MatchAnalysisNotifier(this._api) : super(const MatchAnalysisState());

  Future<void> fetchMatchAnalysis() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.updatePlayerDataQuests();
      state = state.copyWith(isLoading: false, data: data, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearCache() {
    state = const MatchAnalysisState();
  }
}

final matchAnalysisProvider = StateNotifierProvider<MatchAnalysisNotifier, MatchAnalysisState>((ref) {
  return MatchAnalysisNotifier(ref.watch(apiServiceProvider));
});

// ─── Battlepass State ────────────────────────────────────────────────────────

class BattlepassState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? battlepass;
  final List<dynamic> dailyQuests;
  final List<dynamic> weeklyQuests;
  final List<dynamic> seasonalQuests;
  final List<dynamic> leaderboard;

  const BattlepassState({
    this.isLoading = false,
    this.error,
    this.battlepass,
    this.dailyQuests = const [],
    this.weeklyQuests = const [],
    this.seasonalQuests = const [],
    this.leaderboard = const [],
  });

  BattlepassState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? battlepass,
    List<dynamic>? dailyQuests,
    List<dynamic>? weeklyQuests,
    List<dynamic>? seasonalQuests,
    List<dynamic>? leaderboard,
  }) {
    return BattlepassState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      battlepass: battlepass ?? this.battlepass,
      dailyQuests: dailyQuests ?? this.dailyQuests,
      weeklyQuests: weeklyQuests ?? this.weeklyQuests,
      seasonalQuests: seasonalQuests ?? this.seasonalQuests,
      leaderboard: leaderboard ?? this.leaderboard,
    );
  }
}

class BattlepassNotifier extends StateNotifier<BattlepassState> {
  final ApiService _api;
  final Ref _ref;

  BattlepassNotifier(this._api, this._ref) : super(const BattlepassState());

  Future<void> fetchAll() async {
    final auth = _ref.read(authProvider);
    if (auth.clerkUserId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final clerkId = auth.clerkUserId!;
      
      final results = await Future.wait([
        _api.getBattlepass(clerkId),
        _api.getQuests(clerkId),
        _api.getBattlepassLeaderboard(),
      ]);

      final bpData = results[0];
      final questsData = results[1];
      final lbData = results[2];

      final quests = questsData['quests'] as List? ?? [];
      
      state = state.copyWith(
        isLoading: false,
        battlepass: bpData,
        dailyQuests: quests.where((q) => q['quest_type'] == 'daily').toList(),
        weeklyQuests: quests.where((q) => q['quest_type'] == 'weekly').toList(),
        seasonalQuests: quests.where((q) => q['quest_type'] == 'seasonal').toList(),
        leaderboard: lbData['leaderboard'] as List? ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final battlepassProvider = StateNotifierProvider<BattlepassNotifier, BattlepassState>((ref) {
  return BattlepassNotifier(ref.watch(apiServiceProvider), ref);
});
