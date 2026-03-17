import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';

class BattlepassScreen extends ConsumerStatefulWidget {
  const BattlepassScreen({super.key});

  @override
  ConsumerState<BattlepassScreen> createState() => _BattlepassScreenState();
}

class _BattlepassScreenState extends ConsumerState<BattlepassScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('BATTLEPASS', style: AppTheme.krona(size: 24)),
                      const SizedBox(height: 4),
                      Text('Complete quests to earn XP', style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
                    ]),
                  ),
                  if (auth.isClerkSignedIn && auth.isRiotLinked)
                    _XpBadge(),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Tab Bar ────────────────────────────────
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
                    Tab(text: 'DAILY'),
                    Tab(text: 'WEEKLY'),
                    Tab(text: 'SEASONAL'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ────────────────────────────────
            Expanded(
              child: !auth.isClerkSignedIn || !auth.isRiotLinked
                  ? _BattlepassGate(auth: auth)
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _QuestList(type: 'daily'),
                        _QuestList(type: 'weekly'),
                        _SeasonalView(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── XP Badge ─────────────────────────────────────────────────────────────────

class _XpBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, color: AppTheme.accentYellow, size: 16),
        const SizedBox(width: 6),
        Text('0 XP', style: AppTheme.krona(size: 12, color: AppTheme.accentYellow)),
      ]),
    );
  }
}

// ─── Gate ─────────────────────────────────────────────────────────────────────

class _BattlepassGate extends StatelessWidget {
  final AuthState auth;
  const _BattlepassGate({required this.auth});

  @override
  Widget build(BuildContext context) {
    final needsSignIn = !auth.isClerkSignedIn;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(Icons.military_tech_rounded, size: 48, color: AppTheme.accentYellow.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 22),
          Text(
            needsSignIn ? 'SIGN IN REQUIRED' : 'LINK RIOT ACCOUNT',
            style: AppTheme.krona(size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            needsSignIn
                ? 'Sign in to track daily quests, earn XP, and climb the leaderboard.'
                : 'Link your Riot account in Settings to start earning XP from your matches.',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(needsSignIn ? '/onboarding' : '/home'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(needsSignIn ? 'GET STARTED' : 'GO TO SETTINGS', style: AppTheme.krona(size: 11, color: AppTheme.darkBg, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Quest List ───────────────────────────────────────────────────────────────

class _QuestList extends ConsumerWidget {
  final String type;
  const _QuestList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: wire to real API when Riot is linked
    // Mock data for now
    final quests = _mockQuests(type);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: quests.length,
      itemBuilder: (_, i) => _QuestCard(quest: quests[i]),
    );
  }

  List<Map<String, dynamic>> _mockQuests(String type) {
    if (type == 'daily') {
      return [
        {'title': 'Win 2 Competitive Matches', 'xp': 200, 'progress': 1, 'total': 2},
        {'title': 'Get 20 Headshots', 'xp': 150, 'progress': 8, 'total': 20},
        {'title': 'Play 3 Matches', 'xp': 100, 'progress': 3, 'total': 3, 'completed': true},
      ];
    } else if (type == 'weekly') {
      return [
        {'title': 'Win 10 Competitive Matches', 'xp': 800, 'progress': 3, 'total': 10},
        {'title': 'Deal 50,000 Damage', 'xp': 600, 'progress': 21000, 'total': 50000},
        {'title': 'Achieve 15+ Kills in 3 Matches', 'xp': 500, 'progress': 1, 'total': 3},
        {'title': 'Play 5 Different Agents', 'xp': 450, 'progress': 2, 'total': 5},
      ];
    } else {
      return [
        {'title': 'Reach Platinum Rank', 'xp': 3000, 'progress': 50, 'total': 100},
        {'title': 'Win 50 Competitive Matches', 'xp': 2500, 'progress': 18, 'total': 50},
        {'title': 'Get 500 Total Kills', 'xp': 2000, 'progress': 182, 'total': 500},
      ];
    }
  }
}

class _QuestCard extends StatelessWidget {
  final Map<String, dynamic> quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final completed = quest['completed'] == true || quest['progress'] >= quest['total'];
    final pct = (quest['progress'] / quest['total']).clamp(0.0, 1.0) as double;
    final xp = quest['xp'] as int;
    final color = completed ? AppTheme.accentGreen : AppTheme.primaryRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(quest['title'].toString(), style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: AppTheme.accentYellow, size: 12),
              const SizedBox(width: 4),
              Text('+$xp XP', style: AppTheme.krona(size: 9, color: AppTheme.accentYellow)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.borderColor,
            color: color,
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            '${quest['progress']} / ${quest['total']}',
            style: AppTheme.inter(size: 11, color: AppTheme.textMuted),
          ),
          Text(
            completed ? '✓ COMPLETE' : '${(pct * 100).toStringAsFixed(0)}%',
            style: AppTheme.inter(size: 11, color: color, weight: FontWeight.w700),
          ),
        ]),
      ]),
    );
  }
}

// ─── Seasonal View ────────────────────────────────────────────────────────────

class _SeasonalView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Pass track
        Text('PASS TRACK', style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 2)),
        const SizedBox(height: 12),
        _PassTrack(),
        const SizedBox(height: 24),

        // Seasonal quests
        Text('SEASONAL QUESTS', style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 2)),
        const SizedBox(height: 12),
        ...[
          {'title': 'Reach Platinum Rank', 'xp': 3000, 'progress': 50, 'total': 100},
          {'title': 'Win 50 Competitive Matches', 'xp': 2500, 'progress': 18, 'total': 50},
          {'title': 'Get 500 Total Kills', 'xp': 2000, 'progress': 182, 'total': 500},
        ].map((q) => _QuestCard(quest: q)),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _PassTrack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const totalTiers = 10;
    const currentTier = 2;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalTiers,
        itemBuilder: (_, i) {
          final tier = i + 1;
          final isUnlocked = tier <= currentTier;
          final isCurrent = tier == currentTier;
          return Container(
            width: 60,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? AppTheme.primaryGradient
                  : const LinearGradient(colors: [AppTheme.cardBg, AppTheme.cardBg]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent ? AppTheme.primaryRed : AppTheme.borderColor,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                isUnlocked ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                color: isUnlocked ? Colors.white : AppTheme.textMuted,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text('T$tier', style: AppTheme.krona(size: 9, color: isUnlocked ? Colors.white : AppTheme.textMuted)),
            ]),
          );
        },
      ),
    );
  }
}
