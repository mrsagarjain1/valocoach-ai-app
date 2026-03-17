import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'providers/app_providers.dart';
import 'services/cache_service.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/battlepass_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/riot_login_screen.dart';
import 'widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surfaceDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await CacheService().init();

  // Check if onboarding has been shown
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(ProviderScope(child: ValoCoachApp(showOnboarding: !onboardingDone)));
}

class ValoCoachApp extends StatelessWidget {
  final bool showOnboarding;
  const ValoCoachApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValoCoach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: showOnboarding ? '/onboarding' : '/home',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/home': (_) => const AppShell(),
        '/riot-login': (_) => const RiotLoginScreen(),
      },
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = <Widget>[
    HomeScreen(),
    StatisticsScreen(),
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
