import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'providers/app_providers.dart';
import 'services/cache_service.dart';
import 'screens/home_screen.dart';
import 'screens/match_analysis_screen.dart';
import 'screens/battlepass_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/riot_login_screen.dart';
import 'screens/clerk_sign_in_screen.dart';
import 'widgets/bottom_nav.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env not found — fall back to defaults in ApiConfig
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await CacheService().init();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(ProviderScope(child: ValoCoachApp(showOnboarding: !onboardingDone)));
}

class ValoCoachApp extends StatelessWidget {
  final bool showOnboarding;
  const ValoCoachApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    // ClerkAuth must wrap MaterialApp so widgets inside can access ClerkAuth.of(context)
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: ApiConfig.clerkPublishableKey),
      child: MaterialApp(
        title: 'ValoCoach.Ai',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: showOnboarding ? '/onboarding' : '/home',
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/home': (_) => const _AuthBridge(),
          '/clerk-login': (_) => const ClerkSignInScreen(),
          '/riot-login': (_) => const RiotLoginScreen(),
        },
      ),
    );
  }
}

/// Bridges Clerk auth state → Riverpod AuthNotifier.
/// Observes Clerk sign-in/out events and syncs them to our own provider.
class _AuthBridge extends ConsumerStatefulWidget {
  const _AuthBridge();

  @override
  ConsumerState<_AuthBridge> createState() => _AuthBridgeState();
}

class _AuthBridgeState extends ConsumerState<_AuthBridge> {
  String? _lastClerkUserId;

  @override
  Widget build(BuildContext context) {
    return ClerkAuthBuilder(
      builder: (context, authState) {
        // If Clerk is still initializing, show loading
        if (ClerkAuth.of(context, listen: true).isNotAvailable) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryRed),
                  SizedBox(height: 24),
                  Text('LOGGING IN...',
                      style: TextStyle(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        final userId = authState.client.user?.id;

        // Sync to Riverpod
        if (userId != null) {
          if (userId != _lastClerkUserId) {
            _lastClerkUserId = userId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(authProvider.notifier).setClerkUser(userId);
            });
          }
        } else {
          if (_lastClerkUserId != null) {
            _lastClerkUserId = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(authProvider.notifier).clearClerkUser();
            });
          }
        }

        return const AppShell();
      },
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = <Widget>[
    HomeScreen(),
    MatchAnalysisScreen(),
    BattlepassScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
