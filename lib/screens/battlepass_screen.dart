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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('BATTLE', style: AppTheme.krona(size: 28, letterSpacing: 2)),
                            Text('PASS', style: AppTheme.krona(size: 28, color: AppTheme.primaryRed, letterSpacing: 2)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('TURN YOUR IMPROVEMENT INTO REWARDS', 
                            style: AppTheme.krona(size: 10, color: AppTheme.textSecondary, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text('YOUR RANK DESERVES MORE THAN A PNG', 
                            style: AppTheme.inter(size: 11, color: AppTheme.textMuted, weight: FontWeight.w700, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                    tooltip: 'Refresh',
                    onPressed: () => ref.read(battlepassProvider.notifier).fetchAll(),
                  ),
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
    
    String _formatVal(double val) => val.truncateToDouble() == val ? val.toInt().toString() : val.toStringAsFixed(2);
    
    String timeRemaining = '';
    if (quest['expires_at'] != null) {
      try {
        final expires = DateTime.parse(quest['expires_at'].toString()).toLocal();
        final diff = expires.difference(DateTime.now());
        if (diff.isNegative) {
          timeRemaining = 'EXPIRED';
        } else if (diff.inDays > 0) {
          timeRemaining = '${diff.inDays}d ${diff.inHours % 24}h left';
        } else if (diff.inHours > 0) {
          timeRemaining = '${diff.inHours}h ${diff.inMinutes % 60}m left';
        } else {
          timeRemaining = '${diff.inMinutes}m left';
        }
      } catch (_) {}
    }
    
    final statusText = completed ? 'COMPLETED' : (quest['status']?.toString().toUpperCase() ?? 'ACTIVE');

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
              
              // Top Row (Category + Difficulty + Timer)
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(category.toUpperCase(), style: AppTheme.krona(size: 8, color: color, letterSpacing: 1)),
                ),
                const SizedBox(width: 8),
                Text(difficulty.toUpperCase(), style: AppTheme.inter(size: 10, color: AppTheme.textMuted, weight: FontWeight.w600)),
                const Spacer(),
                if (timeRemaining.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(timeRemaining, style: AppTheme.inter(size: 10, color: AppTheme.textSecondary, weight: FontWeight.w600)),
                  ]),
              ]),
              
              const SizedBox(height: 12),
              
              // Title
              Text(title, style: AppTheme.inter(size: 14, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(questData['description']?.toString() ?? 'Complete this mission to earn rewards', style: AppTheme.inter(size: 11, color: AppTheme.textSecondary)),
              
              if (questData['target_agent'] != null || questData['target_map'] != null || questData['target_metric'] != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (questData['target_agent'] != null)
                      _TargetChip(icon: Icons.person_rounded, label: questData['target_agent']),
                    if (questData['target_map'] != null)
                      _TargetChip(icon: Icons.map_rounded, label: questData['target_map']),
                    if (questData['target_metric'] != null)
                      _TargetChip(icon: Icons.analytics_rounded, label: questData['target_metric']),
                  ],
                ),
              ],
              
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
                Text('${_formatVal(progress)} / ${_formatVal(total)}', style: AppTheme.krona(size: 9, color: AppTheme.textMuted)),
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
                    statusText,
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

class _TargetChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TargetChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(label.toUpperCase(), style: AppTheme.krona(size: 8, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Battlepass Track Tab ───────────────────────────────────────────────────────

// ─── Battlepass Track Tab ───────────────────────────────────────────────────────

class _BattlepassTrackTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpState = ref.watch(battlepassProvider);
    final bp = bpState.battlepass ?? {};
    final currentXp = bp['total_xp'] ?? 0;
    final level = bp['level'] ?? 1;
    final targetXp = 3000; // Assuming 3000 XP per level based on UI
    final progress = (currentXp % targetXp) / targetXp;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Progress Bar Section ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text('CURRENT PROGRESS', 
                    style: AppTheme.krona(size: 10, color: AppTheme.primaryRed, letterSpacing: 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                RichText(text: TextSpan(children: [
                  TextSpan(text: '${currentXp % targetXp} ', style: AppTheme.krona(size: 18, color: Colors.white)),
                  TextSpan(text: '/ $targetXp XP', style: AppTheme.krona(size: 12, color: AppTheme.textMuted)),
                ])),
              ]),
              const SizedBox(height: 12),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Stack(children: [
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.4), blurRadius: 10)
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ])),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryRed, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(children: [
                Text('LEVEL', style: AppTheme.krona(size: 8, color: AppTheme.textMuted)),
                Text('$level', style: AppTheme.krona(size: 24, color: Colors.white)),
              ]),
            ),
          ]),
        ),

        // ── Grid Track Section ──
        Stack(children: [
          // Background Grid
          Positioned.fill(child: _GridPainterWidget()),
          
          _PassTrack(),
        ]),

        const SizedBox(height: 30),

        // ── Bottom Claim Info ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.surfaceDark, shape: BoxShape.circle),
                child: const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('REACH LEVEL 50 TO CLAIM', style: AppTheme.krona(size: 12)),
                const SizedBox(height: 4),
                Text('${50 - level} levels remaining to unlock your grand reward.', 
                    style: AppTheme.inter(size: 11, color: AppTheme.textSecondary)),
              ])),
            ]),
          ),
        ),
        
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _GridPainterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PassGridPainter(),
    );
  }
}

class _PassGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Leaderboard Tab ──────────────────────────────────────────────────────────

class _LeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpState = ref.watch(battlepassProvider);
    final auth = ref.watch(authProvider);
    final players = bpState.leaderboard;

    if (bpState.isLoading && players.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow));
    }

    if (players.isEmpty) {
      return const Center(child: Text('Leaderboard is currently empty.', style: TextStyle(color: Colors.white54)));
    }

    // Logic to find current user
    final myFullName = '${auth.riotName}#${auth.riotTag}';
    Map<String, dynamic>? myPlayer;
    int? myRankIndex;

    for (int i = 0; i < players.length; i++) {
      final p = players[i];
      final playerName = p['player_name']?.toString() ?? '';
      if (playerName == myFullName || 
          playerName == auth.riotName || 
          p['clerk_id'] == auth.clerkUserId) {
        myPlayer = p;
        myRankIndex = i;
        break;
      }
    }

    return Column(
      children: [
        // ── Global Stats Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(children: [
              const Icon(Icons.groups_rounded, color: AppTheme.textMuted, size: 20),
              const SizedBox(width: 12),
              Text('TOTAL PLAYERS', style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 1)),
              const Spacer(),
              Text('${bpState.totalPlayers}', style: AppTheme.krona(size: 14, color: Colors.white)),
            ]),
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Extra padding for sticky footer
                physics: const BouncingScrollPhysics(),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final p = players[index];
                  final rank = p['rank'] ?? (index + 1);
                  final playerName = p['player_name']?.toString() ?? '';
                  final isMe = playerName == myFullName || playerName == auth.riotName || p['clerk_id'] == auth.clerkUserId;
                  final isTop3 = rank <= 3;

                  Color rankColor = AppTheme.textMuted;
                  IconData? rankIcon;
                  if (rank == 1) { rankColor = AppTheme.accentYellow; rankIcon = Icons.emoji_events; }
                  else if (rank == 2) { rankColor = AppTheme.accentSilver; rankIcon = Icons.emoji_events; }
                  else if (rank == 3) { rankColor = AppTheme.accentBronze; rankIcon = Icons.emoji_events; }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primaryRed.withValues(alpha: 0.1) : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe 
                          ? AppTheme.primaryRed.withValues(alpha: 0.4) 
                          : (isTop3 ? rankColor.withValues(alpha: 0.3) : AppTheme.borderColor),
                        width: isMe ? 2 : 1,
                      ),
                      boxShadow: isMe ? [
                        BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.1), blurRadius: 12)
                      ] : null,
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 44,
                        child: rankIcon != null 
                          ? Icon(rankIcon, color: rankColor, size: 20)
                          : Text('#$rank', style: AppTheme.krona(size: 13, color: rankColor)),
                      ),
                      const SizedBox(width: 8),
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
                              ),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            if (isMe)
                              Text('YOU', style: AppTheme.krona(size: 8, color: AppTheme.primaryRed, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${p['total_xp'] ?? 0} XP', style: AppTheme.krona(size: 11, color: AppTheme.accentYellow)),
                          const SizedBox(height: 2),
                          Text('LVL ${p['level'] ?? 1}', style: AppTheme.inter(size: 10, color: AppTheme.textSecondary, weight: FontWeight.w700)),
                        ],
                      ),
                    ]),
                  );
                },
              ),

              // ── Sticky "My Rank" Footer ──
              if (myPlayer != null)
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E), // Deeper blue/dark for contrast
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.primaryRed, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 4)),
                        BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.2), blurRadius: 10),
                      ],
                    ),
                    child: Row(children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('MY RANK', style: AppTheme.krona(size: 9, color: AppTheme.primaryRed, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text('#${myPlayer['rank'] ?? (myRankIndex! + 1)}', style: AppTheme.krona(size: 20, color: Colors.white)),
                      ]),
                      const Spacer(),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('TOTAL XP', style: AppTheme.inter(size: 9, color: AppTheme.textMuted, weight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${myPlayer['total_xp'] ?? 0}', style: AppTheme.krona(size: 14, color: AppTheme.accentYellow)),
                      ]),
                      const SizedBox(width: 24),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('LEVEL', style: AppTheme.inter(size: 9, color: AppTheme.textMuted, weight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${myPlayer['level'] ?? 1}', style: AppTheme.krona(size: 14, color: Colors.white)),
                      ]),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PassTrack extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bpState = ref.watch(battlepassProvider);
    const totalTiers = 50;
    final currentLevel = bpState.battlepass?['level'] ?? 1;
    final scrollController = ScrollController();

    return SizedBox(
      height: 380, // Increased height for the cards + track
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 1. Background Connecting Line (Gray)
            Positioned(
              top: 50,
              left: 30,
              right: 30,
              child: Container(
                height: 3,
                width: (totalTiers * 140.0) - 60, // Calculate total width
                color: AppTheme.surfaceDark,
              ),
            ),

            // 2. Foreground Connecting Line (Yellow)
            Positioned(
              top: 50,
              left: 30,
              child: Container(
                height: 3,
                width: (currentLevel - 1) * 140.0,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  boxShadow: [
                    BoxShadow(color: Color(0xFFFFD700), blurRadius: 4),
                  ],
                ),
              ),
            ),

            // 3. Nodes and Cards
            Row(
              children: List.generate(totalTiers, (i) {
                final level = i + 1;
                final isUnlocked = level <= currentLevel;
                final isCurrent = level == currentLevel;
                final isClaimed = level < currentLevel; // Simple logic for demonstration

                return SizedBox(
                  width: 140,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Node Circle
                      Positioned(
                        top: 40,
                        left: 20,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnlocked ? const Color(0xFFFFD700) : AppTheme.surfaceDark,
                            border: Border.all(
                              color: isCurrent ? Colors.white : (isUnlocked ? Colors.transparent : AppTheme.borderColor),
                              width: 2,
                            ),
                            boxShadow: isUnlocked ? [
                              BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 8)
                            ] : null,
                          ),
                          child: Center(
                            child: isUnlocked 
                                ? const Icon(Icons.check, size: 14, color: Colors.black)
                                : Text('$level', style: AppTheme.krona(size: 8, color: AppTheme.textMuted)),
                          ),
                        ),
                      ),

                      // Reward Card
                      Positioned(
                        top: 90,
                        left: 10,
                        child: _RewardCard(
                          level: level,
                          isUnlocked: isUnlocked,
                          isCurrent: isCurrent,
                          isClaimed: isClaimed,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final int level;
  final bool isUnlocked, isCurrent, isClaimed;

  const _RewardCard({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isClaimed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked && !isClaimed) {
          _showClaimPopup(context, level);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: isUnlocked ? AppTheme.cardBg : AppTheme.darkBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? AppTheme.primaryRed : (isUnlocked ? Colors.white24 : AppTheme.borderColor),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent ? [
            BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.2), blurRadius: 15)
          ] : null,
        ),
        child: Stack(
          children: [
            // Reward Image Placeholder (VP Card)
            Positioned.fill(
              child: Opacity(
                opacity: isUnlocked ? 1.0 : 0.3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text('10 VP', style: AppTheme.krona(size: 12, letterSpacing: 1)),
                    const Spacer(),
                    const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 48),
                    const Spacer(),
                    Text('ITEM', style: AppTheme.krona(size: 8, color: AppTheme.textMuted)),
                  ]),
                ),
              ),
            ),

            if (isClaimed)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.accentGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),

            if (!isUnlocked)
              const Center(child: Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 32)),
              
            // Progress highlight at bottom for unlocked
            if (isUnlocked && !isClaimed)
              Positioned(
                bottom: 0, left: 0, right: 0,
                height: 4,
                child: Container(color: AppTheme.primaryRed),
              ),
          ],
        ),
      ),
    );
  }

  void _showClaimPopup(BuildContext context, int level) {
    showDialog(
      context: context,
      builder: (context) => _ClaimDialog(level: level),
    );
  }
}

class _ClaimDialog extends StatelessWidget {
  final int level;
  const _ClaimDialog({required this.level});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.celebration_rounded, color: AppTheme.primaryRed, size: 64),
          const SizedBox(height: 20),
          Text('LEVEL $level REWARD', style: AppTheme.krona(size: 18)),
          const SizedBox(height: 12),
          Text('You have successfully claimed 10 Valo Points!', 
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('AWESOME!', style: AppTheme.krona(size: 12, letterSpacing: 1.5))),
            ),
          ),
        ]),
      ),
    );
  }
}
