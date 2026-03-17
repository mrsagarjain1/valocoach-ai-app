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

  // Cache TTL
  static const Duration cacheTtl = Duration(minutes: 30);
}
