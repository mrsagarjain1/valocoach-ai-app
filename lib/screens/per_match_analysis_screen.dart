import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';

class PerMatchAnalysisScreen extends ConsumerWidget {
  final String matchId;
  const PerMatchAnalysisScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('AI MATCH ANALYSIS', style: AppTheme.krona(size: 14, letterSpacing: 1.5, color: Colors.white)),
        centerTitle: true,
      ),
      body: PerMatchAnalysisBody(matchId: matchId),
    );
  }
}

/// Reusable body widget — can be embedded inside MatchDetailScreen's AI tab.
class PerMatchAnalysisBody extends ConsumerStatefulWidget {
  final String matchId;
  const PerMatchAnalysisBody({super.key, required this.matchId});

  @override
  ConsumerState<PerMatchAnalysisBody> createState() => _PerMatchAnalysisBodyState();
}

class _PerMatchAnalysisBodyState extends ConsumerState<PerMatchAnalysisBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(perMatchAnalysisProvider(widget.matchId).notifier).fetchAnalysis();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(perMatchAnalysisProvider(widget.matchId));
    final ai = state.data?['ai_analysis'];

    if (state.isLoading) return _LoadingView();
    if (state.error != null) return _ErrorView(error: state.error!);
    if (ai == null) return const SizedBox();

    return Column(
      children: [
        _TabHeader(tabCtrl: _tabCtrl),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _SummaryTab(ai: ai),
              _CombatTab(ai: ai),
              _EconomyTab(ai: ai),
              _FlowTab(ai: ai),
              _UtilityTab(ai: ai),
              _ImproveTab(ai: ai),
              _InsightsTab(ai: ai),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sub-Tabs ───────────────────────────────────────────────────────────────

class _TabHeader extends StatelessWidget {
  final TabController tabCtrl;
  const _TabHeader({required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TabBar(
        controller: tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: AppTheme.krona(size: 9, letterSpacing: 0.5),
        unselectedLabelStyle: AppTheme.inter(size: 10, color: AppTheme.textMuted),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textMuted,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'COMBAT'),
          Tab(text: 'ECONOMY'),
          Tab(text: 'FLOW'),
          Tab(text: 'UTILITY'),
          Tab(text: 'IMPROVE'),
          Tab(text: 'INSIGHTS'),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final Map<String, dynamic> ai;
  const _SummaryTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    final outcome = (ai['match_outcome'] ?? '').toString().toUpperCase();
    final isWin = outcome.contains('VICTORY') || outcome.contains('WON');
    final accent = isWin ? AppTheme.accentGreen : AppTheme.primaryRed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 0),
            ],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(outcome, style: AppTheme.krona(size: 11, color: accent, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 24),
            Text('PERFORMANCE RATING', 
                style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.w800, letterSpacing: 2)),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  ai['performance_rating']?.toString() ?? 'N/A', 
                  style: AppTheme.krona(size: 38, color: Colors.white, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (ai['player_archetype'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ai['player_archetype']!.toString().toUpperCase(), 
                  style: AppTheme.inter(size: 12, color: AppTheme.accentYellow, weight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 24),
        _InfoCard(title: 'AI COACH SUMMARY', content: ai['match_summary'], icon: Icons.auto_awesome_outlined, accentColor: AppTheme.primaryRed),
        const SizedBox(height: 16),
        if (ai['hidden_strength'] != null)
          _InfoCard(title: 'PLAYSTYLE INSIGHT', content: ai['hidden_strength'], icon: Icons.flash_on_rounded, accentColor: AppTheme.accentYellow),
        const SizedBox(height: 16),
        if (ai['rank_unlock_insight'] != null)
          _InfoCard(title: 'RANK CLIMB TIP', content: ai['rank_unlock_insight'], icon: Icons.trending_up_rounded, accentColor: AppTheme.accentGreen),
      ]),
    );
  }
}

class _CombatTab extends StatelessWidget {
  final Map<String, dynamic> ai;
  const _CombatTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    final cb = ai['combat_breakdown'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _AnalysisTile(title: 'K/D RATIO & KILLS', content: cb['kill_death_analysis'], icon: Icons.gps_fixed_rounded),
        _AnalysisTile(title: 'HEADSHOT ACCURACY', content: cb['headshot_analysis'], icon: Icons.center_focus_strong_rounded),
        _AnalysisTile(title: 'DAMAGE PER ROUND', content: cb['damage_efficiency'], icon: Icons.local_fire_department_rounded),
        _AnalysisTile(title: 'MULTIKILL IMPACT', content: cb['multikill_performance'], icon: Icons.groups_rounded),
      ]),
    );
  }
}

class _EconomyTab extends StatelessWidget {
  final Map<String, dynamic> ai;
  const _EconomyTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    final eco = ai['economy_analysis'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _AnalysisTile(title: 'SPENDING EFFICIENCY', content: eco['spending_efficiency'], icon: Icons.savings_rounded, color: AppTheme.accentGreen),
        _AnalysisTile(title: 'WEAPON LOADOUTS', content: eco['weapon_performance'], icon: Icons.handyman_rounded, color: AppTheme.accentGreen),
        _AnalysisTile(title: 'ECONOMIC PRESSURE', content: eco['economic_impact'], icon: Icons.trending_down_rounded, color: AppTheme.accentGreen),
      ]),
    );
  }
}

class _FlowTab extends StatelessWidget {
  final Map<String, dynamic> ai;
  const _FlowTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    final flow = ai['round_flow'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _AnalysisTile(title: 'ATTACKING INSIGHT', content: flow['attack_side_performance'], icon: Icons.arrow_forward_rounded, color: Colors.blueAccent),
        _AnalysisTile(title: 'DEFENDING INSIGHT', content: flow['defense_side_performance'], icon: Icons.shield_rounded, color: Colors.blueAccent),
        _AnalysisTile(title: 'MOMENTUM SHIFTS', content: flow['momentum_analysis'], icon: Icons.query_stats_rounded, color: Colors.blueAccent),
        _AnalysisTile(title: 'CRITICAL ROUNDS', content: flow['critical_round_breakdown'], icon: Icons.warning_amber_rounded, color: Colors.blueAccent),
      ]),
    );
  }
}

class _UtilityTab extends StatelessWidget {
  final Map<String, dynamic> ai;
  const _UtilityTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    final util = ai['agent_utility'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _AnalysisTile(title: 'ABILITY RATING', content: util['ability_usage_rating'], icon: Icons.auto_fix_high_rounded, color: const Color(0xFF7C3AED)),
        _AnalysisTile(title: 'AGENT IMPACT', content: util['utility_impact'], icon: Icons.star_purple500_rounded, color: const Color(0xFF7C3AED)),
        _AnalysisTile(title: 'ULTIMATE USAGE', content: util['ultimate_usage'], icon: Icons.bolt_rounded, color: const Color(0xFF7C3AED)),
      ]),
    );
  }
}

class _ImproveTab extends StatelessWidget {
  final Map<String, dynamic> ai;
  const _ImproveTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    final List improvements = ai['top_improvements'] ?? [];
    if (improvements.isEmpty) {
      return Center(child: Text('Play more to generate improvements', style: AppTheme.inter(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: improvements.length,
      itemBuilder: (context, index) {
        final imp = improvements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.stars_rounded, color: AppTheme.accentYellow, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(imp['area']?.toUpperCase() ?? 'FOCUS AREA',
                    style: AppTheme.krona(size: 13, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatChip(label: 'CURRENT', value: imp['current_stat']),
                const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted, size: 14),
                _StatChip(label: 'TARGET', value: imp['target_stat'], color: AppTheme.accentGreen),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 14),
            ... (imp['action_steps'] as List? ?? []).map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.check_circle_outline_rounded, color: AppTheme.accentGreen, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(step, style: AppTheme.inter(size: 13, color: Colors.white70, height: 1.4))),
              ]),
            )),
          ]),
        );
      },
    );
  }
}

class _InsightsTab extends StatelessWidget {
  final Map<String, dynamic> ai;
  const _InsightsTab({required this.ai});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _InfoCard(title: 'MVP MOMENTS', content: ai['mvp_moments'], icon: Icons.emoji_events_rounded, accentColor: Colors.amber),
        const SizedBox(height: 16),
        _InfoCard(title: 'TILT CHECK', content: ai['tilt_check'] ?? 'Maintaining focus throughout the rounds.', icon: Icons.timer_outlined, accentColor: const Color(0xFFC084FC)),
        const SizedBox(height: 16),
        _InfoCard(title: 'NEXT MATCH FOCUS', content: ai['next_match_focus'] ?? 'Keep consistent crosshair placement.', icon: Icons.flag_rounded, accentColor: AppTheme.accentCyan),
      ]),
    );
  }
}

// ─── Shared Components ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final dynamic content;
  final IconData icon;
  final Color accentColor;
  const _InfoCard({required this.title, required this.content, required this.icon, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final text = content?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Text(title, style: AppTheme.krona(size: 11, color: Colors.white, letterSpacing: 1)),
        ]),
        const SizedBox(height: 14),
        Text(text, style: AppTheme.inter(size: 14, color: Colors.white70, height: 1.5)),
      ]),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final String title;
  final dynamic content;
  final IconData icon;
  final Color? color;
  const _AnalysisTile({required this.title, required this.content, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primaryRed;
    final text = content?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 10),
          Text(title, style: AppTheme.inter(size: 10, color: accent, weight: FontWeight.w800, letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 12),
        Text(text, style: AppTheme.inter(size: 14, color: Colors.white, height: 1.4)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color? color;
  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.surfaceDark).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (color ?? AppTheme.borderColor).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.inter(size: 8, color: AppTheme.textMuted, weight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value?.toString() ?? '-', style: AppTheme.krona(size: 12, color: color ?? Colors.white)),
      ]),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator(color: AppTheme.primaryRed, strokeWidth: 3),
        ),
        const SizedBox(height: 32),
        Text('AI IS ANALYZING YOUR PERFORMANCE…', style: AppTheme.krona(size: 12, color: Colors.white)),
        const SizedBox(height: 12),
        Text('Synchronizing round stats and tactical data', style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.primaryRed, size: 48),
          const SizedBox(height: 20),
          Text('COULD NOT LOAD INSIGHTS', style: AppTheme.krona(size: 16)),
          const SizedBox(height: 10),
          Text(error, style: AppTheme.inter(size: 13, color: AppTheme.textMuted), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
