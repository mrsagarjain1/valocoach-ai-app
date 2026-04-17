import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration for ValoCoach
class ApiConfig {
  ApiConfig._();

  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'https://battlepass.onrender.com';
  static String get nextJsUrl => dotenv.env['NEXT_JS_URL'] ?? 'https://www.valocoach.ai';
  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  // Clerk
  static String get clerkPublishableKey => dotenv.env['CLERK_PUBLISHABLE_KEY'] ?? '';

  // Riot Auth
  static const String riotAuthUrl =
      'https://auth.riotgames.com/authorize?redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&client_id=play-valorant-web-prod&response_type=token%20id_token&scope=account%20openid&nonce=1';

  // Razorpay (test key — replace with live key for production)
  // Test Key ID: rzp_test_* — get from https://dashboard.razorpay.com
  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  static const int razorpayAmountPaise = 9900; // ₹99 in paise

  // Cache TTL
  static const Duration cacheTtl = Duration(minutes: 30);
}
