import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import 'statistics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'ap';
  static const _regions = [
    {'code': 'ap', 'label': 'ASIA PACIFIC'},
    {'code': 'eu', 'label': 'EUROPE'},
    {'code': 'na', 'label': 'N. AMERICA'},
  ];
  late AnimationController _heroCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _cardSlide;
  late PageController _carouselCtrl;
  late Timer _carouselTimer;
  int _carouselPage = 0;
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, String>> _history = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });
    _carouselCtrl = PageController();
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      final next = (_carouselPage + 1) % 3;
      _carouselCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
    
    _searchFocus.addListener(() {
      setState(() => _showHistory = _searchFocus.hasFocus && _history.isNotEmpty);
    });

    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final cache = ref.read(cacheServiceProvider);
    setState(() {
      _history = cache.getSearchHistory();
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _carouselCtrl.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _heroCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final input = _searchController.text.trim();
    if (input.isEmpty) return;
    final parts = input.split('#');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Use Name#Tag format (e.g. Player#1234)', style: AppTheme.inter(size: 13)),
        backgroundColor: AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    final cleanName = parts[0].trim().replaceAll(RegExp(r'\s+'), '');
    final cleanTag = parts[1].trim().replaceAll(RegExp(r'\s+'), '');
    
    // Save to history
    ref.read(cacheServiceProvider).addToSearchHistory(cleanName, cleanTag, _selectedRegion);
    _loadSearchHistory(); // Refresh local list

    ref.read(playerStatsProvider.notifier).searchPlayer(cleanName, cleanTag, region: _selectedRegion);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatisticsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Background glow layers
          Positioned(
            top: -80,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryRed.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _heroFade,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HERO CAROUSEL ─────────────────────────────────────
                    _HeroCarousel(
                      pageCtrl: _carouselCtrl,
                      currentPage: _carouselPage,
                      onPageChanged: (p) => setState(() => _carouselPage = p),
                    ),

                    // ── SEARCH SECTION ────────────────────────────────────
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section label
                              Row(children: [
                                Container(
                                  width: 3,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('PLAYER LOOKUP',
                                    style: AppTheme.krona(size: 12, color: Colors.white70, letterSpacing: 1.5)),
                              ]),
                              const SizedBox(height: 16),

                              // Search bar + History Dropdown
                              _SearchBar(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                onSearch: _onSearch,
                              ),

                              if (_showHistory) ...[
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.borderColor),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                        child: Text('RECENT SEARCHES', style: AppTheme.inter(size: 9, color: AppTheme.textMuted, weight: FontWeight.w700, letterSpacing: 1)),
                                      ),
                                      ..._history.map((h) => ListTile(
                                        visualDensity: VisualDensity.compact,
                                        leading: const Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 18),
                                        title: Text('${h['name']}#${h['tag']}', style: AppTheme.inter(size: 13, weight: FontWeight.w600)),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryRed.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(h['region']!.toUpperCase(), style: AppTheme.krona(size: 8, color: AppTheme.primaryRed)),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _searchController.text = '${h['name']}#${h['tag']}';
                                            _selectedRegion = h['region']!;
                                            _showHistory = false;
                                            _searchFocus.unfocus();
                                          });
                                        },
                                      )),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Region selector
                              Text('SELECT REGION',
                                  style: AppTheme.inter(
                                      size: 9,
                                      color: AppTheme.textMuted,
                                      weight: FontWeight.w700,
                                      letterSpacing: 1.5)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _regions.map((r) {
                                  final code = r['code']!;
                                  final label = r['label']!;
                                  final sel = _selectedRegion == code;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedRegion = code),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: sel
                                            ? AppTheme.primaryGradient
                                            : null,
                                        color: sel ? null : AppTheme.cardBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: sel
                                              ? AppTheme.primaryRed
                                              : AppTheme.borderColor,
                                        ),
                                        boxShadow: sel
                                            ? [
                                                BoxShadow(
                                                    color: AppTheme.primaryRed.withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3))
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        label,
                                        style: AppTheme.krona(
                                          size: 9,
                                          color: sel ? Colors.white : AppTheme.textMuted,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 36),

                              // Features
                              Row(children: [
                                Container(
                                  width: 3,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('VALOCOACH FEATURES',
                                    style: AppTheme.krona(size: 12, color: Colors.white70, letterSpacing: 1.5)),
                              ]),
                              const SizedBox(height: 16),

                              _FeatureCard(
                                icon: Icons.auto_awesome_rounded,
                                title: 'AI COACH',
                                subtitle: 'Personalized performance analysis and tips to climb ranks faster',
                                iconColor: const Color(0xFFB78BFA),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A0533), Color(0xFF2D1065)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderColor: const Color(0xFF7C3AED),
                                tag: 'AI POWERED',
                                tagColor: const Color(0xFFB78BFA),
                              ),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                  child: _SmallFeatureCard(
                                    icon: Icons.analytics_outlined,
                                    title: 'MATCH\nANALYSIS',
                                    iconColor: AppTheme.accentGreen,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF021A0E), Color(0xFF04321A)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderColor: AppTheme.accentGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SmallFeatureCard(
                                    icon: Icons.military_tech_rounded,
                                    title: 'BATTLEPASS\n& QUESTS',
                                    iconColor: AppTheme.accentYellow,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1A1000), Color(0xFF332000)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderColor: AppTheme.accentYellow,
                                  ),
                                ),
                              ]),

                              const SizedBox(height: 36),

                              // Tip banner
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderColor),
                                  borderRadius: BorderRadius.circular(16),
                                  color: AppTheme.cardBg,
                                ),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentYellow.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.tips_and_updates_rounded,
                                        color: AppTheme.accentYellow, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PRO TIP', style: AppTheme.krona(size: 10, color: AppTheme.accentYellow, letterSpacing: 1)),
                                      const SizedBox(height: 3),
                                      Text('Sign in to unlock your AI-powered battlepass with daily quests and XP rewards.',
                                          style: AppTheme.inter(size: 11, color: AppTheme.textSecondary)),
                                    ],
                                  )),
                                ]),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Carousel ────────────────────────────────────────────────────────────

/// Data for each carousel slide
class _CarouselSlide {
  final String headline;
  final String subline;
  final String agentAsset; // local asset path
  final List<Color> gradientColors;
  final Color accentColor;
  const _CarouselSlide({
    required this.headline,
    required this.subline,
    required this.agentAsset,
    required this.gradientColors,
    required this.accentColor,
  });
}

const _slides = [
  _CarouselSlide(
    headline: 'DOMINATE\nYOUR RANK.',
    subline: 'AI-powered coaching • Real-time stats',
    agentAsset: 'assets/agents/jett.png',
    gradientColors: [Color(0xFF1C0014), Color(0xFF280018), Color(0xFF0D0D12)],
    accentColor: Color(0xFFFF4655),
  ),
  _CarouselSlide(
    headline: 'AI COACH\nYOUR PLAYS.',
    subline: 'Personalised analysis after every match',
    agentAsset: 'assets/agents/reyna.png',
    gradientColors: [Color(0xFF120A2E), Color(0xFF1E0F4A), Color(0xFF0D0D12)],
    accentColor: Color(0xFFB78BFA),
  ),
  _CarouselSlide(
    headline: 'TRACK EVERY\nSTAT.',
    subline: 'Deep round analytics • Match history',
    agentAsset: 'assets/agents/killjoy.png',
    gradientColors: [Color(0xFF001A0E), Color(0xFF002D18), Color(0xFF0D0D12)],
    accentColor: Color(0xFF16C47F),
  ),
];

class _HeroCarousel extends StatelessWidget {
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  const _HeroCarousel({
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: Stack(
        children: [
          // ── Sliding pages ────────────────────────────────────────
          PageView.builder(
            controller: pageCtrl,
            onPageChanged: onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (_, i) => _CarouselPage(
              slide: _slides[i],
              slideIndex: i,
            ),
          ),

          // ── Dot indicators ───────────────────────────────────────
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? _slides[currentPage].accentColor
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselPage extends StatelessWidget {
  final _CarouselSlide slide;
  final int slideIndex;
  const _CarouselPage({required this.slide, required this.slideIndex});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // Grid overlay
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),

        // Accent circle
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: slide.accentColor.withValues(alpha: 0.12), width: 40),
            ),
          ),
        ),

        // Agent art
        Positioned(
          right: -8,
          bottom: 0,
          top: 0,
          child: Opacity(
            opacity: 0.60,
            child: Image.asset(
              slide.agentAsset,
              height: 262,
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),

        // Right fade
        Positioned(
          right: 0, top: 0, bottom: 0, width: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, slide.gradientColors.last],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),

        // Content — left-aligned, right margin leaves room for agent art
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 155, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── LOGO ──────────────────────────────────────────
                SizedBox(
                  height: 26,
                  child: Image.asset(
                    'assets/main_png_logo.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    errorBuilder: (_, __, ___) => _LogoFallback(),
                  ),
                ),

                const Spacer(),

                // Accent category chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: slide.accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: slide.accentColor.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    ['PERFORMANCE', 'AI COACHING', 'ANALYTICS'][slideIndex % 3],
                    style: AppTheme.inter(size: 8, color: slide.accentColor,
                        weight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 8),

                // Headline
                Text(
                  slide.headline,
                  style: AppTheme.krona(size: 26, height: 1.08, color: Colors.white),
                ),
                const SizedBox(height: 8),

                // Subline
                Text(
                  slide.subline,
                  style: AppTheme.inter(size: 11, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fallback styled-text logo shown if PNG asset is missing
class _LogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('VALOCOACH', style: AppTheme.krona(size: 14, letterSpacing: 2)),
      const SizedBox(width: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
        ),
        child: Text('.AI', style: AppTheme.krona(size: 10, color: const Color(0xFFB78BFA))),
      ),
    ]);
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final FocusNode? focusNode;
  const _SearchBar({required this.controller, required this.onSearch, this.focusNode});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focused ? AppTheme.primaryRed.withValues(alpha: 0.6) : AppTheme.borderColor,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                      color: AppTheme.primaryRed.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(Icons.search_rounded,
                color: _focused ? AppTheme.primaryRed : AppTheme.textMuted, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: AppTheme.inter(size: 15, weight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'PlayerName#Tag',
                hintStyle: AppTheme.inter(color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              onSubmitted: (_) => widget.onSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),
          GestureDetector(
            onTap: widget.onSearch,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text('SEARCH', style: AppTheme.krona(size: 10, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Feature Cards ────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color iconColor, borderColor;
  final LinearGradient gradient;
  final String? tag;
  final Color? tagColor;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.borderColor,
    required this.gradient,
    this.tag,
    this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: borderColor.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(children: [
        Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          if (tag != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: (tagColor ?? iconColor).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(tag!,
                  style: AppTheme.inter(
                      size: 7, color: tagColor ?? iconColor, weight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ]
        ]),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTheme.krona(size: 14, color: Colors.white, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTheme.inter(size: 12, color: AppTheme.textSecondary), maxLines: 2),
        ])),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios_rounded, color: iconColor.withValues(alpha: 0.6), size: 16),
      ]),
    );
  }
}

class _SmallFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor, borderColor;
  final LinearGradient gradient;

  const _SmallFeatureCard({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.borderColor,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 14),
        Text(title,
            style: AppTheme.krona(size: 11, color: Colors.white, height: 1.2, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Row(children: [
          Text('VIEW', style: AppTheme.inter(size: 9, color: iconColor, weight: FontWeight.w800)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 10, color: iconColor),
        ]),
      ]),
    );
  }
}

// ─── Grid Painter ────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.03)
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
