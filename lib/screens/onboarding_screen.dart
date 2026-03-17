import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _signIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // ── Background gradient ─────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0010), Color(0xFF220016), Color(0xFF0D0D0D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // ── Grid overlay ────────────────────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // ── Red glow top-left ───────────────────────────
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryRed.withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Agent art ──────────────────────────────────
          Positioned(
            right: -30,
            top: size.height * 0.05,
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/agents/jett.png',
                height: size.height * 0.55,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo row
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text('VALOCOACH', style: AppTheme.krona(size: 14, letterSpacing: 1.5)),
                      ]),

                      const Spacer(),

                      // Hero text
                      Text(
                        'BECOME\nUNSTOP-\nPABLE.',
                        style: AppTheme.krona(size: 48, height: 1.05),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'AI-powered coaching that analyzes your\ngameplay and helps you rank up faster.',
                        style: AppTheme.inter(size: 14, color: AppTheme.textSecondary),
                      ),

                      const SizedBox(height: 48),

                      // Feature bullets
                      ...[
                        ('🎯', 'AI Coach — personalized tips'),
                        ('📊', 'Match analysis — round by round'),
                        ('🏆', 'Battlepass quests & XP tracking'),
                      ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Text(item.$1, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 12),
                          Text(item.$2, style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
                        ]),
                      )),

                      const SizedBox(height: 40),

                      // Sign in button
                      _PrimaryButton(
                        label: 'GET STARTED',
                        onTap: _signIn,
                      ),

                      const SizedBox(height: 14),

                      // Guest button
                      GestureDetector(
                        onTap: _skip,
                        child: Center(
                          child: Text(
                            'CONTINUE AS GUEST',
                            style: AppTheme.krona(
                              size: 11,
                              color: AppTheme.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(label, style: AppTheme.krona(size: 14, letterSpacing: 1.5)),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    const s = 44.0;
    for (double x = 0; x < size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
