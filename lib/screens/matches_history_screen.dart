import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class MatchesHistoryScreen extends StatelessWidget {
  final List<dynamic> matches;
  final String rank;
  final Map<String, dynamic>? playerData;

  const MatchesHistoryScreen({
    super.key,
    required this.matches,
    required this.rank,
    this.playerData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        centerTitle: true,
        title: Text('MATCH HISTORY', style: AppTheme.krona(size: 14, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: matches.isEmpty
            ? Center(
                child: Text('No matches available', style: AppTheme.inter(color: AppTheme.textMuted)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index] as Map<String, dynamic>;
                  return _ExpandableMatchCard(match: match, rank: rank);
                },
              ),
      ),
    );
  }
}

class _ExpandableMatchCard extends StatefulWidget {
  final Map<String, dynamic> match;
  final String rank;
  const _ExpandableMatchCard({required this.match, required this.rank});

  @override
  State<_ExpandableMatchCard> createState() => _ExpandableMatchCardState();
}

class _ExpandableMatchCardState extends State<_ExpandableMatchCard> {
  bool _isExpanded = false;

  String _agentAsset(String agent) {
    final clean = agent.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'assets/agents/$clean.png';
  }

  String _mapAsset(String map) {
    final clean = map.toLowerCase().replaceAll(' ', '');
    return 'assets/maps/$clean.jpg';
  }
  
  String _rankAsset(String rankStr) {
    final r = rankStr.toLowerCase();
    if (r.contains('radiant')) return 'assets/ranks/radiant_rank.png';
    final m = RegExp(r'^(\w+)\s+(\d+)').firstMatch(rankStr);
    if (m != null) {
      return 'assets/ranks/${m.group(1)!.toLowerCase()}_${m.group(2)}_rank.png';
    }
    return 'assets/ranks/unranked_rank.png';
  }

  @override
  Widget build(BuildContext context) {
    final agent = (widget.match['agent'] ?? '').toString();
    final mapName = (widget.match['map'] ?? '').toString();
    final result = (widget.match['result'] ?? '').toString().toLowerCase();
    final kills = widget.match['kills'] ?? 0;
    final deaths = widget.match['deaths'] ?? 0;
    final assists = widget.match['assists'] ?? 0;
    final mode = (widget.match['mode'] ?? 'Competitive').toString();
    final team = (widget.match['team'] ?? '').toString().toLowerCase();
    final teams = widget.match['teams'] as Map<String, dynamic>?;

    final k = (kills is num ? kills.toInt() : int.tryParse(kills.toString()) ?? 0);
    final d = (deaths is num ? deaths.toInt() : int.tryParse(deaths.toString()) ?? 0);
    final a = (assists is num ? assists.toInt() : int.tryParse(assists.toString()) ?? 0);
    final kd = d > 0 ? (k / d).toStringAsFixed(2) : k.toString();

    int myScore = 0, enemyScore = 0;
    if (teams != null && team.isNotEmpty) {
      final isBlue = team == 'blue';
      myScore = ((isBlue ? teams['blue'] : teams['red']) ?? 0) as int;
      enemyScore = ((isBlue ? teams['red'] : teams['blue']) ?? 0) as int;
    }

    final isWin = result == 'won' || result == 'win' || result == 'victory';
    final isDraw = result == 'draw' || result == 'tied';
    final accent = isDraw ? AppTheme.accentYellow : isWin ? AppTheme.accentGreen : AppTheme.primaryRed;
    final tag = isDraw ? 'DRAW' : isWin ? 'WIN' : 'LOSS';
    
    final hsPercent = widget.match['headshot_percentage'];
    final hsStr = hsPercent != null ? '${(hsPercent is num ? hsPercent.toDouble() : double.tryParse(hsPercent.toString()) ?? 0.0).toStringAsFixed(1)}%' : '-';
    
    final acs = widget.match['ACS'] ?? widget.match['combat_score'] ?? widget.match['score'];
    final acsStr = acs != null ? (acs is num ? acs.toInt().toString() : acs.toString()) : '-';
    
    final dmgMade = widget.match['damage_made'];
    final dmgReceived = widget.match['damage_received'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Column(
            children: [
              // ── Header (Always Visible) ──
              Stack(
                children: [
                  // Map thumbnail bg
                  Positioned.fill(
                    right: null,
                    child: SizedBox(
                      width: 80,
                      child: Stack(
                        children: [
                          Image.asset(
                            _mapAsset(mapName),
                            width: 80,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.surfaceDark),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, AppTheme.cardBg],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Agent image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Image.asset(
                              _agentAsset(agent),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.surfaceDark,
                                child: const Icon(Icons.person_rounded, color: AppTheme.textMuted, size: 26),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Agent + map
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(agent.isEmpty ? 'Unknown' : agent, style: AppTheme.inter(size: 13, weight: FontWeight.w700)),
                              Text('$mapName • $mode', style: AppTheme.inter(size: 10, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        // Score + result tag
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$myScore : $enemyScore', style: AppTheme.krona(size: 15, color: accent)),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tag, style: AppTheme.krona(size: 8, color: accent, letterSpacing: 0.5)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        // KDA
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$k / $d / $a', style: AppTheme.inter(size: 12, color: AppTheme.textSecondary, weight: FontWeight.w600)),
                            Text('K/D $kd', style: AppTheme.inter(size: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ── Expanded Details ──
              if (_isExpanded)
                Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _DetailStat(label: 'HEADSHOT', value: hsStr)),
                          Expanded(child: _DetailStat(label: 'ACS', value: acsStr)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('RANK', style: AppTheme.inter(size: 9, color: AppTheme.textMuted, weight: FontWeight.w700, letterSpacing: 1)),
                                const SizedBox(height: 6),
                                Image.asset(_rankAsset(widget.rank), width: 24, height: 24, errorBuilder: (_,__,___) => const SizedBox(width: 24, height: 24)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                         children: [
                          Expanded(child: _DetailStat(label: 'DMG MADE', value: dmgMade != null ? dmgMade.toString() : '-')),
                          Expanded(child: _DetailStat(label: 'DMG RCVD', value: dmgReceived != null ? dmgReceived.toString() : '-')),
                          Expanded(child: _DetailStat(label: 'MODE', value: mode.toUpperCase())),
                        ],
                      ),
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

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTheme.inter(size: 9, color: AppTheme.textMuted, weight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.krona(size: 13, color: Colors.white)),
      ],
    );
  }
}
