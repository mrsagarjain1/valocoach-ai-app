// Round IDs from the API are 0-indexed. Display as (round_id + 1).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import 'match_detail_screen.dart';

class MatchAnalysisScreen extends ConsumerStatefulWidget {
  const MatchAnalysisScreen({super.key});

  @override
  ConsumerState<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends ConsumerState<MatchAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    _tabCtrl = TabController(length: 2, vsync: this);
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

    if (auth.isClerkSignedIn &&
        auth.isRiotLinked &&
        matchState.data == null &&
        !matchState.isLoading &&
        matchState.error == null) {
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
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MATCH ANALYSIS', style: AppTheme.krona(size: 24)),
                    const SizedBox(height: 4),
                    Text('In-depth stats and round insights',
                        style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
                  ]),
                ),
                if (matchState.data != null)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                    onPressed: () => ref.read(matchAnalysisProvider.notifier).fetchMatchAnalysis(),
                  ),
              ]),
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
                    Tab(text: 'HISTORY'),
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
                        _OverviewTab(
                          data: matchState.data,
                          selectedMatchIndex: 0,
                          isLoading: matchState.isLoading,
                          error: matchState.error,
                        ),
                        _HistoryTab(
                          data: matchState.data,
                          isLoading: matchState.isLoading,
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

// ─── Data Helpers ─────────────────────────────────────────────────────────────

/// Safely unwrap data.data nesting
Map<String, dynamic> _root(Map<String, dynamic>? raw) {
  if (raw == null) return {};
  return raw['data'] as Map<String, dynamic>? ?? raw;
}

/// data.data.round_stats.per_match_stats[]
List<Map<String, dynamic>> _perMatchStats(Map<String, dynamic>? raw) {
  final r = _root(raw);
  final list = r['round_stats']?['per_match_stats'] as List? ?? [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// data.data.comprehensive_stats.matches[]
List<Map<String, dynamic>> _matches(Map<String, dynamic>? raw) {
  final r = _root(raw);
  final list = r['comprehensive_stats']?['matches'] as List? ?? [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// Safe num-as-double helper — handles int, double, String
double _num(dynamic v, [double def = 0]) {
  if (v == null) return def;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? def;
}

/// Safe int helper
int _int(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? def;
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
            child: Icon(Icons.analytics_outlined,
                size: 48, color: const Color(0xFF00E5FF).withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 22),
          Text(needsSignIn ? 'SIGN IN REQUIRED' : 'LINK RIOT ACCOUNT',
              style: AppTheme.krona(size: 18), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            needsSignIn
                ? 'Sign in to access advanced match analysis and performance metrics.'
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
                  BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                  needsSignIn ? 'GET STARTED' : 'GO TO SETTINGS',
                  style: AppTheme.krona(size: 11, color: AppTheme.darkBg, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  final int selectedMatchIndex;
  final bool isLoading;
  final String? error;

  const _OverviewTab({
    this.data,
    required this.selectedMatchIndex,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(color: AppTheme.primaryRed),
          const SizedBox(height: 16),
          Text('Crunching your match data…',
              style: AppTheme.inter(size: 13, color: AppTheme.textMuted)),
        ]),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.primaryRed, size: 48),
            const SizedBox(height: 16),
            Text('Error loading data', style: AppTheme.krona(size: 16)),
            const SizedBox(height: 8),
            Text(error!,
                style: AppTheme.inter(size: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    if (data == null) {
      return Center(
          child: Text('No data yet', style: AppTheme.inter(color: AppTheme.textMuted)));
    }

    final root = _root(data);
    final overall = root['overall_stats'] as Map<String, dynamic>? ?? {};
    final roundStats = root['round_stats'] as Map<String, dynamic>? ?? {};
    final agg = roundStats['aggregated_stats'] as Map<String, dynamic>? ?? {};
    final playerIdentity = root['player_identity'] as Map<String, dynamic>? ?? {};

    final perMatchList = _perMatchStats(data);
    final matchesList = _matches(data);

    final currentPerMatch = perMatchList.isNotEmpty && selectedMatchIndex < perMatchList.length
        ? perMatchList[selectedMatchIndex]
        : null;
    final currentMatchObj = matchesList.isNotEmpty && selectedMatchIndex < matchesList.length
        ? matchesList[selectedMatchIndex]
        : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        if (playerIdentity.isNotEmpty) ...[
          _PlayerIdentityCard(identity: playerIdentity),
          const SizedBox(height: 24),
        ],

        Text('OVERALL STATS',
            style: AppTheme.krona(size: 12, color: AppTheme.primaryRed, letterSpacing: 1.5)),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _StatCard('TOTAL MATCHES', _int(overall['total_matches']).toString(),
                Icons.games_rounded, AppTheme.accentBlue),
            _StatCard('WIN RATE', '${_num(overall['win_rate']).toStringAsFixed(1)}%',
                Icons.emoji_events_rounded, AppTheme.accentGreen),
            _StatCard('AVG K/D', _num(overall['average_kd']).toStringAsFixed(2),
                Icons.my_location_rounded, AppTheme.primaryRed),
            _StatCard('HS %',
                '${_num(overall['average_headshot_percentage']).toStringAsFixed(1)}%',
                Icons.track_changes_rounded, AppTheme.accentYellow),
            _StatCard('DMG/ROUND',
                _num(overall['average_damage_per_round']).toStringAsFixed(0),
                Icons.bolt_rounded, Colors.orange),
            _StatCard(
                'W / L',
                '${_int(overall['total_wins'])} / ${_int(overall['total_losses'])}',
                Icons.bar_chart_rounded,
                Colors.purple),
          ],
        ),

        const SizedBox(height: 28),

        Text('ROUND AGGREGATES',
            style: AppTheme.krona(size: 12, color: const Color(0xFFFBBF24), letterSpacing: 1.5)),
        const SizedBox(height: 14),
        _AggregatedGrid(agg: agg, roundStats: roundStats),

        if (currentMatchObj != null || currentPerMatch != null) ...[
          const SizedBox(height: 28),
          Text('SELECTED MATCH',
              style: AppTheme.krona(size: 12, color: AppTheme.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 14),
          _SelectedMatchReport(
              match: currentMatchObj ?? {}, perMatchStats: currentPerMatch ?? {}),
        ],

        const SizedBox(height: 60),
      ],
    );
  }
}

class _AggregatedGrid extends StatelessWidget {
  final Map<String, dynamic> agg;
  final Map<String, dynamic> roundStats;
  const _AggregatedGrid({required this.agg, required this.roundStats});

  @override
  Widget build(BuildContext context) {
    if (agg.isEmpty) {
      return Text('No aggregated data available.',
          style: AppTheme.inter(size: 12, color: AppTheme.textMuted));
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _AggCard('TOTAL ROUNDS', _int(roundStats['total_rounds']).toString(), const Color(0xFFFFFFFF))),
        const SizedBox(width: 10),
        Expanded(child: _AggCard('DMG / ROUND', _num(agg['damage_per_round']).toStringAsFixed(1), const Color(0xFFF53D4C))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _AggCard('TRADE RATIO', _num(agg['damage_trade_ratio']).toStringAsFixed(2), const Color(0xFF0FB5AE))),
        const SizedBox(width: 10),
        Expanded(child: _AggCard('ECON EFF.', '${_num(agg['economy_efficiency_pct']).toStringAsFixed(1)}%', const Color(0xFFA855F7))),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _AggCard('FIRST BLOODS', _int(agg['first_blood_count']).toString(), const Color(0xFF16C47F))),
        const SizedBox(width: 10),
        Expanded(child: _AggCard('FIRST DEATHS', _int(agg['first_death_count']).toString(), const Color(0xFFF53D4C))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _AggCard('MULTI KILLS', _int(agg['multikill_count']).toString(), const Color(0xFFFBBF24))),
        const SizedBox(width: 10),
        Expanded(child: _AggCard('PLANTS', _int(agg['plants_count']).toString(), const Color(0xFFEC4899))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _AggCard('DEFUSES', _int(agg['defuses_count']).toString(), const Color(0xFF8B5CF6))),
        const SizedBox(width: 10),
        Expanded(child: _AggCard('ACES', _int(agg['ace_count']).toString(), const Color(0xFFFBBF24))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _AggCard('ATK WON',
            '${_int(agg['attack_rounds_won'])}/${_int(agg['total_attack_rounds'])} (${_num(agg['attack_win_rate']).toStringAsFixed(0)}%)',
            const Color(0xFFF53D4C))),
        const SizedBox(width: 10),
        Expanded(child: _AggCard('DEF WON',
            '${_int(agg['defense_rounds_won'])}/${_int(agg['total_defense_rounds'])} (${_num(agg['defense_win_rate']).toStringAsFixed(0)}%)',
            const Color(0xFF0FB5AE))),
      ]),
    ]);
  }
}

class _PlayerIdentityCard extends StatelessWidget {
  final Map<String, dynamic> identity;
  const _PlayerIdentityCard({required this.identity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0520), Color(0xFF0A0E1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(
            identity['player_name']?.toString().split('#').first ?? 'Player',
            style: AppTheme.krona(size: 22, color: Colors.white),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
            ),
            child: Text('LVL ${_int(identity['player_account_level'])}',
                style: AppTheme.krona(size: 10, color: AppTheme.primaryRed)),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 8, children: [
          _IdentityChip(Icons.military_tech_rounded,
              identity['current_rank']?.toString() ?? 'Unranked', const Color(0xFFFBBF24)),
          _IdentityChip(Icons.trending_up_rounded,
              'Peak: ${identity['peak_rank']?.toString() ?? 'N/A'}', const Color(0xFF0FB5AE)),
          if ((identity['rank_protection_shields']?.toString() ?? '0') != '0')
            _IdentityChip(Icons.shield_rounded,
                '${identity['rank_protection_shields']} Shields', const Color(0xFFA855F7)),
          if (identity['leaderboard_placement'] != null &&
              identity['leaderboard_placement'].toString() != 'NONE')
            _IdentityChip(Icons.leaderboard_rounded,
                '#${identity['leaderboard_placement']}', AppTheme.accentGreen),
        ]),
      ]),
    );
  }
}

class _IdentityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _IdentityChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Text(label,
          style: AppTheme.inter(size: 11, color: Colors.white70, weight: FontWeight.w600)),
    ]);
  }
}

class _SelectedMatchReport extends StatelessWidget {
  final Map<String, dynamic> match;
  final Map<String, dynamic> perMatchStats;
  const _SelectedMatchReport({required this.match, required this.perMatchStats});

  @override
  Widget build(BuildContext context) {
    final meta = match['match_metadata'] as Map<String, dynamic>? ?? {};
    final combat = match['combat_stats'] as Map<String, dynamic>? ?? {};
    final agent = match['agent_and_abilities'] as Map<String, dynamic>? ?? {};

    final isWin = meta['won'] == true;
    final resultLabel = isWin ? 'VICTORY' : 'DEFEAT';
    final color = isWin ? const Color(0xFF0FB5AE) : const Color(0xFFF53D4C);

    final kills = _int(combat['kills']);
    final deaths = _int(combat['deaths']);
    final assists = _int(combat['assists']);
    final acs = _num(combat['acs']);
    final hsPercent = _num(combat['headshot_percentage']);
    final mapName = meta['map_name']?.toString() ?? 'Unknown';
    final agentName = agent['agent_name']?.toString() ?? 'Unknown';
    final roundsWon = _int(perMatchStats['rounds_won']);
    final roundsLost = _int(perMatchStats['rounds_lost']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 4,
              height: 40,
              decoration:
                  BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mapName.toUpperCase(), style: AppTheme.krona(size: 14, color: Colors.white)),
            Text(agentName, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(resultLabel, style: AppTheme.krona(size: 11, color: color)),
            Text('$roundsWon - $roundsLost',
                style: AppTheme.inter(size: 11, color: AppTheme.textMuted, weight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _MatchStatlet('K/D/A', '$kills/$deaths/$assists', Colors.white)),
          Expanded(child: _MatchStatlet('ACS', acs.toStringAsFixed(0), const Color(0xFF0FB5AE))),
          Expanded(child: _MatchStatlet('HS %', '${hsPercent.toStringAsFixed(1)}%', const Color(0xFFFBBF24))),
          Expanded(child: _MatchStatlet('AGENT', agentName, AppTheme.textMuted)),
        ]),
      ]),
    );
  }
}

class _MatchStatlet extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _MatchStatlet(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: AppTheme.inter(size: 8, color: AppTheme.textMuted, weight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(value, style: AppTheme.krona(size: 12, color: valueColor)),
    ]);
  }
}

Widget _StatCard(String label, String value, IconData icon, Color color) {
  return Builder(
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(label,
                      style: AppTheme.inter(
                          size: 8, color: AppTheme.textMuted, weight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.krona(size: 18, color: color)),
          ]),
    ),
  );
}

Widget _AggCard(String label, String value, Color color) {
  return Builder(
    builder: (_) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTheme.inter(size: 8, color: AppTheme.textMuted, weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.krona(size: 16, color: color)),
      ]),
    ),
  );
}

// ─── History Tab ──────────────────────────────────────────────────────────────
// Shows all matches; tapping one opens MatchDetailScreen.

class _HistoryTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool isLoading;

  const _HistoryTab({this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    final matches = _matches(data);
    final perMatch = _perMatchStats(data);

    if (matches.isEmpty) {
      return Center(
          child: Text('No match history found',
              style: AppTheme.inter(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: matches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              'MATCH HISTORY (${matches.length})',
              style: AppTheme.krona(size: 20, color: Colors.white),
            ),
          );
        }

        final i = index - 1;
        final m = matches[i];
        final pms = (i < perMatch.length) ? perMatch[i] : <String, dynamic>{};

        final meta = m['match_metadata'] as Map<String, dynamic>? ?? {};
        final combat = m['combat_stats'] as Map<String, dynamic>? ?? {};
        final agentAbilities = m['agent_and_abilities'] as Map<String, dynamic>? ?? {};

        final isWin = meta['won'] == true;
        final resultColor = isWin ? const Color(0xFF0FB5AE) : const Color(0xFFF53D4C);
        final resultLabel = isWin ? 'VICTORY' : 'DEFEAT';

        final mapName = meta['map_name']?.toString() ?? 'Unknown';
        final agentName = agentAbilities['agent_name']?.toString() ?? 'Unknown';
        final kills = _int(combat['kills']);
        final deaths = _int(combat['deaths']);
        final assists = _int(combat['assists']);
        final acs = _num(combat['acs']);
        final roundsWon = _int(pms['rounds_won']);
        final roundsLost = _int(pms['rounds_lost']);
        final startedAt = meta['started_at']?.toString() ?? '';
        final matchId = m['match_id']?.toString() ?? '';

        return GestureDetector(
          onTap: () {
            if (matchId.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(
                  match: m,
                  perMatchStats: pms,
                  matchId: matchId,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                        color: resultColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(mapName.toUpperCase(),
                        style: AppTheme.krona(size: 14, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(agentName,
                        style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$resultLabel  $roundsWon - $roundsLost',
                      style: AppTheme.krona(size: 10, color: resultColor)),
                  if (startedAt.isNotEmpty)
                    Text(startedAt,
                        style: AppTheme.inter(size: 9, color: AppTheme.textMuted)),
                ]),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _MatchStat('K/D/A', '$kills/$deaths/$assists'),
                const SizedBox(width: 24),
                _MatchStat('ACS', acs.toStringAsFixed(0), color: const Color(0xFF0FB5AE)),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _MatchStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MatchStat(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTheme.inter(size: 8, color: AppTheme.textMuted, weight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(value, style: AppTheme.krona(size: 12, color: color ?? Colors.white)),
    ]);
  }
}
