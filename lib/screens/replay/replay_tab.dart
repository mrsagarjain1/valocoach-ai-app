import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import '../../providers/replay_provider.dart';
import '../../config/app_theme.dart';
import 'replay_painter.dart';
import 'replay_utils.dart';

class ReplayTab extends ConsumerStatefulWidget {
  final String matchId;
  const ReplayTab({Key? key, required this.matchId}) : super(key: key);

  @override
  ConsumerState<ReplayTab> createState() => _ReplayTabState();
}

class _ReplayTabState extends ConsumerState<ReplayTab> {
  int _currentTimeMs = 0;
  int _durationMs = 0;
  int _selectedEventIdx = -1;
  
  Map<String, dynamic>? _matchData;
  Map<String, dynamic>? _currentRound;
  int _currentRoundIdx = 0;

  ui.Image? _mapImg;
  final Map<String, ui.Image> _agentImgs = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadMapImage(String mapName) async {
    final lowerName = mapName.toLowerCase();
    try {
      final imgData = await rootBundle.load('assets/location_maps/$lowerName.png');
      final codec = await ui.instantiateImageCodec(imgData.buffer.asUint8List());
      final frameInfo = await codec.getNextFrame();
      setState(() {
        _mapImg = frameInfo.image;
      });
    } catch (e) {
      print('Could not load map image: assets/location_maps/$lowerName.png');
    }
  }

  Future<void> _loadAgentImages(Map<String, dynamic> roster) async {
    for (var info in roster.values) {
      final agentName = normalizeAgent(info['agent'] ?? '');
      if (!_agentImgs.containsKey(agentName)) {
        try {
          final imgData = await rootBundle.load('assets/location_agents/$agentName.png');
          final codec = await ui.instantiateImageCodec(imgData.buffer.asUint8List());
          final frameInfo = await codec.getNextFrame();
          _agentImgs[agentName] = frameInfo.image;
        } catch (e) {
          print('Could not load agent image: $agentName ${e.toString()}');
        }
      }
    }
    setState(() {}); // trigger rebuild after images load
  }

  void _setRound(int idx) {
    if (_matchData == null) return;
    final rounds = _matchData!['rounds'] as List<dynamic>? ?? [];
    if (idx < 0 || idx >= rounds.length) return;
    
    setState(() {
      _currentRoundIdx = idx;
      _currentRound = rounds[idx];
      _currentTimeMs = 0;
      _selectedEventIdx = -1;
      _durationMs = getRoundDuration(_currentRound!);
    });
  }

  void _selectEvent(int idx, int timeMs) {
    setState(() {
      _selectedEventIdx = idx;
      _currentTimeMs = timeMs;
    });
  }

  String _weaponKey(String? weapon) {
    if (weapon == null || weapon.isEmpty) return 'classic';
    String key = weapon.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    if (key == 'tactical_knife' || key == 'knife') key = 'melee';
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(replayTimelineProvider(widget.matchId));

    return timelineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      error: (e, st) => Center(child: Text('Error loading replay: $e', style: AppTheme.inter(color: Colors.white))),
      data: (data) {
        if (data == null) {
          return Center(child: Text('No replay data available', style: AppTheme.inter(color: Colors.white)));
        }

        if (_matchData == null) {
          _matchData = data;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadMapImage(data['map'] ?? '');
            _loadAgentImages(data['roster'] ?? {});
            _setRound(0);
          });
        }

        final rounds = data['rounds'] as List<dynamic>? ?? [];
        final events = _currentRound?['events'] as List<dynamic>? ?? [];
        final actionEvents = events.where((e) => e['event_type'] != 'round_start').toList();
        final roster = data['roster'] as Map<String, dynamic>? ?? {};

        return Column(
          children: [
            // Top Half: Canvas
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: const Color(0xFF0A0E14),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: AspectRatio(
                    aspectRatio: 1, // square map
                    child: CustomPaint(
                      painter: _currentRound != null ? ReplayPainter(
                        mapImg: _mapImg,
                        agentImgs: _agentImgs,
                        round: _currentRound!,
                        timeMs: _currentTimeMs,
                        roster: roster,
                        mapName: data['map'] ?? '',
                        killFlashes: [], // Removed dynamic ticker flashes for static snapshots
                        nowTs: DateTime.now().millisecondsSinceEpoch,
                      ) : null,
                    ),
                  ),
                ),
              ),
            ),

            // Middle: Round Pills
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: AppTheme.darkBg,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rounds.length,
                itemBuilder: (context, idx) {
                  final active = idx == _currentRoundIdx;
                  return GestureDetector(
                    onTap: () => _setRound(idx),
                    child: Container(
                      width: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryRed : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${idx + 1}', style: AppTheme.krona(size: 13, color: active ? Colors.white : Colors.white54)),
                    ),
                  );
                },
              ),
            ),

            // Bottom: Kill Feed Event Log
            Expanded(
              flex: 4,
              child: Container(
                color: AppTheme.surfaceDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feed Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                      ),
                      child: Row(
                        children: [
                          Text('EVENT LOG', style: AppTheme.krona(size: 13, color: Colors.white, letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                          Text('${actionEvents.length} events', style: AppTheme.inter(size: 11, color: Colors.white54)),
                        ],
                      ),
                    ),

                    // Feed List
                    if (actionEvents.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text('No events in this round.', style: AppTheme.inter(color: Colors.white54, fontStyle: FontStyle.italic)),
                        ),
                      )
                    else 
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: actionEvents.length,
                          itemBuilder: (context, idx) {
                            final ev = actionEvents[idx];
                            final timeMs = ev['time_in_round_in_ms'] as int? ?? 0;
                            final type = ev['event_type'];
                            final active = idx == _selectedEventIdx;

                            Widget content = const SizedBox();

                            if (type == 'kill') {
                              final d = ev['event_data'];
                              final killerStr = d['killer']?.toString();
                              final victimStr = d['victim']?.toString();
                              final killerInfo = roster[killerStr];
                              final victimInfo = roster[victimStr];
                              
                              final killerColor = killerInfo?['team'] == 'Red' ? const Color(0xFFFF4654) : const Color(0xFF0FB5AE);
                              final victimColor = victimInfo?['team'] == 'Red' ? const Color(0xFFFF4654) : const Color(0xFF0FB5AE);
                              
                              final weaponKey = _weaponKey(d['weapon']);

                              content = Row(
                                children: [
                                  // Killer
                                  SizedBox(
                                    width: 80,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: killerColor, width: 2),
                                            color: const Color(0xFF1A1E28),
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/location_agents/${normalizeAgent(killerInfo?['agent'] ?? '')}.png',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const SizedBox(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(killerInfo?['name'] ?? 'UNKNOWN', 
                                          style: AppTheme.inter(size: 10, color: Colors.white, weight: FontWeight.w700),
                                          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Weapon & Time
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(formatMs(timeMs), style: AppTheme.inter(size: 11, color: Colors.white70, weight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Image.asset(
                                          'assets/weapons/${weaponKey}_killstream.png',
                                          height: 18,
                                          color: Colors.white,
                                          errorBuilder: (_, __, ___) => Text(
                                            d['weapon']?.toString().toUpperCase() ?? 'ABILITY',
                                            style: AppTheme.inter(size: 10, color: Colors.white54, weight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Victim
                                  SizedBox(
                                    width: 80,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: victimColor, width: 2),
                                            color: const Color(0xFF1A1E28),
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipOval(
                                                child: Image.asset(
                                                  'assets/location_agents/${normalizeAgent(victimInfo?['agent'] ?? '')}.png',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                                ),
                                              ),
                                              Container(
                                                color: Colors.black.withOpacity(0.5),
                                                alignment: Alignment.center,
                                                child: const Text('✕', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(victimInfo?['name'] ?? 'UNKNOWN', 
                                          style: AppTheme.inter(size: 10, color: Colors.white, weight: FontWeight.w700),
                                          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            } else if (type == 'plant') {
                              final d = ev['event_data'];
                              final planterInfo = roster[d['planted_by']?.toString()];
                              
                              content = Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.orange, width: 2),
                                      color: const Color(0xFF1A1E28),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/location_agents/${normalizeAgent(planterInfo?['agent'] ?? '')}.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const SizedBox(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(formatMs(timeMs), style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w800)),
                                  Expanded(
                                    child: Center(
                                      child: Text('● PLANTED', style: AppTheme.inter(size: 12, color: Colors.orange, weight: FontWeight.w900)),
                                    ),
                                  ),
                                  Text('SITE ${d['site']}', style: AppTheme.inter(size: 12, color: Colors.orange, weight: FontWeight.w800)),
                                  const SizedBox(width: 16),
                                ],
                              );
                            } else if (type == 'defuse') {
                              content = Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF0FB5AE), width: 2),
                                      color: const Color(0xFF1A1E28),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('🛡', style: TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(formatMs(timeMs), style: AppTheme.inter(size: 12, color: Colors.white, weight: FontWeight.w800)),
                                  Expanded(
                                    child: Center(
                                      child: Text('◆ DEFUSED', style: AppTheme.inter(size: 12, color: const Color(0xFF0FB5AE), weight: FontWeight.w900)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              );
                            }

                            final colorLine = type == 'plant' ? Colors.orange : (type == 'defuse' ? const Color(0xFF0FB5AE) : const Color(0xFFFF4654));

                            return GestureDetector(
                              onTap: () => _selectEvent(idx, timeMs),
                              child: Container(
                                height: 65,
                                decoration: BoxDecoration(
                                  color: active ? AppTheme.primaryRed.withOpacity(0.12) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
                                    left: BorderSide(color: active ? colorLine : Colors.transparent, width: 3),
                                  ),
                                ),
                                child: content,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
