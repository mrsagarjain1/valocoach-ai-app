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

  Future<void> analyze({
    required String name,
    required String tag,
    String region = 'ap',
    String mode = 'competitive',
    String platform = 'pc',
  }) async {
    state = state.copyWith(isLoading: true, error: null, isRateLimit: false);
    try {
      final result = await _api.getPlayerAnalysis(
        name: name,
        tag: tag,
        region: region,
        mode: mode,
        platform: platform,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      final msg = e.toString();
      final isRate = msg.contains('429') || msg.toLowerCase().contains('rate');
      state = state.copyWith(isLoading: false, error: msg, isRateLimit: isRate);
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AiAnalysisScreen extends ConsumerStatefulWidget {
  final String playerName;
  final String playerTag;
  final String region;
  final String mode;
  final String platform;

  const AiAnalysisScreen({
    super.key,
    required this.playerName,
    required this.playerTag,
    this.region = 'ap',
    this.mode = 'competitive',
    this.platform = 'pc',
  });

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = '${widget.playerName}_${widget.playerTag}';
      ref.read(aiAnalysisProvider(key).notifier).analyze(
        name: widget.playerName,
        tag: widget.playerTag,
        region: widget.region,
        mode: widget.mode,
        platform: widget.platform,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = '${widget.playerName}_${widget.playerTag}';
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
                      onAnalyze: () => ref.read(aiAnalysisProvider(key).notifier).analyze(
                        name: widget.playerName,
                        tag: widget.playerTag,
                        region: widget.region,
                        mode: widget.mode,
                        platform: widget.platform,
                      ),
                      playerName: widget.playerName,
                      playerTag: widget.playerTag,
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

class _Cta extends StatefulWidget {
  final String? error;
  final bool isRateLimit;
  final VoidCallback onAnalyze;
  final String playerName, playerTag;
  const _Cta({super.key, this.error, required this.isRateLimit, required this.onAnalyze, required this.playerName, required this.playerTag});

  @override
  State<_Cta> createState() => _CtaState();
}

class _CtaState extends State<_Cta> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.15, end: 0.35).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (_, child) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D0026), Color(0xFF1C0645), Color(0xFF2D1065)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: _glow.value),
                      blurRadius: 32, offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    right: -20, top: -20,
                    child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF7C3AED).withValues(alpha: 0.15))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1A0828), Color(0xFF28106A)]),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.2), blurRadius: 20)
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB78BFA), size: 48),
                      ),
                      const SizedBox(height: 32),
                      Text('AI COACH REPORT', style: AppTheme.krona(size: 24, color: Colors.white, height: 1.2), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text('Personalized insights for', style: AppTheme.inter(size: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('${widget.playerName}#${widget.playerTag}', style: AppTheme.krona(size: 16, color: const Color(0xFFB78BFA)), textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      
                      if (widget.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (widget.isRateLimit ? AppTheme.accentYellow : AppTheme.primaryRed).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (widget.isRateLimit ? AppTheme.accentYellow : AppTheme.primaryRed).withValues(alpha: 0.25)),
                          ),
                          child: Row(children: [
                            Icon(widget.isRateLimit ? Icons.timer_outlined : Icons.error_outline, color: widget.isRateLimit ? AppTheme.accentYellow : AppTheme.primaryRed, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(widget.isRateLimit ? 'Rate limit reached. Please wait a few minutes.' : widget.error!, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary))),
                          ]),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      GestureDetector(
                        onTap: widget.isRateLimit ? null : widget.onAnalyze,
                        child: AnimatedOpacity(
                          opacity: widget.isRateLimit ? 0.4 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6))],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Text('GENERATE FULL ANALYSIS', style: AppTheme.krona(size: 12, color: Colors.white, letterSpacing: 1)),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
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
    final analysis = data['analysis'] as Map<String, dynamic>? ?? data;

    // Performance fields
    final perf = analysis['performance_overview'] as Map<String, dynamic>? ?? analysis;
    final overallRating = perf['overall_rating']?.toString();
    final agentContext = perf['agent_context']?.toString();
    final combatConsistency = perf['acs_combat_consistency']?.toString();

    // Deep dive fields
    final deepDive = analysis['deep_dive_analysis'] as Map<String, dynamic>? ?? {};
    final proficiency = deepDive['combat_proficiency']?.toString();
    final tacticalAwareness = deepDive['tactical_economic_awareness']?.toString();

    final recommendedAgent = analysis['recommended_agent_and_role']?.toString();
    final quote = analysis['motivation_quote']?.toString() ?? analysis['motivation']?.toString();
    final tips = _parseTipsObjects(analysis['actionable_tips'] ?? analysis['tips']);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        
        // ── SECTION 0: MOTIVATION QUOTE (Moved to top) ──
        if (quote != null && quote.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A0800), Color(0xFF4A0E00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
              boxShadow: [
                 BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(children: [
              const Icon(Icons.format_quote_rounded, color: AppTheme.primaryRed, size: 32),
              const SizedBox(height: 12),
              Text(
                quote,
                textAlign: TextAlign.center,
                style: AppTheme.krona(size: 12, height: 1.6, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ]),
          ),
          const SizedBox(height: 32),
        ],

        // ── SECTION 1: PERFORMANCE OVERVIEW ──
        _SectionHeader(title: 'PERFORMANCE OVERVIEW', icon: Icons.analytics_outlined),
        const SizedBox(height: 16),
        if (overallRating != null && overallRating.isNotEmpty) ...[
          _RatingCard(rating: overallRating),
          const SizedBox(height: 16),
        ],
        
        if (recommendedAgent != null && recommendedAgent.isNotEmpty) 
          _InfoCard(
            title: 'RECOMMENDED AGENT', 
            body: recommendedAgent, 
            accentColor: const Color(0xFF38BDF8),
            gradient: const LinearGradient(colors: [Color(0xFF0C4A6E), Color(0xFF0369A1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        
        if (agentContext != null && agentContext.isNotEmpty) 
          _InfoCard(
            title: 'AGENT CONTEXT', 
            body: agentContext, 
            accentColor: const Color(0xFFB78BFA),
            gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          
        if (combatConsistency != null && combatConsistency.isNotEmpty) 
          _InfoCard(
            title: 'COMBAT CONSISTENCY', 
            body: combatConsistency, 
            accentColor: const Color(0xFF10B981),
            gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF065F46)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),

        const SizedBox(height: 32),

        // ── SECTION 2: DEEP DIVE ──
        _SectionHeader(title: 'DEEP DIVE ANALYSIS', icon: Icons.psychology_outlined),
        const SizedBox(height: 16),
        if (proficiency != null && proficiency.isNotEmpty) 
          _InfoCard(
            title: 'COMBAT PROFICIENCY', 
            body: proficiency, 
            accentColor: const Color(0xFFF43F5E),
            gradient: const LinearGradient(colors: [Color(0xFF4C0519), Color(0xFF881337)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          
        if (tacticalAwareness != null && tacticalAwareness.isNotEmpty) 
          _InfoCard(
            title: 'TACTICAL & ECONOMIC', 
            body: tacticalAwareness, 
            accentColor: const Color(0xFFFBBF24),
            gradient: const LinearGradient(colors: [Color(0xFF78350F), Color(0xFF92400E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),

        const SizedBox(height: 32),

        // ── SECTION 3: ACTIONABLE TIPS ──
        if (tips.isNotEmpty) ...[
          _SectionHeader(title: 'ACTIONABLE TIPS', icon: Icons.lightbulb_outline_rounded),
          const SizedBox(height: 16),
          ...tips.map((tip) => _StructTipCard(tip: tip)),
        ],

        const SizedBox(height: 40),
      ]),
    );
  }

  List<Map<String, String>> _parseTipsObjects(dynamic val) {
    if (val == null) return [];
    if (val is List) {
      return val.map((e) {
        if (e is Map) {
          return {
            'number': e['tip_number']?.toString() ?? '',
            'title': e['title']?.toString() ?? '',
            'description': e['description']?.toString() ?? '',
          };
        } else {
          return {
            'number': '',
            'title': 'Tip',
            'description': e.toString(),
          };
        }
      }).toList();
    }
    return [];
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppTheme.textMuted, size: 16),
      const SizedBox(width: 8),
      Text(title, style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 2)),
    ]);
  }
}

class _RatingCard extends StatelessWidget {
  final String rating;
  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final isNumeric = rating.length <= 5 && double.tryParse(rating.replaceAll(RegExp(r'[^0-9.]'), '')) != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0828), Color(0xFF28106A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERFORMANCE RATING', style: AppTheme.krona(size: 9, color: const Color(0xFFB78BFA), letterSpacing: 1.5)),
          const SizedBox(height: 12),
          
          if (isNumeric) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(rating, style: AppTheme.krona(size: 40, color: Colors.white)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text('/ 10', style: AppTheme.krona(size: 14, color: Colors.white54)),
              ),
            ]),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ((double.tryParse(rating) ?? 0) / 10).clamp(0.0, 1.0),
                  child: Container(decoration: BoxDecoration(color: const Color(0xFFB78BFA), borderRadius: BorderRadius.circular(2))),
                ),
              ),
            ),
          ] else ...[
             // Safe wrapping for textual descriptions
            Text(rating, style: AppTheme.inter(size: 14, height: 1.5, color: Colors.white)),
          ]
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, body;
  final LinearGradient gradient;
  final Color accentColor;
  const _InfoCard({required this.title, required this.body, required this.gradient, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTheme.krona(size: 9, color: accentColor, letterSpacing: 1.5))),
        ]),
        const SizedBox(height: 12),
        Text(body, style: AppTheme.inter(size: 14, height: 1.5, color: Colors.white.withValues(alpha: 0.95))),
      ]),
    );
  }
}

class _StructTipCard extends StatelessWidget {
  final Map<String, String> tip;
  const _StructTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final hasNumber = tip['number']?.isNotEmpty == true;
    final tipHeader = hasNumber ? 'TIP #${tip['number']}' : tip['title']!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF27272A), Color(0xFF18181B)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AppTheme.accentYellow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.accentYellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(tipHeader, style: AppTheme.krona(size: 9, color: AppTheme.accentYellow, letterSpacing: 1.2)),
          ),
        ]),
        const SizedBox(height: 12),
        if (hasNumber && tip['title']?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(tip['title']!.toUpperCase(), style: AppTheme.krona(size: 11, color: Colors.white, letterSpacing: 0.5)),
          ),
        Text(tip['description']!, style: AppTheme.inter(size: 14, height: 1.5, color: AppTheme.textPrimary)),
      ]),
    );
  }
}
