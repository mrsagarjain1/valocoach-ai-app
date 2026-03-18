import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) throw Exception('CacheService not initialized. Call init() first.');
    return _prefs!;
  }

  // ─── Generic Cache ────────────────────────────────────

  Future<void> saveJson(String key, Map<String, dynamic> data) async {
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _p.setString(key, jsonEncode(cacheEntry));
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = _p.getString(key);
    if (raw == null) return null;

    try {
      final cacheEntry = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > ApiConfig.cacheTtl.inMilliseconds) {
        _p.remove(key);
        return null; // Expired
      }

      return cacheEntry['data'] as Map<String, dynamic>;
    } catch (e) {
      _p.remove(key);
      return null;
    }
  }

  Future<void> remove(String key) async {
    await _p.remove(key);
  }

  Future<void> clearAll() async {
    await _p.clear();
  }

  // ─── Convenience Keys ─────────────────────────────────

  static const String playerStatsKey = 'player_stats';
  static const String aiAnalysisKey = 'ai_analysis';
  static const String questsKey = 'quests';
  static const String battlepassKey = 'battlepass';
  static const String riotAuthKey = 'riot_auth';

  // ─── Riot Auth Cache ──────────────────────────────────

  Future<void> saveRiotAuth({
    required String puuid,
    required String token,
    String? name,
    String? tag,
  }) async {
    await saveJson(riotAuthKey, {
      'puuid': puuid,
      'token': token,
      'name': name,
      'tag': tag,
      'linked_at': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? getRiotAuth() {
    return getJson(riotAuthKey);
  }

  Future<void> clearRiotAuth() async {
    await remove(riotAuthKey);
  }
}
