import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  Dio? _dio;
  String? _clerkUserId;

  Dio get dio {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.backendUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 240),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': ApiConfig.apiKey,
          },
        ),
      );
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (_clerkUserId != null) {
              options.headers['X-Clerk-User-Id'] = _clerkUserId;
            }
            handler.next(options);
          },
          onError: (error, handler) {
            handler.next(error);
          },
        ),
      );
    }
    return _dio!;
  }

  ApiService._internal();

  void setClerkUserId(String? userId) {
    _clerkUserId = userId;
  }

  String? get clerkUserId => _clerkUserId;

  // ─── Check User Auth ──────────────────────────────────
  // Called immediately after Clerk sign-in to see if the user has a Riot
  // account linked and to fetch basic profile info.
  Future<Map<String, dynamic>> checkUserAuth(String clerkId) async {
    final response = await dio.get('/api/check-user-auth/$clerkId');
    return response.data;
  }

  // ─── User Status ─────────────────────────────────────
  Future<Map<String, dynamic>> getUserStatus(String clerkId) async {
    final response = await dio.get('/api/user-status/$clerkId');
    return response.data;
  }

  // ─── Premium Sync ─────────────────────────────────────
  // Sync premium status from the backend (e.g. after payment or app restart).
  Future<Map<String, dynamic>> syncPremiumStatus(String clerkId) async {
    final response = await dio.post('/api/premium/sync/$clerkId');
    return response.data;
  }

  // ─── Razorpay: Create Order ───────────────────────────
  // Creates a Razorpay order on the backend. Returns orderId, amount, currency.
  Future<Map<String, dynamic>> createRazorpayOrder({
    int amountPaise = ApiConfig.razorpayAmountPaise,
  }) async {
    final response = await dio.post(
      '${ApiConfig.nextJsUrl}/api/razorpay/create-order',
      data: {
        'amount': amountPaise,
      },
      options: Options(
        headers: {
          'x-user-id': _clerkUserId,
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return response.data;
  }

  // ─── Razorpay: Verify Payment ─────────────────────────
  // Called after Razorpay checkout success to verify signature and update
  // premium status in the backend.
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await dio.post(
      '${ApiConfig.nextJsUrl}/api/razorpay/verify-payment',
      data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
      options: Options(
        headers: {
          'x-user-id': _clerkUserId,
        },
      ),
    );
    return response.data;
  }

  // ─── Player Stats ─────────────────────────────────────
  Future<Map<String, dynamic>> getPlayerStats({
    required String name,
    required String tag,
    String region = 'ap',
    String mode = 'competitive',
    String platform = 'pc',
  }) async {
    final response = await dio.post(
      '/player-stat',
      data: {
        'name': name,
        'tag': tag,
        'region': region,
        'mode': mode,
        'platform': platform,
      },
    );
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
    final response = await dio.post(
      '/player-analysis',
      data: {
        'name': name,
        'tag': tag,
        'region': region,
        'mode': mode,
        'platform': platform,
      },
    );
    return response.data;
  }

  // ─── Match Analysis AI ────────────────────────────────
  Future<Map<String, dynamic>> getMatchAnalysis(String matchId) async {
    final response = await dio.post('/api/match-analysis/ai/$matchId');
    return response.data;
  }

  // ─── Match Analysis Full Data ─────────────────────────
  Future<Map<String, dynamic>> getMatchAnalysisData() async {
    final response = await dio.get('/api/match-analysis');
    return response.data;
  }

  // ─── Match Timeline (2D Replay) ───────────────────────
  Future<Map<String, dynamic>> getMatchTimeline(String matchId) async {
    final response = await dio.get('/api/match-timeline/$matchId');
    return response.data;
  }

  // ─── Update Quests & Data ─────────────────────────────
  Future<Map<String, dynamic>> updatePlayerDataQuests() async {
    final response = await dio.post(
      '/api/update-player-data-quests',
      data: {
        'platform': 'pc',
        'mode': 'competitive',
        'matches': 10,
      },
    );
    return response.data;
  }

  // ─── Quests ───────────────────────────────────────────
  Future<Map<String, dynamic>> getQuests(
    String clerkId, {
    String? questType,
  }) async {
    final queryParams = <String, dynamic>{};
    if (questType != null) queryParams['quest_type'] = questType;

    final response = await dio.get(
      '/api/quests/$clerkId',
      queryParameters: queryParams,
    );
    return response.data;
  }

  // ─── Battlepass ───────────────────────────────────────
  Future<Map<String, dynamic>> getBattlepass(String clerkId) async {
    final response = await dio.get('/api/battlepass/$clerkId');
    return response.data;
  }

  // ─── Battlepass Leaderboard ───────────────────────────
  Future<Map<String, dynamic>> getBattlepassLeaderboard() async {
    final response = await dio.get('/api/battlepass/leaderboard');
    return response.data;
  }

  // ─── Onboard User (Links Riot + Inits Data) ──────────
  Future<dynamic> onboardUser({
    required String clerkId,
    required String puuid,
    required String token,
    String region = 'ap',
  }) async {
    final response = await dio.post(
      '/api/battlepass/onboard',
      data: {
        'puuid': puuid,
        'riot_token': token,
        'region': region,
        'platform': 'pc',
        'mode': 'competitive',
        'matches': 50,
      },
    );
    return response.data;
  }
}
