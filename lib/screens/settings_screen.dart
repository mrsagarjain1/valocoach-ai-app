import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import 'riot_login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),

                // ── Header ─────────────────────────────
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SETTINGS', style: AppTheme.krona(size: 24)),
                    const SizedBox(height: 4),
                    Text('Account & preferences', style: AppTheme.inter(size: 13, color: AppTheme.textSecondary)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
                    child: const Icon(Icons.settings_rounded, color: AppTheme.textMuted, size: 18),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Clerk Account Block ─────────────────
                _SectionLabel('ACCOUNT'),
                const SizedBox(height: 10),
                _ClerkBlock(auth: auth, ref: ref),

                const SizedBox(height: 20),

                // ── Riot Link Block ─────────────────────
                _SectionLabel('RIOT ACCOUNT'),
                const SizedBox(height: 10),
                _RiotBlock(auth: auth, ref: ref),

                const SizedBox(height: 20),

                // ── Premium Status ──────────────────────
                _SectionLabel('MEMBERSHIP'),
                const SizedBox(height: 10),
                _PremiumCard(isLinked: auth.isRiotLinked, isPremium: auth.isPremium),

                const SizedBox(height: 20),

                // ── General ────────────────────────────
                _SectionLabel('GENERAL'),
                const SizedBox(height: 10),
                _GroupBox(children: [
                  _Row(icon: Icons.info_outline_rounded, label: 'About ValoCoach'),
                  _Row(icon: Icons.shield_outlined, label: 'Privacy Policy'),
                  _Row(icon: Icons.mail_outline_rounded, label: 'Contact Support'),
                ]),

                const SizedBox(height: 20),

                // ── Data ───────────────────────────────
                _SectionLabel('DATA'),
                const SizedBox(height: 10),
                _GroupBox(children: [
                  _Row(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear Cache',
                    onTap: () async {
                      await ref.read(cacheServiceProvider).clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cache cleared', style: AppTheme.inter(size: 13)),
                            backgroundColor: AppTheme.accentGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                // ── Sign Out ───────────────────────────
                if (auth.isClerkSignedIn)
                  GestureDetector(
                    onTap: () async {
                      // Sign out from both Clerk SDK and Riverpod
                      await ClerkAuth.of(context).signOut();
                      if (context.mounted) {
                        ref.read(authProvider.notifier).signOut();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.25)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.logout_rounded, color: AppTheme.primaryRed, size: 18),
                        const SizedBox(width: 10),
                        Text('SIGN OUT', style: AppTheme.krona(size: 12, color: AppTheme.primaryRed, letterSpacing: 1)),
                      ]),
                    ),
                  ),

                const SizedBox(height: 20),
                Center(child: Text('ValoCoach v1.0.0', style: AppTheme.inter(size: 12, color: AppTheme.textMuted))),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Clerk Block ──────────────────────────────────────────────────────────────

class _ClerkBlock extends StatelessWidget {
  final AuthState auth;
  final WidgetRef ref;
  const _ClerkBlock({required this.auth, required this.ref});

  @override
  Widget build(BuildContext context) {
    final signedOutGradient = const LinearGradient(
      colors: [Color(0xFF1E1128), Color(0xFF130D26)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final signedInGradient = const LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF18282C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: auth.isClerkSignedIn ? signedInGradient : signedOutGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: auth.isClerkSignedIn 
            ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
            : const Color(0xFF7C3AED).withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        if (auth.isClerkSignedIn)
           const ClerkUserButton()
        else
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF9D4EDD), Color(0xFF5A189A)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            auth.isClerkSignedIn ? 'SIGNED IN' : 'NOT SIGNED IN',
            style: AppTheme.krona(
              size: 11,
              color: auth.isClerkSignedIn ? const Color(0xFF00E5FF) : const Color(0xFFC77DFF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            auth.isClerkSignedIn ? 'Active session' : 'Sign in to access premium features',
            style: AppTheme.inter(size: 11, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ])),
        if (!auth.isClerkSignedIn)
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/clerk-login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text('SIGN IN', style: AppTheme.krona(size: 10, color: Colors.white, letterSpacing: 1)),
            ),
          ),
      ]),
    );
  }
}

// ─── Riot Block ───────────────────────────────────────────────────────────────

class _RiotBlock extends StatelessWidget {
  final AuthState auth;
  final WidgetRef ref;
  const _RiotBlock({required this.auth, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: auth.isRiotLinked ? AppTheme.accentGreen.withValues(alpha: 0.2) : AppTheme.borderColor),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: auth.isRiotLinked ? AppTheme.accentGreen.withValues(alpha: 0.12) : AppTheme.primaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sports_esports_rounded, size: 20, color: auth.isRiotLinked ? AppTheme.accentGreen : AppTheme.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              auth.isRiotLinked ? 'RIOT: LINKED' : 'RIOT: NOT LINKED',
              style: AppTheme.krona(size: 11, color: auth.isRiotLinked ? AppTheme.accentGreen : AppTheme.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              auth.isRiotLinked ? (auth.riotPuuid ?? 'Account linked') : 'Link your Riot account for full features',
              style: AppTheme.inter(size: 11, color: AppTheme.textMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ])),
        ]),

        const SizedBox(height: 14),

        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.of(context).push<Map<String, String>?>(
                  MaterialPageRoute(builder: (_) => const RiotLoginScreen()),
                );
                if (result != null && context.mounted) {
                  await ref.read(authProvider.notifier).linkRiotAccount(
                    result['puuid'] ?? '',
                    result['token'] ?? '',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Riot account linked!', style: AppTheme.inter(size: 13)),
                        backgroundColor: AppTheme.accentGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: auth.isRiotLinked ? null : AppTheme.primaryGradient,
                  color: auth.isRiotLinked ? AppTheme.borderColor : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    auth.isRiotLinked ? 'RE-LINK RIOT' : 'LINK RIOT ACCOUNT',
                    style: AppTheme.krona(size: 10, letterSpacing: 1,
                        color: auth.isRiotLinked ? AppTheme.textMuted : Colors.white),
                  ),
                ),
              ),
            ),
          ),
          if (auth.isRiotLinked) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => ref.read(authProvider.notifier).unlinkRiot(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2)),
                ),
                child: Text('UNLINK', style: AppTheme.krona(size: 10, color: AppTheme.primaryRed, letterSpacing: 1)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ─── Premium Card ─────────────────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  final bool isLinked;
  final bool isPremium;
  const _PremiumCard({required this.isLinked, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isPremium ? AppTheme.accentYellow.withValues(alpha: 0.2) : AppTheme.borderColor),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPremium ? AppTheme.accentYellow.withValues(alpha: 0.12) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.workspace_premium_rounded, color: isPremium ? AppTheme.accentYellow : AppTheme.textMuted, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PREMIUM STATUS', style: AppTheme.krona(size: 11, color: isPremium ? AppTheme.accentYellow : AppTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(
            isPremium ? 'Full access unlocked' : (isLinked ? 'Upgrade to Premium' : 'Sign in to access premium features'),
            style: AppTheme.inter(size: 11, color: AppTheme.textSecondary),
          ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isPremium ? AppTheme.accentYellow.withValues(alpha: 0.1) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isPremium ? 'ACTIVE' : 'FREE',
            style: AppTheme.krona(size: 9, color: isPremium ? AppTheme.accentYellow : AppTheme.textMuted, letterSpacing: 1),
          ),
        ),
      ]),
    );
  }
}

// ─── Section helpers ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTheme.krona(size: 10, color: AppTheme.textMuted, letterSpacing: 2));
}

class _GroupBox extends StatelessWidget {
  final List<Widget> children;
  const _GroupBox({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.borderColor)),
      child: Column(
        children: List.generate(children.length, (i) => Column(children: [
          children[i],
          if (i < children.length - 1) const Divider(height: 1, indent: 18, endIndent: 18, color: AppTheme.borderColor),
        ])),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Row({required this.icon, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTheme.inter(size: 14, weight: FontWeight.w500))),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}
