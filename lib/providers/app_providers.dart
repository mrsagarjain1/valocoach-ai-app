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
  final String? riotName;
  final String? riotTag;
  final bool isPremium;
  final int? daysRemaining;
  final DateTime? subscriptionEnd;
  final bool isSyncing; // true while checkUserAuth / premium sync is in flight

  const AuthState({
    this.isClerkSignedIn = false,
    this.clerkUserId,
    this.isRiotLinked = false,
    this.riotPuuid,
    this.riotToken,
    this.riotName,
    this.riotTag,
    this.isPremium = false,
    this.daysRemaining,
    this.subscriptionEnd,
    this.isSyncing = false,
  });

  AuthState copyWith({
    bool? isClerkSignedIn,
    String? clerkUserId,
    bool? isRiotLinked,
    String? riotPuuid,
    String? riotToken,
    String? riotName,
    String? riotTag,
    bool? isPremium,
    int? daysRemaining,
    DateTime? subscriptionEnd,
    bool? isSyncing,
  }) {
    return AuthState(
      isClerkSignedIn: isClerkSignedIn ?? this.isClerkSignedIn,
      clerkUserId: clerkUserId ?? this.clerkUserId,
      isRiotLinked: isRiotLinked ?? this.isRiotLinked,
      riotPuuid: riotPuuid ?? this.riotPuuid,
      riotToken: riotToken ?? this.riotToken,
      riotName: riotName ?? this.riotName,
      riotTag: riotTag ?? this.riotTag,
      isPremium: isPremium ?? this.isPremium,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      isSyncing: isSyncing ?? this.isSyncing,
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
        riotName: cached['name'],
        riotTag: cached['tag'],
      );
    }
  }

  /// Called by _AuthBridge in main.dart when Clerk reports a signed-in user.
  /// Syncs the Clerk user ID to both the ApiService interceptor (which auto-
  /// attaches it as X-Clerk-User-Id header) and the local Riverpod state, then
  /// fires the full backend sync in the background.
  void setClerkUser(String userId) {
    _api.setClerkUserId(userId);
    state = state.copyWith(
      isClerkSignedIn: true,
      clerkUserId: userId,
      isSyncing: true,
    );
    _onboardAndSync(userId);
  }

  /// 1. Call check-user-auth to fetch Riot linkage + premium status.
  /// 2. Sync premium status.
  Future<void> _onboardAndSync(String clerkId) async {

    // Check auth & riot linkage
    try {
      final res = await _api.checkUserAuth(clerkId);
      final isLinked = res['exists'] == true || 
                       res['player_puuid'] != null || 
                       res['riot_puuid'] != null ||
                       res['puuid'] != null;
      
      final puuid = res['player_puuid']?.toString() ?? 
                    res['riot_puuid']?.toString() ?? 
                    res['puuid']?.toString();
      
      final token = res['riot_token']?.toString() ?? res['token']?.toString();
      final name = res['riot_name']?.toString() ?? res['name']?.toString();
      final tag = res['riot_tag']?.toString() ?? res['tag']?.toString();
      final isPrem = (res['is_premium'] == true || res['premium'] == true);

      state = state.copyWith(
        isRiotLinked: isLinked,
        riotPuuid: puuid ?? state.riotPuuid,
        riotToken: token ?? state.riotToken,
        riotName: name ?? state.riotName,
        riotTag: tag ?? state.riotTag,
        isPremium: isPrem,
        daysRemaining: res['days_remaining'] != null ? int.tryParse(res['days_remaining'].toString()) : null,
        subscriptionEnd: res['subscription_end'] != null ? DateTime.tryParse(res['subscription_end'].toString()) : null,
      );

      // Persist the backend-provided auth data to local cache for session stability
      if (isLinked && puuid != null) {
        await _cache.saveRiotAuth(
          puuid: puuid,
          token: token ?? state.riotToken ?? '',
          name: name ?? state.riotName,
          tag: tag ?? state.riotTag,
        );
      }
    } catch (e) {
      debugPrint('[Auth] checkUserAuth failed: $e');
    }

    // Dedicated premium sync
    await refreshPremium();

    state = state.copyWith(isSyncing: false);
  }

  Future<void> linkRiot({
    required String puuid,
    required String token,
    String? name,
    String? tag,
  }) async {
    if (state.clerkUserId == null) return;

    try {
      // 1. Tell backend to link it permanently (via onboarding) if not already linked
      final status = await _api.checkUserAuth(state.clerkUserId!);
      if (status['exists'] != true) {
        await _api.onboardUser(
          clerkId: state.clerkUserId!,
          puuid: puuid,
          token: token,
          region: 'ap', // Default to Asia Pacific
        );
      }

      // 2. Persist locally
      await _cache.saveRiotAuth(
        puuid: puuid,
        token: token,
        name: name,
        tag: tag,
      );

      // 3. Update state
      state = state.copyWith(
        isRiotLinked: true,
        riotPuuid: puuid,
        riotToken: token,
        riotName: name,
        riotTag: tag,
      );
    } catch (e) {
      debugPrint('[Auth] linkRiot failed: $e');
      rethrow;
    }
  }

  void clearClerkUser() {
    _api.setClerkUserId(null);
    state = state.copyWith(
      isClerkSignedIn: false,
      clerkUserId: null,
      isSyncing: false,
    );
  }

  Future<void> linkRiotAccount(String puuid, String token, {String? name, String? tag}) async {
    await _cache.saveRiotAuth(puuid: puuid, token: token, name: name, tag: tag);
    state = state.copyWith(
      isRiotLinked: true,
      riotPuuid: puuid,
      riotToken: token,
      riotName: name,
      riotTag: tag,
    );
  }

  /// Re-fetches premium status from backend.  Call this after a successful
  /// Razorpay payment to immediately reflect the new status.
  Future<void> refreshPremium() async {
    final clerkId = state.clerkUserId;
    if (clerkId == null) return;
    try {
      final res = await _api.syncPremiumStatus(clerkId);
      final isPrem = (res['is_premium'] == true || res['premium'] == true);
      state = state.copyWith(
        isPremium: isPrem,
        daysRemaining: res['days_remaining'] != null ? int.tryParse(res['days_remaining'].toString()) : null,
        subscriptionEnd: res['subscription_end'] != null ? DateTime.tryParse(res['subscription_end'].toString()) : null,
      );
    } catch (e) {
      debugPrint('[Auth] refreshPremium failed: $e');
    }
  }

  Future<void> unlinkRiot() async {
    await _cache.clearRiotAuth();
    state = state.copyWith(
      isRiotLinked: false,
      riotPuuid: null,
      riotToken: null,
      riotName: null,
      riotTag: null,
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

// ─── Per-Match AI Analysis State ────────────────────────
class PerMatchAnalysisState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const PerMatchAnalysisState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  PerMatchAnalysisState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return PerMatchAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class PerMatchAnalysisNotifier extends StateNotifier<PerMatchAnalysisState> {
  final ApiService _api;
  final CacheService _cache;
  final String matchId;

  PerMatchAnalysisNotifier(this._api, this._cache, this.matchId) : super(const PerMatchAnalysisState());

  Future<void> fetchAnalysis() async {
    final cacheKey = 'match_analysis_$matchId';
    
    // 1. Check Cache
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      state = state.copyWith(data: cached, isLoading: false, error: null);
      return;
    }

    // 2. Fetch from API
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getMatchAnalysis(matchId);
      
      // 3. Save to Cache
      await _cache.saveJson(cacheKey, res);
      
      state = state.copyWith(isLoading: false, data: res);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final perMatchAnalysisProvider = StateNotifierProvider.family<PerMatchAnalysisNotifier, PerMatchAnalysisState, String>((ref, matchId) {
  return PerMatchAnalysisNotifier(
    ref.watch(apiServiceProvider), 
    ref.watch(cacheServiceProvider),
    matchId,
  );
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
  final int totalPlayers;

  const BattlepassState({
    this.isLoading = false,
    this.error,
    this.battlepass,
    this.dailyQuests = const [],
    this.weeklyQuests = const [],
    this.seasonalQuests = const [],
    this.leaderboard = const [],
    this.totalPlayers = 0,
  });

  BattlepassState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? battlepass,
    List<dynamic>? dailyQuests,
    List<dynamic>? weeklyQuests,
    List<dynamic>? seasonalQuests,
    List<dynamic>? leaderboard,
    int? totalPlayers,
  }) {
    return BattlepassState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      battlepass: battlepass ?? this.battlepass,
      dailyQuests: dailyQuests ?? this.dailyQuests,
      weeklyQuests: weeklyQuests ?? this.weeklyQuests,
      seasonalQuests: seasonalQuests ?? this.seasonalQuests,
      leaderboard: leaderboard ?? this.leaderboard,
      totalPlayers: totalPlayers ?? this.totalPlayers,
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
      final leaderboard = lbData['leaderboard'] as List? ?? [];
      final totalPlayers = lbData['total_players'] as int? ?? leaderboard.length;

      state = state.copyWith(
        isLoading: false,
        battlepass: bpData,
        dailyQuests: quests.where((q) => q['quest_type'] == 'daily').toList(),
        weeklyQuests: quests.where((q) => q['quest_type'] == 'weekly').toList(),
        seasonalQuests: quests.where((q) => q['quest_type'] == 'seasonal').toList(),
        leaderboard: leaderboard,
        totalPlayers: totalPlayers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final battlepassProvider = StateNotifierProvider<BattlepassNotifier, BattlepassState>((ref) {
  return BattlepassNotifier(ref.watch(apiServiceProvider), ref);
});
