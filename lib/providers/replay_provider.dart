import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final replayTimelineProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, matchId) async {
  try {
    final api = ApiService();
    final data = await api.getMatchTimeline(matchId);
    return data;
  } catch (e) {
    print('Failed to fetch timeline for $matchId: $e');
    return null;
  }
});
