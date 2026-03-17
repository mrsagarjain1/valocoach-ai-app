import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';

// Provider for AI analysis state
final aiAnalysisProvider = StateNotifierProvider.autoDispose
    .family<AiAnalysisNotifier, AiAnalysisState, String>(
  (ref, key, ) => AiAnalysisNotifier(ref.read(apiServiceProvider)),
);

class AiAnalysisState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final bool isRateLimit;
  const AiAnalysisState({this.isLoading = false, this.data, this.error, this.isRateLimit = false});
  AiAnalysisState copyWith({bool? isLoading, Map<String, dynamic>? data, String? error, bool? isRateLimit}) =>
      AiAnalysisState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        error: error ?? this.error,
        isRateLimit: isRateLimit ?? this.isRateLimit,
      );
}

class AiAnalysisNotifier extends StateNotifier<AiAnalysisState> {
  final ApiService _api;
  AiAnalysisNotifier(this._api) : super(const AiAnalysisState());

  Future<void> analyze(String name, String tag) async {
    state = state.copyWith(isLoading: true, error: null, isRateLimit: false);
    try {
      final result = await _api.getPlayerAnalysis(name: name, tag: tag);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      final msg = e.toString();
      final isRate = msg.contains('429') || msg.toLowerCase().contains('rate');
      state = state.copyWith(isLoading: false, error: msg, isRateLimit: isRate);
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AiAnalysisScreen extends ConsumerWidget {
  final String playerName;
  final String playerTag;
  const AiAnalysisScreen({super.key, required this.playerName, required this.playerTag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = '${playerName}_$playerTag';
    final state = ref.watch(aiAnalysisProvider(key));
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('AI COACH', style: AppTheme.krona(size: 16, letterSpacing: 1)),
      ),
      body: !auth.isClerkSignedIn
          ? _AuthGate()
          : state.isLoading
              ? _LoadingView()
              : state.data != null
                  ? _AnalysisView(data: state.data!)
                  : _Cta(
                      error: state.error,
                      isRateLimit: state.isRateLimit,
                      onAnalyze: () => ref.read(aiAnalysisProvider(key).notifier).analyze(playerName, playerTag),
                      playerName: playerName,
                      playerTag: playerTag,
                    ),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────

class _AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A0828), Color(0xFF28106A)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: Color(0xFFB78BFA), size: 42),
          ),
          const SizedBox(height: 24),
          Text('SIGN IN REQUIRED', style: AppTheme.krona(size: 18)),
          const SizedBox(height: 8),
          Text(
            'AI Coach analysis is available for signed-in users. Create a free account to unlock personalized tips.',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/onboarding'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.35), blurRadius: 16)],
              ),
              child: Text('GET STARTED', style: AppTheme.krona(size: 13, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A0828), Color(0xFF28106A)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB78BFA), size: 40),
        ),
        const SizedBox(height: 24),
        Text('ANALYZING...', style: AppTheme.krona(size: 16, color: const Color(0xFFB78BFA), letterSpacing: 2)),
        const SizedBox(height: 12),
        Text('Processing your match data', style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        const SizedBox(
          width: 180,
          child: LinearProgressIndicator(
            color: Color(0xFF7C3AED),
            backgroundColor: Color(0xFF2D1065),
          ),
        ),
      ]),
    );
  }
}

// ─── Call to Action ───────────────────────────────────────────────────────────

class _Cta extends StatelessWidget {
  final String? error;
  final bool isRateLimit;
  final VoidCallback onAnalyze;
  final String playerName, playerTag;
  const _Cta({this.error, required this.isRateLimit, required this.onAnalyze, required this.playerName, required this.playerTag});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A0828), Color(0xFF28106A)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 30)],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB78BFA), size: 44),
          ),
          const SizedBox(height: 24),
          Text('AI COACH', style: AppTheme.krona(size: 22, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Get personalized analysis for\n$playerName#$playerTag',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 13, color: AppTheme.textSecondary),
          ),

          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isRateLimit ? AppTheme.accentYellow : AppTheme.primaryRed).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isRateLimit ? AppTheme.accentYellow : AppTheme.primaryRed).withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Icon(isRateLimit ? Icons.timer_outlined : Icons.error_outline, color: isRateLimit ? AppTheme.accentYellow : AppTheme.primaryRed, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(isRateLimit ? 'Rate limit reached. Please wait a few minutes.' : error!, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary))),
              ]),
            ),
          ],

          const SizedBox(height: 32),

          GestureDetector(
            onTap: isRateLimit ? null : onAnalyze,
            child: AnimatedOpacity(
              opacity: isRateLimit ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text('ANALYZE NOW', style: AppTheme.krona(size: 13, letterSpacing: 1)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Analysis View ────────────────────────────────────────────────────────────

class _AnalysisView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnalysisView({required this.data});

  @override
  Widget build(BuildContext context) {
    // Flatten nested structure — API may return data under 'analysis' key
    final analysis = data['analysis'] as Map<String, dynamic>? ?? data;

    final overallRating   = analysis['overall_rating']?.toString();
    final agentContext    = analysis['agent_context']?.toString();
    final archetype       = analysis['player_archetype']?.toString();
    final hiddenStrength  = analysis['hidden_strength']?.toString();
    final rankInsight     = analysis['rank_unlock_insight']?.toString();
    final tips            = _parseTips(analysis['actionable_tips'] ?? analysis['tips']);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Rating badge
        if (overallRating != null) _RatingCard(rating: overallRating),
        const SizedBox(height: 20),

        if (agentContext != null) _InfoCard(title: 'AGENT CONTEXT', body: agentContext, color: const Color(0xFFB78BFA)),
        if (archetype != null) _InfoCard(title: 'PLAYER ARCHETYPE', body: archetype, color: AppTheme.accentBlue),
        if (hiddenStrength != null) _InfoCard(title: 'HIDDEN STRENGTH', body: hiddenStrength, color: AppTheme.accentGreen),
        if (rankInsight != null) _InfoCard(title: 'RANK INSIGHT', body: rankInsight, color: AppTheme.accentYellow),

        if (tips.isNotEmpty) ...[
          Text('ACTIONABLE TIPS', style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 2)),
          const SizedBox(height: 12),
          ...tips.map((tip) => _TipCard(tip: tip)),
        ],

        const SizedBox(height: 40),
      ]),
    );
  }

  List<String> _parseTips(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).toList();
    if (val is String) return [val];
    return [];
  }
}

class _RatingCard extends StatelessWidget {
  final String rating;
  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A0828), Color(0xFF28106A)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.35)),
      ),
      child: Column(children: [
        Text('OVERALL RATING', style: AppTheme.inter(size: 11, color: Colors.white60, weight: FontWeight.w600, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(rating, style: AppTheme.krona(size: 42, color: const Color(0xFFB78BFA))),
        const SizedBox(height: 4),
        Text('out of 10', style: AppTheme.inter(size: 12, color: Colors.white54)),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, body;
  final Color color;
  const _InfoCard({required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.krona(size: 9, color: color, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(body, style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 6, height: 6,
          decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(tip, style: AppTheme.inter(size: 13, color: AppTheme.textSecondary))),
      ]),
    );
  }
}
