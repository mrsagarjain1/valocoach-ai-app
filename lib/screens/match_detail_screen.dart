import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'per_match_analysis_screen.dart';
import 'replay/replay_tab.dart';

/// Opened when the user taps a match in the HISTORY tab.
/// 4 tabs: MATCH overview, ROUNDS, AI Analysis, 2D REPLAY
class MatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  final Map<String, dynamic> perMatchStats;
  final String matchId;

  const MatchDetailScreen({
    super.key,
    required this.match,
    required this.perMatchStats,
    required this.matchId,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedRoundIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.match['match_metadata'] as Map<String, dynamic>? ?? {};
    final isWin = meta['won'] == true;
    final resultColor = isWin ? const Color(0xFF16C47F) : const Color(0xFFF53D4C);
    final mapName = meta['map_name']?.toString() ?? 'Unknown';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(mapName.toUpperCase(), style: AppTheme.krona(size: 14, color: Colors.white)),
          Text(isWin ? 'VICTORY' : 'DEFEAT',
              style: AppTheme.inter(size: 10, color: resultColor, weight: FontWeight.w700)),
        ]),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                  Tab(text: 'AI'),
                  Tab(text: 'REPLAY'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _MatchOverviewTab(match: widget.match, perMatchStats: widget.perMatchStats),
                _RoundsTabContent(
                  perMatchStats: widget.perMatchStats,
                  selectedRoundIndex: _selectedRoundIndex,
                  onRoundSelect: (i) => setState(() => _selectedRoundIndex = i),
                ),
                PerMatchAnalysisBody(matchId: widget.matchId),
                ReplayTab(matchId: widget.matchId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

double _num(dynamic v, [double def = 0]) {
  if (v == null) return def;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? def;
}

int _int(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? def;
}

// ─── Match Overview Tab ────────────────────────────────────────────────────────

class _MatchOverviewTab extends StatelessWidget {
  final Map<String, dynamic> match;
  final Map<String, dynamic> perMatchStats;
  const _MatchOverviewTab({required this.match, required this.perMatchStats});

  @override
  Widget build(BuildContext context) {
    final meta = match['match_metadata'] as Map<String, dynamic>? ?? {};
    final combat = match['combat_stats'] as Map<String, dynamic>? ?? {};
    final agentData = match['agent_and_abilities'] as Map<String, dynamic>? ?? {};
    final econ = match['economy_stats'] as Map<String, dynamic>? ?? {};
    final behavioral = match['behavioral_data'] as Map<String, dynamic>? ?? {};
    final teamParty = match['team_and_party'] as Map<String, dynamic>? ?? {};
    final matchStats = perMatchStats['match_stats'] as Map<String, dynamic>? ?? {};

    final isWin = meta['won'] == true;
    final accentColor = isWin ? const Color(0xFF16C47F) : const Color(0xFFF53D4C);
    final mapName = meta['map_name']?.toString() ?? 'Unknown';
    final agentName = agentData['agent_name']?.toString() ?? 'Unknown';
    final queueName = meta['queue_name']?.toString() ?? meta['mode']?.toString() ?? 'Competitive';
    final startedAt = meta['started_at']?.toString() ?? '';
    final roundsWon = _int(perMatchStats['rounds_won']);
    final roundsLost = _int(perMatchStats['rounds_lost']);
    final totalRounds = _int(perMatchStats['total_rounds']);
    final partySize = _int(teamParty['party_size'], 1);
    final partyMembers = teamParty['party_members'] as List? ?? [];

    // Weapon kills
    final weaponKills = matchStats['weapon_kills'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Hero Header ──────────────────────────────────────────────────
        _MatchHeader(
          mapName: mapName,
          agentName: agentName,
          queueName: queueName,
          startedAt: startedAt,
          isWin: isWin,
          accentColor: accentColor,
          roundsWon: roundsWon,
          roundsLost: roundsLost,
        ),
        const SizedBox(height: 20),

        // ── Section: Combat Stats ────────────────────────────────────────
        _SectionLabel('COMBAT STATS', accentColor),
        const SizedBox(height: 12),
        _BigStatRow(items: [
          _BigStat('KILLS', _int(combat['kills']).toString(), const Color(0xFF16C47F)),
          _BigStat('DEATHS', _int(combat['deaths']).toString(), const Color(0xFFF53D4C)),
          _BigStat('ASSISTS', _int(combat['assists']).toString(), const Color(0xFF60A5FA)),
        ]),
        const SizedBox(height: 10),
        _BigStatRow(items: [
          _BigStat('ACS', _num(combat['acs']).toStringAsFixed(0), const Color(0xFF06B6D4)),
          _BigStat('HS %', '${_num(combat['headshot_percentage']).toStringAsFixed(1)}%', const Color(0xFFFBBF24)),
          _BigStat('SCORE', _int(combat['score']).toString(), Colors.white),
        ]),
        const SizedBox(height: 20),

        // ── Section: Performance Stats ───────────────────────────────────
        _SectionLabel('PERFORMANCE', AppTheme.accentYellow),
        const SizedBox(height: 12),
        _StatGrid(items: [
          _StatItem('ROUNDS WON', '$roundsWon/$totalRounds', const Color(0xFF16C47F)),
          _StatItem('DMG/ROUND', _num(matchStats['damage_per_round']).toStringAsFixed(1), const Color(0xFF06B6D4)),
          _StatItem('TRADE RATIO', _num(matchStats['damage_trade_ratio']).toStringAsFixed(2), const Color(0xFFF97316)),
          _StatItem('ECON EFF.', '${_num(matchStats['economy_efficiency_pct']).toStringAsFixed(1)}%', const Color(0xFFA855F7)),
          _StatItem('AVG SPENT', '\$${_num(econ['spent_average']).toStringAsFixed(0)}', const Color(0xFFFBBF24)),
          _StatItem('AVG LOADOUT', '\$${_num(econ['loadout_value_average']).toStringAsFixed(0)}', const Color(0xFF0FB5AE)),
        ]),
        const SizedBox(height: 20),

        // ── Section: Round Events ────────────────────────────────────────
        _SectionLabel('ROUND EVENTS', const Color(0xFF16C47F)),
        const SizedBox(height: 12),
        _StatGrid(items: [
          _StatItem('FIRST BLOODS', _int(matchStats['first_blood_count']).toString(), const Color(0xFF16C47F)),
          _StatItem('FIRST DEATHS', _int(matchStats['first_death_count']).toString(), const Color(0xFFF53D4C)),
          _StatItem('MULTI KILLS', _int(matchStats['multikill_count']).toString(), const Color(0xFFFBBF24)),
          _StatItem('ACES', _int(matchStats['ace_count']).toString(), const Color(0xFFFBBF24)),
          _StatItem('CLUTCHES', _int(matchStats['clutch_situations_won']).toString(), const Color(0xFFA855F7)),
          _StatItem('PLANTS', _int(matchStats['plants_count']).toString(), const Color(0xFF3B82F6)),
          _StatItem('DEFUSES', _int(matchStats['defuses_count']).toString(), const Color(0xFF8B5CF6)),
        ]),
        const SizedBox(height: 20),

        // ── Section: Side Performance ────────────────────────────────────
        _SectionLabel('SIDE PERFORMANCE', const Color(0xFFF97316)),
        const SizedBox(height: 12),
        _StatGrid(items: [
          _StatItem('ATK WON', '${_int(matchStats['attack_rounds_won'])}/${_int(matchStats['total_attack_rounds'])}', const Color(0xFFF53D4C)),
          _StatItem('ATK WIN %', '${_num(matchStats['attack_win_rate']).toStringAsFixed(1)}%', const Color(0xFFF53D4C)),
          _StatItem('DEF WON', '${_int(matchStats['defense_rounds_won'])}/${_int(matchStats['total_defense_rounds'])}', const Color(0xFF0FB5AE)),
          _StatItem('DEF WIN %', '${_num(matchStats['defense_win_rate']).toStringAsFixed(1)}%', const Color(0xFF0FB5AE)),
          _StatItem('PARTY SIZE', '$partySize ${partySize == 1 ? 'Solo' : 'Stack'}', partySize > 1 ? const Color(0xFF16C47F) : const Color(0xFFFBBF24)),
        ]),
        if (partySize > 1 && partyMembers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final m in partyMembers)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${m['name'] ?? ''}#${m['tag'] ?? ''}',
                  style: AppTheme.inter(size: 10, color: const Color(0xFF60A5FA), weight: FontWeight.w700),
                ),
              ),
          ]),
        ],
        const SizedBox(height: 20),

        // ── Section: Shot Distribution ───────────────────────────────────
        _SectionLabel('SHOT DISTRIBUTION', const Color(0xFF06B6D4)),
        const SizedBox(height: 12),
        _StatGrid(items: [
          _StatItem('HEADSHOTS', _int(combat['headshots']).toString(), const Color(0xFF16C47F)),
          _StatItem('BODYSHOTS', _int(combat['bodyshots']).toString(), const Color(0xFFFBBF24)),
          _StatItem('LEGSHOTS', _int(combat['legshots']).toString(), const Color(0xFF9CA3AF)),
        ]),
        if (weaponKills.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionLabel('WEAPON KILLS', const Color(0xFFFBBF24)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final entry in weaponKills.entries)
              _WeaponChip(entry.key, entry.value?.toString() ?? '0'),
          ]),
        ],
        const SizedBox(height: 20),

        // ── Section: Agent Abilities ─────────────────────────────────────
        _SectionLabel('AGENT ABILITIES', const Color(0xFF8B5CF6)),
        const SizedBox(height: 12),
        _StatGrid(items: [
          _StatItem('ABILITY 1 (Q)', _int(agentData['ability1_casts']).toString(), const Color(0xFF60A5FA)),
          _StatItem('ABILITY 2 (E)', _int(agentData['ability2_casts']).toString(), const Color(0xFF8B5CF6)),
          _StatItem('ABILITY 3 (C)', _int(agentData['grenade_casts']).toString(), const Color(0xFF16C47F)),
          _StatItem('ULTIMATE (X)', _int(agentData['ultimate_casts']).toString(), const Color(0xFFFBBF24)),
        ]),
        const SizedBox(height: 20),

        // ── Section: Behavioral Data ─────────────────────────────────────
        _SectionLabel('BEHAVIORAL DATA', const Color(0xFF9CA3AF)),
        const SizedBox(height: 12),
        _StatGrid(items: [
          _StatItem('FF INCOMING', _int(behavioral['friendly_fire_incoming']).toString(),
              _int(behavioral['friendly_fire_incoming']) > 0 ? const Color(0xFFF53D4C) : const Color(0xFF16C47F)),
          _StatItem('FF OUTGOING', _int(behavioral['friendly_fire_outgoing']).toString(),
              _int(behavioral['friendly_fire_outgoing']) > 0 ? const Color(0xFFF53D4C) : const Color(0xFF16C47F)),
          _StatItem('AFK ROUNDS', _int(behavioral['afk_rounds']).toString(),
              _int(behavioral['afk_rounds']) > 0 ? const Color(0xFFF53D4C) : const Color(0xFF16C47F)),
          _StatItem('SPAWN IDLE', _int(behavioral['rounds_in_spawn']).toString(),
              _int(behavioral['rounds_in_spawn']) > 0 ? const Color(0xFFF53D4C) : const Color(0xFF16C47F)),
        ]),
        const SizedBox(height: 60),
      ],
    );
  }
}

// ─── Match Header ──────────────────────────────────────────────────────────────

String _mapAssetPath(String mapName) {
  final key = mapName.toLowerCase().trim();
  const knownMaps = {
    'ascent', 'bind', 'haven', 'split', 'fracture', 'breeze',
    'icebox', 'pearl', 'lotus', 'sunset', 'abyss', 'corrode',
    'district', 'drift', 'glitch', 'kasbah', 'piazza',
  };
  return knownMaps.contains(key)
      ? 'assets/maps/$key.jpg'
      : 'assets/maps/unknown_map.jpg';
}

String _agentAssetPath(String agentName) {
  final key = agentName.toLowerCase().trim();
  return 'assets/agents/$key.png';
}

class _MatchHeader extends StatelessWidget {
  final String mapName, agentName, queueName, startedAt;
  final bool isWin;
  final Color accentColor;
  final int roundsWon, roundsLost;

  const _MatchHeader({
    required this.mapName,
    required this.agentName,
    required this.queueName,
    required this.startedAt,
    required this.isWin,
    required this.accentColor,
    required this.roundsWon,
    required this.roundsLost,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // ── Map background image ──────────────────────────────
            Positioned.fill(
              child: Image.asset(
                _mapAssetPath(mapName),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1C0014)),
              ),
            ),

            // ── Dark gradient overlay ─────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.80),
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // ── Accent-colour glow at bottom edge ────────────────
            Positioned(
              left: 0, right: 0, bottom: 0, height: 3,
              child: Container(color: accentColor.withValues(alpha: 0.8)),
            ),

            // ── Agent art (right side, faded) ────────────────────
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140,
              child: ShaderMask(
                shaderCallback: (Rect bounds) => const LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.0, 0.45],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    _agentAssetPath(agentName),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),

            // ── Content overlay ───────────────────────────────────
            Container(
              constraints: const BoxConstraints(minHeight: 200),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top: Map name + WIN/LOSS badge on LEFT, nothing on right (agent art is right)
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      mapName.toUpperCase(),
                      style: AppTheme.krona(size: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      // WIN / LOSS badge — stays LEFT, away from agent art
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.25), blurRadius: 10)],
                        ),
                        child: Text(
                          isWin ? 'VICTORY' : 'DEFEAT',
                          style: AppTheme.krona(size: 10, color: accentColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        queueName,
                        style: AppTheme.inter(size: 11, color: Colors.white54),
                      ),
                    ]),
                  ]),

                  // Bottom row: agent pill (left) + score (left, not pushed to right into agent)
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Score — on the LEFT so it never collides with agent art
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          Text(
                            '$roundsWon',
                            style: AppTheme.krona(size: 42, color: isWin ? const Color(0xFF16C47F) : const Color(0xFFF53D4C)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text(':', style: AppTheme.krona(size: 32, color: Colors.white38)),
                          ),
                          Text(
                            '$roundsLost',
                            style: AppTheme.krona(size: 42, color: isWin ? const Color(0xFFF53D4C) : const Color(0xFF16C47F)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      // Agent pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          agentName,
                          style: AppTheme.inter(size: 11, color: Colors.white, weight: FontWeight.w700),
                        ),
                      ),
                      if (startedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          startedAt,
                          style: AppTheme.inter(size: 9, color: Colors.white38),
                        ),
                      ],
                    ]),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared UI Components ──────────────────────────────────────────────────────

Widget _SectionLabel(String label, Color color) {
  return Builder(builder: (_) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: AppTheme.inter(size: 10, color: color, weight: FontWeight.w800, letterSpacing: 1.5)),
  ]));
}

class _BigStatRow extends StatelessWidget {
  final List<_BigStat> items;
  const _BigStatRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((s) => Expanded(child: _BigStatCard(s))).toList(),
    );
  }
}

class _BigStat {
  final String label, value;
  final Color color;
  const _BigStat(this.label, this.value, this.color);
}

class _BigStatCard extends StatelessWidget {
  final _BigStat stat;
  const _BigStatCard(this.stat);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stat.color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stat.label,
            style: AppTheme.inter(size: 8, color: AppTheme.textMuted, weight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(stat.value, style: AppTheme.krona(size: 28, color: stat.color), maxLines: 1),
        ),
      ]),
    );
  }
}

class _StatItem {
  final String label, value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}

class _StatGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.55,
      children: items.map((s) => _StatGridCard(s)).toList(),
    );
  }
}

class _StatGridCard extends StatelessWidget {
  final _StatItem stat;
  const _StatGridCard(this.stat);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stat.color.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(stat.label,
            style: AppTheme.inter(size: 7, color: AppTheme.textMuted, weight: FontWeight.w700, letterSpacing: 0.3),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(stat.value,
              style: AppTheme.krona(size: 17, color: stat.color),
              maxLines: 1),
        ),
      ]),
    );
  }
}

class _WeaponChip extends StatelessWidget {
  final String weapon, kills;
  const _WeaponChip(this.weapon, this.kills);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.28)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(weapon.toUpperCase(), style: AppTheme.inter(size: 10, color: const Color(0xFFFBBF24), weight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text(kills, style: AppTheme.krona(size: 13, color: Colors.white)),
      ]),
    );
  }
}

// ─── Rounds Tab Content ────────────────────────────────────────────────────────

class _RoundsTabContent extends StatefulWidget {
  final Map<String, dynamic> perMatchStats;
  final int selectedRoundIndex;
  final Function(int) onRoundSelect;

  const _RoundsTabContent({
    required this.perMatchStats,
    required this.selectedRoundIndex,
    required this.onRoundSelect,
  });

  @override
  State<_RoundsTabContent> createState() => _RoundsTabContentState();
}

class _RoundsTabContentState extends State<_RoundsTabContent> {
  String _filterResult = 'All';
  String _filterSide = 'All';
  String _filterEvent = 'All';

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget _filterChip(String label, String value, String current, Function(String) onSelect) {
              final isSelected = value == current;
              return GestureDetector(
                onTap: () {
                  setModalState(() => onSelect(value));
                  setState(() => onSelect(value));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryRed : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppTheme.primaryRed : AppTheme.borderColor),
                  ),
                  child: Text(label, style: AppTheme.inter(size: 11, color: isSelected ? Colors.white : AppTheme.textMuted, weight: FontWeight.w600)),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FILTER ROUNDS', style: AppTheme.krona(size: 14, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('RESULT', style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _filterChip('ALL', 'All', _filterResult, (v) => _filterResult = v),
                    _filterChip('WON', 'Won', _filterResult, (v) => _filterResult = v),
                    _filterChip('LOST', 'Lost', _filterResult, (v) => _filterResult = v),
                  ]),
                  const SizedBox(height: 20),
                  Text('SIDE', style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _filterChip('ALL', 'All', _filterSide, (v) => _filterSide = v),
                    _filterChip('ATTACK', 'Attack', _filterSide, (v) => _filterSide = v),
                    _filterChip('DEFENSE', 'Defense', _filterSide, (v) => _filterSide = v),
                  ]),
                  const SizedBox(height: 20),
                  Text('KEY EVENTS', style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _filterChip('ALL', 'All', _filterEvent, (v) => _filterEvent = v),
                    _filterChip('FIRST BLOOD', 'First Blood', _filterEvent, (v) => _filterEvent = v),
                    _filterChip('FIRST DEATH', 'First Death', _filterEvent, (v) => _filterEvent = v),
                    _filterChip('CLUTCH', 'Clutch', _filterEvent, (v) => _filterEvent = v),
                    _filterChip('ACE', 'Ace', _filterEvent, (v) => _filterEvent = v),
                    _filterChip('PLANTED', 'Planted', _filterEvent, (v) => _filterEvent = v),
                    _filterChip('DEFUSED', 'Defused', _filterEvent, (v) => _filterEvent = v),
                  ]),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('APPLY FILTERS', style: AppTheme.krona(size: 12, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rounds = (widget.perMatchStats['per_round_details'] as List? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    if (rounds.isEmpty) {
      return Center(
        child: Text("Round details aren't available for this match.",
            style: AppTheme.inter(color: AppTheme.textMuted), textAlign: TextAlign.center),
      );
    }

    final filteredRounds = rounds.where((r) {
      final won = r['round_result']?.toString().toLowerCase() == 'won';
      final side = r['player_side']?.toString().toLowerCase() ?? '';
      final fb = r['got_first_blood'] == true;
      final fd = r['got_first_death'] == true;
      final clutch = r['was_clutch'] == true;
      final ace = r['was_ace'] == true;
      final plant = r['planted'] == true;
      final defuse = r['defused'] == true;

      if (_filterResult == 'Won' && !won) return false;
      if (_filterResult == 'Lost' && won) return false;
      if (_filterSide == 'Attack' && side != 'attack') return false;
      if (_filterSide == 'Defense' && side != 'defense') return false;

      if (_filterEvent == 'First Blood' && !fb) return false;
      if (_filterEvent == 'First Death' && !fd) return false;
      if (_filterEvent == 'Clutch' && !clutch) return false;
      if (_filterEvent == 'Ace' && !ace) return false;
      if (_filterEvent == 'Planted' && !plant) return false;
      if (_filterEvent == 'Defused' && !defuse) return false;

      return true;
    }).toList();

    final winsCount = filteredRounds.where((r) => r['round_result']?.toString().toLowerCase() == 'won').length;
    final lossCount = filteredRounds.length - winsCount;

    final selectedRound = widget.selectedRoundIndex < rounds.length ? rounds[widget.selectedRoundIndex] : rounds.first;

    // Determine first and second half based on the original global index
    final firstHalf = filteredRounds.where((r) => rounds.indexOf(r) < 12).toList();
    final secondHalf = filteredRounds.where((r) => rounds.indexOf(r) >= 12).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(children: [
          Text('ROUND SELECT', style: AppTheme.krona(size: 14, color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
            padding: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(),
            onPressed: () => _showFilterSheet(context),
          ),
          const Spacer(),
          _PillBadge('${winsCount}W', const Color(0xFF0FB5AE)),
          const SizedBox(width: 6),
          _PillBadge('${lossCount}L', const Color(0xFFF53D4C)),
        ]),
        const SizedBox(height: 16),

        _HalfLabel('FIRST HALF', firstHalf),
        const SizedBox(height: 10),
        _RoundGrid(rounds: firstHalf, allRounds: rounds, selectedIndex: widget.selectedRoundIndex, onSelect: widget.onRoundSelect),
        if (secondHalf.isNotEmpty) ...[
          const SizedBox(height: 20),
          _HalfLabel('SECOND HALF', secondHalf),
          const SizedBox(height: 10),
          _RoundGrid(rounds: secondHalf, allRounds: rounds, selectedIndex: widget.selectedRoundIndex, onSelect: widget.onRoundSelect),
        ],
        const SizedBox(height: 28),

        Row(children: [
          Text('ROUND REPORT', style: AppTheme.krona(size: 12, color: AppTheme.primaryRed, letterSpacing: 1.5)),
          const SizedBox(width: 10),
          Text('Round ${widget.selectedRoundIndex + 1}',
              style: AppTheme.inter(size: 12, color: AppTheme.textMuted, weight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        _RoundReport(round: selectedRound, roundNumber: widget.selectedRoundIndex + 1),
        const SizedBox(height: 60),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.inter(size: 10, color: color, weight: FontWeight.bold)),
      ]),
    );
  }
}

Widget _HalfLabel(String label, List<Map<String, dynamic>> half) {
  if (half.isEmpty) return const SizedBox.shrink();
  final wins = half.where((r) => r['round_result']?.toString().toLowerCase() == 'won').length;
  final losses = half.length - wins;
  return Builder(builder: (_) => Row(children: [
    Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF6B7280))),
    const Spacer(),
    _PillBadge('${wins}W', const Color(0xFF0FB5AE)),
    const SizedBox(width: 6),
    _PillBadge('${losses}L', const Color(0xFFF53D4C)),
  ]));
}

class _RoundGrid extends StatelessWidget {
  final List<Map<String, dynamic>> rounds;
  final List<Map<String, dynamic>> allRounds;
  final int selectedIndex;
  final Function(int) onSelect;

  const _RoundGrid({required this.rounds, required this.allRounds, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (int ri = 0; ri < rounds.length; ri++)
        Builder(builder: (_) {
          final round = rounds[ri];
          final globalIndex = allRounds.indexOf(round);
          final displayNum = globalIndex + 1;
          final isSelected = globalIndex == selectedIndex;
          final won = round['round_result']?.toString().toLowerCase() == 'won';
          final hasFirstBlood = round['got_first_blood'] == true;

          final borderColor = won ? const Color(0xFF0FB5AE) : const Color(0xFFF53D4C);
          final bgColor = isSelected
              ? (won ? const Color(0xFF0FB5AE) : const Color(0xFFF53D4C))
              : (won ? const Color(0xFF0FB5AE).withValues(alpha: 0.08) : const Color(0xFFF53D4C).withValues(alpha: 0.08));

          return GestureDetector(
            onTap: () => globalIndex >= 0 ? onSelect(globalIndex) : null,
            child: Stack(children: [
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor.withValues(alpha: isSelected ? 1.0 : 0.5), width: isSelected ? 2 : 1),
                ),
                child: Text('$displayNum',
                    style: TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : borderColor)),
              ),
              if (hasFirstBlood)
                Positioned(top: 3, right: 3, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle))),
            ]),
          );
        }),
    ]);
  }
}

class _RoundReport extends StatelessWidget {
  final Map<String, dynamic> round;
  final int roundNumber;
  const _RoundReport({required this.round, required this.roundNumber});

  @override
  Widget build(BuildContext context) {
    final won = round['round_result']?.toString().toLowerCase() == 'won';
    final isAttack = round['player_side']?.toString().toLowerCase() == 'attack';
    final kills = _int(round['kills']);
    final deaths = _int(round['deaths']);
    final damageDealt = _num(round['damage_dealt']);
    final loadoutValue = _num(round['loadout_value']);
    final econEfficiency = _num(round['economy_efficiency']);
    final gotFirstBlood = round['got_first_blood'] == true;
    final gotFirstDeath = round['got_first_death'] == true;
    final wasClutch = round['was_clutch'] == true;
    final wasAce = round['was_ace'] == true;
    final planted = round['planted'] == true;
    final defused = round['defused'] == true;
    final weaponName = round['weapon_name']?.toString() ?? '';

    final accentColor = won ? const Color(0xFF0FB5AE) : const Color(0xFFF53D4C);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(17), topRight: Radius.circular(17)),
          ),
          child: Row(children: [
            Text('ROUND $roundNumber', style: AppTheme.krona(size: 14, color: Colors.white)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAttack ? AppTheme.primaryRed.withValues(alpha: 0.15) : const Color(0xFF0FB5AE).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(isAttack ? 'ATTACK' : 'DEFENSE',
                  style: AppTheme.krona(size: 8, color: isAttack ? AppTheme.primaryRed : const Color(0xFF0FB5AE))),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(6)),
              child: Text(won ? 'WIN' : 'LOSS', style: AppTheme.krona(size: 9, color: Colors.white, letterSpacing: 0.5)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(children: [
              Expanded(child: _RoundStat('KILLS', kills.toString(), const Color(0xFF16C47F))),
              Expanded(child: _RoundStat('DEATHS', deaths.toString(), const Color(0xFFF53D4C))),
              Expanded(child: _RoundStat('DAMAGE', damageDealt.toStringAsFixed(0), const Color(0xFFFBBF24))),
              Expanded(child: _RoundStat('LOADOUT', '\$${loadoutValue.toStringAsFixed(0)}', const Color(0xFFA855F7))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _RoundStat('ECON EFF.', '${econEfficiency.toStringAsFixed(1)}%', const Color(0xFF0FB5AE))),
              Expanded(child: _RoundStat('WEAPON', weaponName.isNotEmpty ? weaponName : '—', Colors.white70)),
              Expanded(child: const SizedBox()),
              Expanded(child: const SizedBox()),
            ]),
            if (gotFirstBlood || gotFirstDeath || wasClutch || wasAce || planted || defused) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (gotFirstBlood) _EventChip('⚡ FIRST BLOOD', const Color(0xFF16C47F)),
                if (gotFirstDeath) _EventChip('💀 FIRST DEATH', const Color(0xFFF53D4C)),
                if (wasClutch) _EventChip('🏆 CLUTCH', const Color(0xFFA855F7)),
                if (wasAce) _EventChip('⭐ ACE', const Color(0xFFFBBF24)),
                if (planted) _EventChip('💣 PLANTED', const Color(0xFFEC4899)),
                if (defused) _EventChip('🛡 DEFUSED', const Color(0xFF8B5CF6)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _RoundStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RoundStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: AppTheme.inter(size: 8, color: AppTheme.textMuted, weight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(value, style: AppTheme.krona(size: 16, color: color)),
    ]);
  }
}

Widget _EventChip(String label, Color color) {
  return Builder(builder: (_) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(label, style: AppTheme.inter(size: 10, color: color, weight: FontWeight.bold)),
  ));
}
