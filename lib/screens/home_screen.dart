import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'ap';
  static const _regions = ['ap', 'eu', 'na'];
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final input = _searchController.text.trim();
    if (input.isEmpty) return;
    final parts = input.split('#');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please use Name#Tag format', style: AppTheme.inter(size: 13)),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final cleanName = parts[0].trim().replaceAll(RegExp(r'\s+'), '');
    final cleanTag  = parts[1].trim().replaceAll(RegExp(r'\s+'), '');
    ref.read(playerStatsProvider.notifier).searchPlayer(cleanName, cleanTag, region: _selectedRegion);
    ref.read(bottomNavIndexProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── TOP HERO ──────────────────────────────────────────
                _HeroBanner(size: size),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Region chips
                      Row(
                        children: _regions.map((r) {
                          final sel = _selectedRegion == r;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRegion = r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(
                                  color: sel ? AppTheme.primaryRed : AppTheme.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel ? AppTheme.primaryRed : AppTheme.borderColor,
                                  ),
                                ),
                                child: Text(
                                  r.toUpperCase(),
                                  style: AppTheme.krona(
                                    size: 11,
                                    color: sel ? Colors.white : AppTheme.textMuted,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: AppTheme.inter(size: 15, weight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'PlayerName#Tag',
                                  hintStyle: AppTheme.inter(color: AppTheme.textMuted),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 17,
                                  ),
                                ),
                                onSubmitted: (_) => _onSearch(),
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                            GestureDetector(
                              onTap: _onSearch,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryRed.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Section header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('FEATURES', style: AppTheme.krona(size: 11, color: AppTheme.textMuted, letterSpacing: 2)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Feature cards
                      _FeatureTile(
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI COACH',
                        subtitle: 'Personalized tips to climb ranks',
                        iconColor: const Color(0xFFB78BFA),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A0533), Color(0xFF2D1065)],
                        ),
                        borderColor: const Color(0xFF7C3AED),
                      ),
                      const SizedBox(height: 10),
                      _FeatureTile(
                        icon: Icons.analytics_outlined,
                        title: 'MATCH ANALYSIS',
                        subtitle: 'Round-by-round breakdown',
                        iconColor: AppTheme.accentGreen,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF021A0E), Color(0xFF04321A)],
                        ),
                        borderColor: AppTheme.accentGreen,
                      ),
                      const SizedBox(height: 10),
                      _FeatureTile(
                        icon: Icons.military_tech_rounded,
                        title: 'BATTLEPASS',
                        subtitle: 'Daily quests, XP & leaderboard',
                        iconColor: AppTheme.accentYellow,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1000), Color(0xFF332000)],
                        ),
                        borderColor: AppTheme.accentYellow,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final Size size;
  const _HeroBanner({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background gradient
        Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0010), Color(0xFF300016), Color(0xFF0D0D0D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Grid lines overlay
        Positioned.fill(
          child: CustomPaint(painter: _GridPainter()),
        ),

        // Valorant logo agent art
        Positioned(
          right: -10,
          bottom: -10,
          child: Opacity(
            opacity: 0.28,
            child: CachedNetworkImage(
              imageUrl: 'https://www.valocoach.live/media/agents/jett.png',
              height: 250,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(),
              errorWidget: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),

        // Red glow
        Positioned(
          left: -30,
          top: -30,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryRed.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branding row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('VALOCOACH', style: AppTheme.krona(size: 14, letterSpacing: 1.5)),
                ],
              ),

              const SizedBox(height: 24),

              // Hero text
              Text(
                'READY TO\nDOMINATE?',
                style: AppTheme.krona(size: 36, height: 1.1),
              ),

              const SizedBox(height: 10),

              // Sub text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'AI-powered coaching for ranked players',
                  style: AppTheme.inter(size: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Subtle grid overlay
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
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

// ─── Feature Tile ─────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color iconColor;
  final LinearGradient gradient;
  final Color borderColor;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.gradient,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.krona(size: 12, color: Colors.white, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
        ],
      ),
    );
  }
}
