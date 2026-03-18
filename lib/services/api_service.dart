import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  String? _clerkUserId;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.backendUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 240),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ApiConfig.apiKey,
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_clerkUserId != null) {
          options.headers['X-Clerk-User-Id'] = _clerkUserId;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  void setClerkUserId(String? userId) {
    _clerkUserId = userId;
  }

  // ─── Player Stats ─────────────────────────────────────
  Future<Map<String, dynamic>> getPlayerStats({
    required String name,
    required String tag,
    String region = 'ap',
    String mode = 'competitive',
    String platform = 'pc',
  }) async {
    final response = await _dio.post('/player-stat', data: {
      'name': name,
      'tag': tag,
      'region': region,
      'mode': mode,
      'platform': platform,
    });
    return response.data;
  }

  // ─── Player Analysis (AI Coach) ───────────────────────
  Future<Map<String, dynamic>> getPlayerAnalysis({
    required String name,
    required String tag,
    String region = 'ap',
    String mode = 'competitive',
    String platform = 'pc',
  }) async {
    final response = await _dio.post('/player-analysis', data: {
      'name': name,
      'tag': tag,
      'region': region,
      'mode': mode,
      'platform': platform,
    });
    return response.data;
  }

  // ─── Match Analysis AI ────────────────────────────────
  Future<Map<String, dynamic>> getMatchAnalysis(String matchId) async {
    final response = await _dio.post('/api/match-analysis/ai/$matchId');
    return response.data;
  }

  // ─── Match Analysis Full Data ─────────────────────────
  Future<Map<String, dynamic>> getMatchAnalysisData() async {
    final response = await _dio.get('/api/match-analysis');
    return response.data;
  }

  // ─── Premium Sync ─────────────────────────────────────
  Future<Map<String, dynamic>> syncPremiumStatus(String clerkId) async {
    final response = await _dio.post('/api/premium/sync/$clerkId');
    return response.data;
  }


  
  // ─── Update Quests & Data ─────────────────────────────
  Future<Map<String, dynamic>> updatePlayerDataQuests() async {
    final response = await _dio.post('/api/update-player-data-quests', data: {
      'region': 'ap',
      'platform': 'pc',
      'mode': 'competitive',
      'matches': 10,
    });
    return response.data;
  }

  // ─── Quests ───────────────────────────────────────────
  Future<Map<String, dynamic>> getQuests(String clerkId, {String? questType}) async {
    final queryParams = <String, dynamic>{};
    if (questType != null) queryParams['quest_type'] = questType;

    final response = await _dio.get(
      '/api/quests/$clerkId',
      queryParameters: queryParams,
    );
    return response.data;
  }

  // ─── Battlepass ───────────────────────────────────────
  Future<Map<String, dynamic>> getBattlepass(String clerkId) async {
    final response = await _dio.get('/api/battlepass/$clerkId');
    return response.data;
  }

  // ─── Battlepass Leaderboard ───────────────────────────
  Future<Map<String, dynamic>> getBattlepassLeaderboard() async {
    final response = await _dio.get('/api/battlepass/leaderboard');
    return response.data;
  }

  // ─── Check User Auth ─────────────────────────────────
  Future<Map<String, dynamic>> checkUserAuth(String clerkId) async {
    final response = await _dio.get('/api/check-user-auth/$clerkId');
    return response.data;
  }

  // ─── Link Riot Account ────────────────────────────────
  Future<Map<String, dynamic>> linkRiotAccount({
    required String clerkId,
    required String puuid,
    required String token,
  }) async {
    final response = await _dio.post('/api/riot-auth', data: {
      'clerk_id': clerkId,
      'puuid': puuid,
      'token': token,
    });
    return response.data;
  }

  // ─── User Status ──────────────────────────────────────
  Future<Map<String, dynamic>> getUserStatus(String clerkId) async {
    final response = await _dio.get('/api/user-status/$clerkId');
    return response.data;
  }
}
