import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../config/app_theme.dart';

/// Full Clerk sign-in / sign-up screen using the SDK's ClerkAuthentication widget.
class ClerkSignInScreen extends StatelessWidget {
  const ClerkSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0010), Color(0xFF220016), Color(0xFF0D0D0D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),

          // ── Red glow ─────────────────────────────────────────
          Positioned(
            top: -60, left: -40,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryRed.withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back / close ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textPrimary),
                    ),
                  ),
                ),

                // ── Branding ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text('VALOCOACH', style: AppTheme.krona(size: 14, letterSpacing: 1.5)),
                      ]),
                      const SizedBox(height: 16),
                      Text('SIGN IN', style: AppTheme.krona(size: 32)),
                      const SizedBox(height: 6),
                      Text(
                        'Access AI coaching, match analysis & battlepass',
                        style: AppTheme.inter(size: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Clerk Authentication Widget with dark theme ──
                Expanded(
                  child: ClerkAuthBuilder(
                    builder: (context, authState) {
                      // If signed in, pop the screen automatically.
                      // This avoids the user seeing the lingering 'server error' that happens
                      // after the OAuth redirect is complete but the SDK throws an exception.
                      if (authState.client.user != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        });
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppTheme.accentGreen, size: 48),
                              const SizedBox(height: 16),
                              Text('Signed In Successfully!', style: AppTheme.krona(size: 16, color: AppTheme.accentGreen)),
                            ],
                          ),
                        );
                      }

                      return ClerkErrorListener(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            extensions: [
                              ClerkThemeExtension(
                                colors: const ClerkThemeColors(
                                  background: AppTheme.cardBg,
                                  altBackground: AppTheme.surfaceDark,
                                  borderSide: AppTheme.borderColor,
                                  text: AppTheme.textPrimary,
                                  icon: AppTheme.textSecondary,
                                  lightweightText: AppTheme.textMuted,
                                  error: AppTheme.primaryRed,
                                  accent: AppTheme.primaryRed,
                                ),
                              ),
                            ],
                          ),
                          child: const ClerkAuthentication(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
