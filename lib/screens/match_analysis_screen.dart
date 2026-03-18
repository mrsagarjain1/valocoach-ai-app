import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';

class MatchAnalysisScreen extends ConsumerStatefulWidget {
  const MatchAnalysisScreen({super.key});

  @override
  ConsumerState<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends ConsumerState<MatchAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedMatchIndex = 0;

  @override
  void initState() {
    _tabCtrl = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final matchState = ref.watch(matchAnalysisProvider);

    if (auth.isClerkSignedIn && auth.isRiotLinked && matchState.data == null && !matchState.isLoading && matchState.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(matchAnalysisProvider.notifier).fetchMatchAnalysis();
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('MATCH ANALYSIS', style: AppTheme.krona(size: 24)),
                      const SizedBox(height: 4),
                      Text('In-depth stats and round insights', style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  labelStyle: AppTheme.krona(size: 10, letterSpacing: 1),
                  unselectedLabelStyle: AppTheme.inter(size: 11, color: AppTheme.textMuted),
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
                    Tab(text: 'ROUNDS'),
                    Tab(text: 'MATCHES'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !auth.isClerkSignedIn || !auth.isRiotLinked
                  ? _AnalysisGate(auth: auth)
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _OverviewTab(data: matchState.data, selectedIndex: _selectedMatchIndex),
                        _RoundsTab(data: matchState.data, selectedIndex: _selectedMatchIndex),
                        _MatchesTab(
                          data: matchState.data, 
                          selectedIndex: _selectedMatchIndex,
                          onSelect: (i) {
                            setState(() => _selectedMatchIndex = i);
                            _tabCtrl.animateTo(0); // Go to overview for selected match
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gate ─────────────────────────────────────────────────────────────────────

class _AnalysisGate extends ConsumerWidget {
  final AuthState auth;
  const _AnalysisGate({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsSignIn = !auth.isClerkSignedIn;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(Icons.analytics_outlined, size: 48, color: const Color(0xFF00E5FF).withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 22),
          Text(needsSignIn ? 'SIGN IN REQUIRED' : 'LINK RIOT ACCOUNT', style: AppTheme.krona(size: 18), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            needsSignIn
                ? 'Sign in to access advanced AI match analysis and performance metrics.'
                : 'Link your Riot account in Settings to analyze your recent matches.',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              if (needsSignIn) {
                Navigator.of(context).pushNamed('/clerk-login');
              } else {
                ref.read(bottomNavIndexProvider.notifier).state = 3;
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(needsSignIn ? 'GET STARTED' : 'GO TO SETTINGS', style: AppTheme.krona(size: 11, color: AppTheme.darkBg, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final Map<String, dynamic>? data;
  final int selectedIndex;
  const _OverviewTab({this.data, required this.selectedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchAnalysisProvider);

    if (state.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    if (state.error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Error: ${state.error}', style: AppTheme.inter(color: AppTheme.primaryRed), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.read(matchAnalysisProvider.notifier).fetchMatchAnalysis(), child: const Text('RETRY')),
        ]),
      );
    }
    if (data == null) return const Center(child: Text('Building insights...', style: TextStyle(color: Colors.white54)));

    // Try to get per-match data if available
    final perMatchList = data?['round_stats']?['per_match_stats'] as List?;
    final stats = data?['overall_stats'] ?? {};
    
    // Fallback focus to selected match if list exists
    final currentMatch = (perMatchList != null && perMatchList.length > selectedIndex) ? perMatchList[selectedIndex] : null;
    final matchAggregated = currentMatch != null ? (currentMatch['aggregated_stats'] ?? {}) : (data?['round_stats']?['aggregated_stats'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        Text('MATCH OVERVIEW', style: AppTheme.krona(size: 14, color: AppTheme.primaryRed)),
        if (currentMatch != null) ...[
          const SizedBox(height: 8),
          Text(
            '${currentMatch['map_name'] ?? 'Unknown Map'} • ${currentMatch['agent_name'] ?? 'Agent'}',
            style: AppTheme.inter(size: 12, color: AppTheme.textSecondary, weight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildSmallStat('TOTAL MATCHES', stats['total_matches']?.toString() ?? '0', Icons.games),
            _buildSmallStat('GLOBAL WIN RATE', stats['win_rate']?.toString() ?? '0%', Icons.emoji_events),
            _buildSmallStat('AVG K/D', stats['average_kd']?.toString() ?? '0.0', Icons.my_location),
            _buildSmallStat('HS %', stats['average_headshot_percentage']?.toString() ?? '0%', Icons.track_changes),
          ],
        ),
        const SizedBox(height: 32),
        Text('ROUND ANALYTICS', style: AppTheme.krona(size: 14, color: AppTheme.primaryRed)),
        const SizedBox(height: 16),
        _buildFullStat('Damage / Round', matchAggregated['damage_per_round']?.toStringAsFixed(1) ?? '0', Icons.bolt, Colors.orange),
        _buildFullStat('Multi-Kills', matchAggregated['multikill_count']?.toString() ?? '0', Icons.military_tech, Colors.purple),
        _buildFullStat('Aces', matchAggregated['ace_count']?.toString() ?? '0', Icons.star, Colors.yellow),
        _buildFullStat('Clutches Won', matchAggregated['clutch_situations_won']?.toString() ?? '0', Icons.gavel, Colors.blue),
        _buildFullStat('Plants / Defuses', '${matchAggregated['plants_count'] ?? 0} / ${matchAggregated['defuses_count'] ?? 0}', Icons.timer, Colors.red),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.inter(size: 9, color: AppTheme.textSecondary, weight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.krona(size: 17)),
      ]),
    );
  }

  Widget _buildFullStat(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: AppTheme.inter(size: 13, color: AppTheme.textPrimary, weight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: AppTheme.krona(size: 15)),
        ]),
      ),
    );
  }
}

// ─── Rounds Tab ───────────────────────────────────────────────────────────────

class _RoundsTab extends ConsumerWidget {
  final Map<String, dynamic>? data;
  final int selectedIndex;
  const _RoundsTab({this.data, required this.selectedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchAnalysisProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    
    final perMatch = data?['round_stats']?['per_match_stats'] as List?;
    if (perMatch == null || perMatch.isEmpty) return const Center(child: Text('No round data available', style: TextStyle(color: Colors.white54)));

    // Focus on selected match
    final currentMatch = (selectedIndex < perMatch.length) ? perMatch[selectedIndex] : perMatch[0];
    final rounds = currentMatch['per_round_details'] as List?;
    
    if (rounds == null || rounds.isEmpty) return const Center(child: Text('Round details for this match aren\'t available yet.', style: TextStyle(color: Colors.white54)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: rounds.length,
      itemBuilder: (context, index) {
        final r = rounds[index];
        final won = r['round_result'] == 'won';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: won ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
             Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
               Text('ROUND ${r['round_num']}', style: AppTheme.krona(size: 11)),
               const SizedBox(height: 4),
               Text(r['player_side']?.toString().toUpperCase() ?? '', style: AppTheme.inter(size: 9, color: AppTheme.textMuted, weight: FontWeight.w700, letterSpacing: 0.5)),
             ]),
             const Spacer(),
             if (r['got_first_blood'] == true) 
               const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.flash_on, color: Colors.yellow, size: 18)),
             Text('${r['kills_in_round'] ?? 0} KILLS', style: AppTheme.krona(size: 10)),
             const SizedBox(width: 16),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
               decoration: BoxDecoration(
                 color: won ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(6),
               ),
               child: Text(won ? 'WIN' : 'LOSS', style: AppTheme.krona(size: 8, color: won ? Colors.green : Colors.red, letterSpacing: 0.5)),
             ),
          ]),
        );
      },
    );
  }
}

// ─── Matches Tab ──────────────────────────────────────────────────────────────

class _MatchesTab extends ConsumerWidget {
  final Map<String, dynamic>? data;
  final int selectedIndex;
  final Function(int) onSelect;
  const _MatchesTab({this.data, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchAnalysisProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    
    // Per-match stats has agent names and maps
    final perMatch = data?['round_stats']?['per_match_stats'] as List?;
    if (perMatch == null || perMatch.isEmpty) return const Center(child: Text('No match history found', style: TextStyle(color: Colors.white54)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: perMatch.length,
      itemBuilder: (context, index) {
        final m = perMatch[index];
        final isSelected = selectedIndex == index;
        final map = m['map_name'] ?? 'Unknown Map';
        final agent = m['agent_name'] ?? 'Agent';
        final deaths = m['deaths'] ?? 1;
        final kd = ((m['kills'] ?? 0) / (deaths == 0 ? 1 : deaths)).toStringAsFixed(1);

        return GestureDetector(
          onTap: () => onSelect(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.08) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.3) : AppTheme.borderColor, width: isSelected ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sports_esports_rounded, color: AppTheme.textMuted, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(map.toUpperCase(), style: AppTheme.krona(size: 11)),
                const SizedBox(height: 2),
                Text(agent, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('K/D $kd', style: AppTheme.krona(size: 10, color: AppTheme.accentGreen)),
                const SizedBox(height: 4),
                Text('${m['kills'] ?? 0} Kills', style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.w600)),
              ]),
              if (isSelected) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check_circle, color: AppTheme.primaryRed, size: 16),
              ],
            ]),
          ),
        );
      },
    );
  }
}
