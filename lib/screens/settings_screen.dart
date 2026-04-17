import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import 'package:dio/dio.dart';
import 'riot_login_screen.dart';
import '../widgets/premium_modal.dart';

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
                _PremiumCard(
                  isLinked: auth.isRiotLinked,
                  isPremium: auth.isPremium,
                  isSyncing: auth.isSyncing,
                  daysRemaining: auth.daysRemaining,
                  subscriptionEnd: auth.subscriptionEnd,
                ),

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
    if (!auth.isClerkSignedIn) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryRed, size: 28),
          ),
          const SizedBox(height: 16),
          Text('NOT SIGNED IN', style: AppTheme.krona(size: 14, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('Sign in to track your progress and stats', style: AppTheme.inter(size: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/clerk-login'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('SIGN IN', style: AppTheme.krona(size: 12, letterSpacing: 1.5))),
            ),
          ),
        ]),
      );
    }

    final user = ClerkAuth.of(context).user;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.5), width: 2),
              image: (user?.imageUrl) != null 
                ? DecorationImage(image: NetworkImage(user!.imageUrl!), fit: BoxFit.cover)
                : null,
            ),
            child: (user?.imageUrl) == null ? const Icon(Icons.person, size: 32) : null,
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.firstName ?? (user?.username ?? 'Agent'), 
                style: AppTheme.krona(size: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              (user?.emailAddresses != null && user!.emailAddresses!.isNotEmpty)
                ? user.emailAddresses![0].emailAddress
                : 'Connected Account', 
              style: AppTheme.inter(size: 12, color: AppTheme.textSecondary), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
            ),
          ])),
        ]),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.borderColor),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            await ClerkAuth.of(context).signOut();
            ref.read(authProvider.notifier).signOut();
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.logout_rounded, color: AppTheme.primaryRed, size: 18),
            const SizedBox(width: 8),
            Text('SIGN OUT', style: AppTheme.krona(size: 11, color: AppTheme.primaryRed, letterSpacing: 1)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Riot Block ───────────────────────────────────────────────────────────────

class _RiotBlock extends StatefulWidget {
  final AuthState auth;
  final WidgetRef ref;
  const _RiotBlock({required this.auth, required this.ref});

  @override
  State<_RiotBlock> createState() => _RiotBlockState();
}

class _RiotBlockState extends State<_RiotBlock> {
  bool _isLinking = false;

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final isBusy = auth.isSyncing || _isLinking;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: auth.isRiotLinked 
            ? AppTheme.accentGreen.withValues(alpha: 0.3) 
            : AppTheme.borderColor,
          width: auth.isRiotLinked ? 1.5 : 1,
        ),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isBusy 
                ? AppTheme.accentBlue.withValues(alpha: 0.1)
                : auth.isRiotLinked 
                  ? AppTheme.accentGreen.withValues(alpha: 0.1) 
                  : AppTheme.primaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isBusy 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.accentBlue, strokeWidth: 2))
              : Icon(Icons.sports_esports_rounded, 
                  size: 24, 
                  color: auth.isRiotLinked ? AppTheme.accentGreen : AppTheme.textMuted),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isBusy ? 'LINKING...' : (auth.isRiotLinked ? 'RIOT ACCOUNT LINKED' : 'RIOT ACCOUNT'),
              style: AppTheme.krona(size: 12, 
                  color: isBusy ? AppTheme.accentBlue : (auth.isRiotLinked ? AppTheme.accentGreen : Colors.white), 
                  letterSpacing: 0.5),
            ),
            if (isBusy) ...[
              const SizedBox(height: 4),
              Text(
                _isLinking ? 'Verifying with server...' : 'Fetching latest stats...',
                style: AppTheme.inter(size: 12, color: AppTheme.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ] else if (!auth.isRiotLinked) ...[
              const SizedBox(height: 4),
              Text(
                'Connect your account to track progress',
                style: AppTheme.inter(size: 12, color: AppTheme.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ] else if (auth.riotPuuid != null) ...[
              const SizedBox(height: 4),
              Text(
                'PUUID: ${auth.riotPuuid!}',
                style: AppTheme.inter(size: 10, color: AppTheme.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ])),
          if (auth.isRiotLinked && !isBusy)
            const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 22),
        ]),

        if (!auth.isRiotLinked && !isBusy) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.of(context).push<Map<String, String>?>(
                MaterialPageRoute(builder: (_) => const RiotLoginScreen()),
              );

              if (result != null && result['puuid'] != null && result['token'] != null) {
                if (!mounted) return;
                setState(() => _isLinking = true);
                try {
                  await widget.ref.read(authProvider.notifier).linkRiot(
                    puuid: result['puuid']!,
                    token: result['token']!,
                  );
                } on DioException catch (e) {
                  if (context.mounted) {
                    String msg = 'An error occurred';
                    if (e.response?.statusCode == 502) {
                       msg = 'Server is waking up. Please try again in 30 seconds.';
                    } else if (e.response?.statusCode == 409) {
                       msg = 'This Riot account is already linked to another player.';
                       if (e.response?.data is Map && e.response?.data['error'] != null) {
                         msg = e.response?.data['error']?.toString() ?? msg;
                       }
                    } else if (e.response?.data != null && e.response!.data is Map) {
                       msg = e.response!.data['error']?.toString() ?? e.response!.data.toString();
                    } else {
                       msg = e.message ?? e.toString();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Linking failed: $msg'), backgroundColor: AppTheme.primaryRed),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Linking failed: $e'), backgroundColor: AppTheme.primaryRed),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLinking = false);
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('LINK RIOT ACCOUNT', style: AppTheme.krona(size: 11, letterSpacing: 1.5))),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Premium Card ─────────────────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  final bool isLinked;
  final bool isPremium;
  final bool isSyncing;
  final int? daysRemaining;
  final DateTime? subscriptionEnd;

  const _PremiumCard({
    required this.isLinked,
    required this.isPremium,
    required this.isSyncing,
    this.daysRemaining,
    this.subscriptionEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!isPremium && !isSyncing) {
          showPremiumModal(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isPremium ? AppTheme.accentYellow.withValues(alpha: 0.2) : AppTheme.borderColor),
          boxShadow: !isPremium ? [] : [
            BoxShadow(color: AppTheme.accentYellow.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2),
            BoxShadow(color: AppTheme.accentYellow.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 0),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPremium ? AppTheme.accentYellow.withValues(alpha: 0.12) : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isSyncing 
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.textMuted, strokeWidth: 2))
                : Icon(Icons.workspace_premium_rounded, color: isPremium ? AppTheme.accentYellow : AppTheme.textMuted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PREMIUM STATUS', style: AppTheme.krona(size: 11, color: isPremium ? AppTheme.accentYellow : (isSyncing ? AppTheme.accentBlue : AppTheme.textMuted), letterSpacing: 0.5)),
            const SizedBox(height: 4),
            if (isSyncing)
              Text(
                'Checking subscription...',
                style: AppTheme.inter(size: 11, color: AppTheme.textSecondary),
              )
            else if (isPremium && daysRemaining != null)
              Text(
                'Active ($daysRemaining days left)',
                style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w600),
              )
            else
              Text(
                isPremium ? 'Full access unlocked' : (isLinked ? 'Upgrade to Premium • Tap to join' : 'Sign in to access premium features'),
                style: AppTheme.inter(size: 11, color: AppTheme.textSecondary),
              ),
            if (isPremium && subscriptionEnd != null && !isSyncing)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Expires: ${subscriptionEnd!.year}-${subscriptionEnd!.month.toString().padLeft(2, '0')}-${subscriptionEnd!.day.toString().padLeft(2, '0')}',
                  style: AppTheme.inter(size: 10, color: AppTheme.textMuted),
                ),
              ),
          ])),
          if (isSyncing)
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'SYNCING',
                style: AppTheme.krona(size: 9, color: AppTheme.accentBlue, letterSpacing: 0.5),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isPremium ? AppTheme.accentYellow.withValues(alpha: 0.1) : AppTheme.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: !isPremium ? AppTheme.primaryRed.withValues(alpha: 0.3) : Colors.transparent),
              ),
              child: Text(
                isPremium ? 'ACTIVE' : 'JOIN',
                style: AppTheme.krona(size: 9, color: isPremium ? AppTheme.accentYellow : AppTheme.primaryRed, letterSpacing: 0.5),
              ),
            ),
        ]),
      ),
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
