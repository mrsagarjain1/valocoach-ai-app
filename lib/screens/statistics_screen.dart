import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import 'ai_analysis_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _agentAsset(String agent) {
  final clean = agent.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return 'assets/agents/$clean.png';
}

String _rankAsset(String rank) {
  final r = rank.toLowerCase();
  if (r.contains('radiant')) return 'assets/ranks/radiant_rank.png';
  final m = RegExp(r'^(\w+)\s+(\d+)').firstMatch(rank);
  if (m != null) {
    return 'assets/ranks/${m.group(1)!.toLowerCase()}_${m.group(2)}_rank.png';
  }
  return 'assets/ranks/unranked_rank.png';
}

String _mapAsset(String map) {
  final clean = map.toLowerCase().replaceAll(' ', '');
  return 'assets/maps/$clean.jpg';
}

Color _kdColor(dynamic kd) {
  final v = double.tryParse(kd?.toString() ?? '0') ?? 0;
  if (v >= 1.2) return AppTheme.accentGreen;
  if (v >= 0.9) return AppTheme.accentYellow;
  return AppTheme.primaryRed;
}

String _fmt(dynamic v, {int decimals = 1, String suffix = ''}) {
  if (v == null) return '-';
  final d = double.tryParse(v.toString());
  if (d == null) return '-';
  return '${d.toStringAsFixed(decimals)}$suffix';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStatsProvider);

    if (state.isLoading) return const _Skeleton();
    if (state.error != null) return _ErrorView(state: state, ref: ref);
    if (state.data == null) return const _EmptyView();
    return _StatsBody(data: state.data!);
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Shimmer.fromColors(
        baseColor: AppTheme.shimmerBase,
        highlightColor: AppTheme.shimmerHighlight,
        child: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
            ]),
            const SizedBox(height: 20),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
            )),
          ]),
        )),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final PlayerStatsState state;
  final WidgetRef ref;
  const _ErrorView({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 20),
          Text('PLAYER NOT FOUND', style: AppTheme.krona(size: 18)),
          const SizedBox(height: 8),
          Text(state.error ?? '', textAlign: TextAlign.center, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              if (state.searchedName != null) {
                ref.read(playerStatsProvider.notifier).searchPlayer(state.searchedName!, state.searchedTag!);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: Text('RETRY', style: AppTheme.krona(size: 12, letterSpacing: 1.5)),
            ),
          ),
        ]),
      ))),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.person_search_rounded, size: 72, color: AppTheme.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: 20),
        Text('SEARCH A PLAYER', style: AppTheme.krona(size: 18)),
        const SizedBox(height: 6),
        Text('Go to Home and enter a player name', style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
      ]))),
    );
  }
}

// ─── Main Stats Body ──────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final name       = (data['name'] ?? '').toString();
    final tag        = (data['tag'] ?? '').toString();
    final rank       = (data['current_rank'] ?? 'Unranked').toString();
    final peakRank   = (data['peak_rank'] ?? 'Unranked').toString();
    final topAgent   = (data['top_agent'] ?? '').toString();
    final bestMap    = (data['best_map'] ?? '').toString();
    final worstMap   = (data['worst_map'] ?? '').toString();
    final kd         = _fmt(data['overall_kd_ratio'], decimals: 2);
    final winRate    = _fmt(data['overall_win_percent'], suffix: '%');
    final hs         = _fmt(data['overall_headshot_percentage'], suffix: '%');
    final acs        = _fmt(data['overall_ACS'], decimals: 0);
    final matches    = data['matches'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Player Hero Card ─────────────────────────
              _PlayerHero(
                name: name,
                tag: tag,
                rank: rank,
                peakRank: peakRank,
                topAgent: topAgent,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── Stats Grid ───────────────────────
                    _SectionLabel('PERFORMANCE'),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _StatCard(label: 'K/D RATIO', value: kd, color: _kdColor(data['overall_kd_ratio']))),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'WIN RATE', value: winRate, color: AppTheme.accentBlue)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _StatCard(label: 'HEADSHOT %', value: hs, color: AppTheme.accentYellow)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'AVG ACS', value: acs, color: AppTheme.accentGreen)),
                    ]),

                    const SizedBox(height: 10),

                    // Maps info row
                    if (bestMap.isNotEmpty || worstMap.isNotEmpty)
                      Row(children: [
                        if (bestMap.isNotEmpty) Expanded(child: _MapChip(label: 'BEST MAP', map: bestMap, color: AppTheme.accentGreen)),
                        if (bestMap.isNotEmpty && worstMap.isNotEmpty) const SizedBox(width: 10),
                        if (worstMap.isNotEmpty) Expanded(child: _MapChip(label: 'WORST MAP', map: worstMap, color: AppTheme.primaryRed)),
                      ]),

                    const SizedBox(height: 24),

                    // ── AI Coach CTA ─────────────────────
                    _AiCta(name: name, tag: tag),

                    const SizedBox(height: 28),

                    // ── Match History ────────────────────
                    _SectionLabel('RECENT MATCHES'),
                    const SizedBox(height: 10),

                    if (matches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No matches available', style: AppTheme.inter(color: AppTheme.textMuted)),
                        ),
                      )
                    else
                      ...matches.take(10).map((m) => _MatchCard(match: m as Map<String, dynamic>, rank: rank)),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Player Hero Card ─────────────────────────────────────────────────────────

class _PlayerHero extends StatelessWidget {
  final String name, tag, rank, peakRank, topAgent;
  const _PlayerHero({required this.name, required this.tag, required this.rank, required this.peakRank, required this.topAgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      color: const Color(0xFF120010),
      child: Stack(
        children: [
          // Map/gradient bg
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E0016), Color(0xFF1A001A), Color(0xFF120010)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Subtle grid
          Positioned.fill(child: CustomPaint(painter: _HeroGridPainter())),

          // Agent cutout — large, right side
          if (topAgent.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 0,
              top: -10,
              child: Image.asset(
                _agentAsset(topAgent),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 120),
              ),
            ),

          // Left red accent bar
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.primaryRed.withValues(alpha: 0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 160, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank Image + name
                Row(children: [
                  Image.asset(_rankAsset(rank), width: 44, height: 44,
                    errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, color: AppTheme.accentYellow, size: 36),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name.toUpperCase(), style: AppTheme.krona(size: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('#$tag', style: AppTheme.inter(size: 12, color: AppTheme.textMuted, weight: FontWeight.w500)),
                    ]),
                  ),
                ]),
                const Spacer(),
                // Rank chips
                Row(children: [
                  _RankBadge(label: 'CURRENT', value: rank, color: AppTheme.primaryRed),
                  const SizedBox(width: 8),
                  _RankBadge(label: 'PEAK', value: peakRank, color: AppTheme.accentYellow),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.025)..strokeWidth = 0.5;
    const s = 36.0;
    for (double x = 0; x < size.width; x += s) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += s) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(_) => false;
}

class _RankBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RankBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.inter(size: 8, color: color, weight: FontWeight.w700, letterSpacing: 1)),
        Text(value, style: AppTheme.inter(size: 11, weight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Text(value, style: AppTheme.krona(size: 30, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Container(width: 5, height: 5, margin: const EdgeInsets.only(bottom: 5), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ]),
      ]),
    );
  }
}

// ─── Map Chip ─────────────────────────────────────────────────────────────────

class _MapChip extends StatelessWidget {
  final String label, map;
  final Color color;
  const _MapChip({required this.label, required this.map, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Stack(children: [
        // blurred map bg
        Positioned.fill(child: Image.asset(
          _mapAsset(map), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(),
        )),
        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.62))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: AppTheme.inter(size: 9, color: color, weight: FontWeight.w700, letterSpacing: 1)),
            Text(map.toUpperCase(), style: AppTheme.krona(size: 11)),
          ]),
        ),
      ]),
    );
  }
}

// ─── AI CTA ───────────────────────────────────────────────────────────────────

class _AiCta extends ConsumerWidget {
  final String name, tag;
  const _AiCta({required this.name, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AiAnalysisScreen(playerName: name, playerTag: tag),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0828), Color(0xFF28106A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB78BFA), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI COACH ANALYSIS', style: AppTheme.krona(size: 12, color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(
              auth.isClerkSignedIn ? 'Tap to get personalized coaching tips' : 'Sign in for personalized analysis',
              style: AppTheme.inter(size: 11, color: Colors.white60),
            ),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('ANALYZE', style: AppTheme.krona(size: 9, color: Colors.white, letterSpacing: 1)),
          ),
        ]),
      ),
    );
  }
}

// ─── Match Card ───────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String rank;
  const _MatchCard({required this.match, required this.rank});

  @override
  Widget build(BuildContext context) {
    final agent   = (match['agent'] ?? '').toString();
    final mapName = (match['map'] ?? '').toString();
    final result  = (match['result'] ?? '').toString().toLowerCase();
    final kills   = match['kills'] ?? 0;
    final deaths  = match['deaths'] ?? 0;
    final assists = match['assists'] ?? 0;
    final team    = (match['team'] ?? '').toString().toLowerCase();
    final teams   = match['teams'] as Map<String, dynamic>?;

    int myScore = 0, enemyScore = 0;
    if (teams != null && team.isNotEmpty) {
      final isBlue = team == 'blue';
      myScore    = ((isBlue ? teams['blue'] : teams['red']) ?? 0) as int;
      enemyScore = ((isBlue ? teams['red'] : teams['blue']) ?? 0) as int;
    }

    final isWin  = result == 'won' || result == 'win' || result == 'victory';
    final isDraw = result == 'draw' || result == 'tied';
    final accent = isDraw ? AppTheme.accentYellow : isWin ? AppTheme.accentGreen : AppTheme.primaryRed;
    final tag    = isDraw ? 'DRAW' : isWin ? 'WIN' : 'LOSS';

    final k = (kills is num ? kills.toInt() : int.tryParse(kills.toString()) ?? 0);
    final d = (deaths is num ? deaths.toInt() : int.tryParse(deaths.toString()) ?? 0);
    final a = (assists is num ? assists.toInt() : int.tryParse(assists.toString()) ?? 0);
    final kd = d > 0 ? (k / d).toStringAsFixed(2) : k.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(children: [
          // Map thumbnail bg
          Positioned.fill(right: null,
            child: SizedBox(
              width: 80,
              child: Stack(children: [
                Image.asset(_mapAsset(mapName), width: 80, height: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceDark),
                ),
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, AppTheme.cardBg],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                )),
              ]),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              // Agent image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 46, height: 46,
                  child: Image.asset(_agentAsset(agent), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceDark,
                      child: const Icon(Icons.person_rounded, color: AppTheme.textMuted, size: 26),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Agent + map
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(agent.isEmpty ? 'Unknown' : agent, style: AppTheme.inter(size: 13, weight: FontWeight.w700)),
                Text(mapName, style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
              ])),

              // Score + result tag
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$myScore : $enemyScore', style: AppTheme.krona(size: 15, color: accent)),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(tag, style: AppTheme.inter(size: 9, color: accent, weight: FontWeight.w700)),
                ),
              ]),

              const SizedBox(width: 14),

              // KDA
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$k / $d / $a', style: AppTheme.inter(size: 12, color: AppTheme.textSecondary, weight: FontWeight.w600)),
                Text('K/D $kd', style: AppTheme.inter(size: 10, color: AppTheme.textMuted)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 2));
  }
}
