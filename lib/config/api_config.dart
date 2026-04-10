/// API Configuration for ValoCoach
class ApiConfig {
  ApiConfig._();

  static const String backendUrl = 'https://battlepass.onrender.com';
  static const String apiKey = 'ommvquCzN3CeKKshW9313V1K77TlEQlb';

  // Clerk
  static const String clerkPublishableKey =
      'pk_test_cG9zc2libGUtY2xhbS0xLmNsZXJrLmFjY291bnRzLmRldiQ';

  // Riot Auth
  static const String riotAuthUrl =
      'https://auth.riotgames.com/authorize?redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&client_id=play-valorant-web-prod&response_type=token%20id_token&scope=account%20openid&nonce=1';

  // Razorpay (test key — replace with live key for production)
  // Test Key ID: rzp_test_* — get from https://dashboard.razorpay.com
  static const String razorpayKeyId = 'rzp_test_5O5y63a2SthJq9';
  static const int razorpayAmountPaise = 9900; // ₹99 in paise

  // Cache TTL
  static const Duration cacheTtl = Duration(minutes: 30);
}
