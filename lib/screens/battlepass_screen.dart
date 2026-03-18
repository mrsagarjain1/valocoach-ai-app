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
    _tabCtrl = TabController(length: 5, vsync: this);
    
    // Fetch battlepass data on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(battlepassProvider.notifier).fetchAll();
      }
    });
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
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'TRACK'),
                    Tab(text: 'DAILY'),
                    Tab(text: 'WEEKLY'),
                    Tab(text: 'SEASONAL'),
                    Tab(text: 'LEADERBOARD'),
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
                        _BattlepassTrackTab(),
                        _QuestList(type: 'daily'),
                        _QuestList(type: 'weekly'),
                        _QuestList(type: 'seasonal'),
                        _LeaderboardTab(),
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

class _XpBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpState = ref.watch(battlepassProvider);
    final currentXp = bpState.battlepass?['total_xp'] ?? 0;

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
        Text('$currentXp XP', style: AppTheme.krona(size: 12, color: AppTheme.accentYellow)),
      ]),
    );
  }
}

// ─── Gate ─────────────────────────────────────────────────────────────────────

class _BattlepassGate extends ConsumerWidget {
  final AuthState auth;
  const _BattlepassGate({required this.auth});

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
    final bpState = ref.watch(battlepassProvider);
    
    final List quests;
    if (type == 'daily') {
      quests = bpState.dailyQuests;
    } else if (type == 'weekly') {
      quests = bpState.weeklyQuests;
    } else {
      quests = bpState.seasonalQuests;
    }

    if (bpState.isLoading && quests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow));
    }
    
    if (quests.isEmpty) {
      return Center(
        child: Text('No $type quests available.', style: AppTheme.inter(color: AppTheme.textMuted)),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: quests.length,
      itemBuilder: (_, i) => _QuestCard(quest: quests[i]),
    );
  }

}

class _QuestCard extends StatelessWidget {
  final Map<String, dynamic> quest;
  const _QuestCard({required this.quest});

  Color _getCategoryColor(String category) {
    if (category.toLowerCase() == 'combat') return AppTheme.primaryRed;
    if (category.toLowerCase() == 'objective') return const Color(0xFF9D4EDD);
    if (category.toLowerCase() == 'tactical') return const Color(0xFF00E5FF);
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final questData = quest['quest_data'] as Map<String, dynamic>? ?? {};
    final progressMap = quest['progress'] as Map<String, dynamic>? ?? {};

    final category = questData['category'] as String? ?? 'Combat';
    final difficulty = questData['difficulty'] as String? ?? 'Medium';
    
    final progress = double.tryParse((progressMap['current_value'] ?? 0).toString()) ?? 0.0;
    final total = double.tryParse((progressMap['target_value'] ?? 1).toString()) ?? 1.0;
    final completed = quest['status'] == 'completed' || progress >= total;
    final pct = (progress / total).clamp(0.0, 1.0);
    final xp = (questData['xp'] ?? 0);
    final title = (questData['name'] ?? quest['title'] ?? 'Unknown Quest').toString();
    
    final color = completed ? AppTheme.accentGreen : _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: completed ? AppTheme.accentGreen.withValues(alpha: 0.3) : AppTheme.borderColor),
      ),
      child: Stack(
        children: [
          // Left Accent Border
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(width: 4, color: color),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              
              // Top Row (Category + Difficulty)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(category.toUpperCase(), style: AppTheme.krona(size: 8, color: color, letterSpacing: 1)),
                ),
                Text(difficulty.toUpperCase(), style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.w600)),
              ]),
              
              const SizedBox(height: 12),
              
              // Title
              Text(title, style: AppTheme.inter(size: 14, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(questData['description']?.toString() ?? 'Complete this mission to earn rewards', style: AppTheme.inter(size: 11, color: AppTheme.textSecondary)),
              
              const SizedBox(height: 16),
              
              // Custom Skewed Progress Bar
              Container(
                height: 12,
                decoration: BoxDecoration(color: AppTheme.darkBg, border: Border.all(color: AppTheme.borderColor)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          width: constraints.maxWidth * pct,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                          ),
                        ),
                        // Skewed lines overlay
                        ...List.generate((constraints.maxWidth / 20).floor(), (i) => Positioned(
                          left: i * 20.0, top: 0, bottom: 0,
                          child: Container(
                            width: 1, 
                            color: Colors.black.withValues(alpha: 0.2), 
                            transform: Matrix4.skewX(-0.3),
                          ),
                        )),
                      ],
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 6),
              // Progress Text
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${progress.toInt()} / ${total.toInt()}', style: AppTheme.krona(size: 9, color: AppTheme.textMuted)),
                Text(completed ? '100%' : '${(pct * 100).toStringAsFixed(0)}%', style: AppTheme.krona(size: 9, color: color)),
              ]),

              const SizedBox(height: 16),
              
              // Bottom Row (XP + CTA)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.star_rounded, color: AppTheme.accentYellow, size: 16),
                  const SizedBox(width: 4),
                  Text('$xp XP', style: AppTheme.krona(size: 12, color: AppTheme.accentYellow)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: completed ? AppTheme.accentGreen.withValues(alpha: 0.15) : AppTheme.darkBg,
                    border: Border.all(color: completed ? AppTheme.accentGreen.withValues(alpha: 0.3) : AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    completed ? 'CLAIMED' : 'TRACKING',
                    style: AppTheme.krona(
                      size: 9,
                      color: completed ? AppTheme.accentGreen : AppTheme.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ]),
              
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Battlepass Track Tab ───────────────────────────────────────────────────────

class _BattlepassTrackTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SEASON 1 BATTLEPASS', style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 2)),
        const SizedBox(height: 12),
        _PassTrack(),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ─── Leaderboard Tab ──────────────────────────────────────────────────────────

class _LeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpState = ref.watch(battlepassProvider);
    final players = bpState.leaderboard;
    final auth = ref.watch(authProvider);

    if (bpState.isLoading && players.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow));
    }

    if (players.isEmpty) {
      return const Center(child: Text('Leaderboard is currently empty.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        final rank = p['rank'] ?? (index + 1);
        final isMe = p['clerk_id'] == auth.clerkUserId;
        final isTop3 = rank <= 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryRed.withValues(alpha: 0.1) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe 
                ? AppTheme.primaryRed.withValues(alpha: 0.4) 
                : (isTop3 ? AppTheme.accentYellow.withValues(alpha: 0.3) : AppTheme.borderColor),
              width: isMe ? 2 : 1,
            ),
            boxShadow: isMe ? [
              BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.1), blurRadius: 12)
            ] : null,
          ),
          child: Row(children: [
            SizedBox(
              width: 40,
              child: Text(
                '#$rank', 
                style: AppTheme.krona(
                  size: 14, 
                  color: isTop3 ? AppTheme.accentYellow : AppTheme.textMuted
                )
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (p['player_name'] ?? 'Unknown').toString(), 
                    style: AppTheme.inter(
                      size: 14, 
                      weight: FontWeight.bold,
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                    )
                  ),
                  if (isMe)
                    Text('YOU', style: AppTheme.krona(size: 8, color: AppTheme.primaryRed, letterSpacing: 1)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${p['total_xp'] ?? 0} XP', style: AppTheme.krona(size: 11, color: AppTheme.accentYellow)),
                const SizedBox(height: 2),
                Text('LVL ${p['level'] ?? 1}', style: AppTheme.inter(size: 10, color: AppTheme.textSecondary, weight: FontWeight.w600)),
              ],
            ),
          ]),
        );
      },
    );
  }
}

class _PassTrack extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpState = ref.watch(battlepassProvider);
    const totalTiers = 50;
    final currentTier = bpState.battlepass?['level'] ?? 1;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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
              color: isUnlocked ? null : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent ? AppTheme.accentGreen : AppTheme.borderColor,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isCurrent ? [
                BoxShadow(color: AppTheme.accentGreen.withValues(alpha: 0.2), blurRadius: 10)
              ] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                isUnlocked ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                color: isUnlocked ? Colors.white : AppTheme.textMuted.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text('T$tier', style: AppTheme.krona(
                size: 9, 
                color: isUnlocked ? Colors.white : AppTheme.textMuted,
              )),
            ]),
          );
        },
      ),
    );
  }
}
