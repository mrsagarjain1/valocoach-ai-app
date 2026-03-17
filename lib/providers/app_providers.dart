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

  const AuthState({
    this.isClerkSignedIn = false,
    this.clerkUserId,
    this.isRiotLinked = false,
    this.riotPuuid,
    this.riotToken,
  });

  AuthState copyWith({
    bool? isClerkSignedIn,
    String? clerkUserId,
    bool? isRiotLinked,
    String? riotPuuid,
    String? riotToken,
  }) {
    return AuthState(
      isClerkSignedIn: isClerkSignedIn ?? this.isClerkSignedIn,
      clerkUserId: clerkUserId ?? this.clerkUserId,
      isRiotLinked: isRiotLinked ?? this.isRiotLinked,
      riotPuuid: riotPuuid ?? this.riotPuuid,
      riotToken: riotToken ?? this.riotToken,
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
  }

  Future<void> linkRiotAccount(String puuid, String token) async {
    await _cache.saveRiotAuth(puuid: puuid, token: token);
    state = state.copyWith(
      isRiotLinked: true,
      riotPuuid: puuid,
      riotToken: token,
    );
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
