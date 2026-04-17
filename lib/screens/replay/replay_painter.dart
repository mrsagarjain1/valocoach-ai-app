import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../config/app_theme.dart';
import 'replay_utils.dart';

class KillFlash {
  final double px;
  final double py;
  final int startTime;
  KillFlash({required this.px, required this.py, required this.startTime});
}

class ReplayPainter extends CustomPainter {
  final ui.Image? mapImg;
  final Map<String, ui.Image> agentImgs;
  final Map<String, dynamic> round;
  final int timeMs;
  final Map<String, dynamic> roster;
  final String mapName;
  final List<KillFlash> killFlashes;
  final int nowTs;

  static const Color redColor = Color(0xFFFF4654);
  static const Color blueColor = Color(0xFF0FB5AE);
  static const Color orangeColor = Color(0xFFeab308);

  ReplayPainter({
    required this.mapImg,
    required this.agentImgs,
    required this.round,
    required this.timeMs,
    required this.roster,
    required this.mapName,
    required this.killFlashes,
    required this.nowTs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final scale = W / 700.0;
    final pR = 14.0 * scale;
    final cR = 45.0 * scale;
    final coneA = math.pi / 2.4;

    // Background Map
    if (mapImg != null) {
      canvas.drawImageRect(
        mapImg!,
        Rect.fromLTWH(0, 0, mapImg!.width.toDouble(), mapImg!.height.toDouble()),
        Rect.fromLTWH(0, 0, W, H),
        Paint(),
      );
      canvas.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()..color = Colors.black.withOpacity(0.22));
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()..color = const Color(0xFF0A0E14));
    }

    // Process Deaths
    final deathMap = <String, Map<String, double>>{};
    final deathTimeMap = <String, Map<String, dynamic>>{};

    final events = (round['events'] as List<dynamic>?) ?? [];
    for (var ev in events) {
      if (ev['event_type'] == 'kill') {
        final d = ev['event_data'];
        if (d != null && d['victim_death_location'] != null) {
          final vic = d['victim'].toString();
          final loc = d['victim_death_location'];
          deathTimeMap[vic] = {
            'loc': {'x': (loc['x'] as num).toDouble(), 'y': (loc['y'] as num).toDouble()},
            'time': ev['time_in_round_in_ms'] as int
          };
          if ((ev['time_in_round_in_ms'] as int) <= timeMs) {
            deathMap[vic] = {'x': (loc['x'] as num).toDouble(), 'y': (loc['y'] as num).toDouble()};
          }
        }
      }
    }

    // Spike Plant
    final spike = getSpikeState(round, timeMs);
    if (spike['planted'] == true && spike['location'] != null) {
      final loc = spike['location'];
      final pxPy = gameToPixel((loc['x'] as num).toDouble(), (loc['y'] as num).toDouble(), mapName, W, H);
      final px = pxPy['px']!;
      final py = pxPy['py']!;

      final pulseProg = (nowTs / 700.0) % 1.0;
      final alpha = (math.sin(pulseProg * math.pi) * 0.55 * 255).toInt();
      final isDefused = spike['defused'] == true;
      final spikeColor = isDefused ? blueColor : orangeColor;

      canvas.drawCircle(
        Offset(px, py),
        (14.0 + pulseProg * 24.0) * scale,
        Paint()
          ..color = spikeColor.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * scale,
      );

      canvas.drawCircle(
        Offset(px, py),
        9.0 * scale,
        Paint()
          ..color = spikeColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );

      final textSpan = TextSpan(
        text: 'SITE ${spike['site'] ?? ''}',
        style: TextStyle(
          color: spikeColor,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontFamily: 'Inter',
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr, textAlign: TextAlign.center);
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py + 12 * scale));
    }

    // Kill flashes
    for (var flash in killFlashes) {
      final elapsed = nowTs - flash.startTime;
      if (elapsed >= 900) continue;
      final prog = elapsed / 900.0;
      
      final flashPaint = Paint()
        ..color = redColor.withOpacity((1 - prog) * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;
        
      canvas.drawCircle(Offset(flash.px, flash.py), (6.0 + prog * 28.0) * scale, flashPaint);
      
      if (prog < 0.35) {
        canvas.drawCircle(
          Offset(flash.px, flash.py), 
          (6.0 + prog * 28.0) * scale, 
          Paint()
            ..color = redColor.withOpacity((1 - prog / 0.35) * 0.18)
            ..style = PaintingStyle.fill
        );
      }
    }

    // Interpolate Positions
    final playerPositions = interpolatePlayers(round, timeMs);

    // View cones
    for (var entry in playerPositions.entries) {
      final idx = entry.key;
      final pos = entry.value;
      if (deathMap.containsKey(idx) || pos['is_alive'] != true || pos['x'] == null || pos['y'] == null || pos['view_radians'] == null) continue;
      
      final info = roster[idx];
      if (info == null) continue;

      final pxPy = gameToPixel(pos['x'], pos['y'], mapName, W, H);
      final px = pxPy['px']!;
      final py = pxPy['py']!;
      final angle = pos['view_radians'] - math.pi / 2;

      final isRed = info['team'] == 'Red';
      final baseConeColor = isRed ? redColor : blueColor;

      final gradient = ui.Gradient.radial(
        Offset(px, py),
        cR,
        [
          baseConeColor.withOpacity(0.3),
          baseConeColor.withOpacity(0.1),
          baseConeColor.withOpacity(0.0),
        ],
        [0.0, 0.6, 1.0],
      );

      final path = Path()
        ..moveTo(px, py)
        ..arcTo(
          Rect.fromCircle(center: Offset(px, py), radius: cR),
          angle - coneA / 2,
          coneA,
          false,
        )
        ..close();

      canvas.drawPath(path, Paint()..shader = gradient);
    }

    // Players
    for (var idx in roster.keys) {
      final info = roster[idx];
      if (info == null) continue;

      final isDead = deathMap.containsKey(idx);
      final pos = playerPositions[idx];
      final teamColor = info['team'] == 'Red' ? redColor : blueColor;
      
      String cleanAgentName = normalizeAgent(info['agent'] ?? '');
      final agentImg = agentImgs[cleanAgentName];

      if (isDead) {
        final loc = deathMap[idx]!;
        final pxPy = gameToPixel(loc['x']!, loc['y']!, mapName, W, H);
        final px = pxPy['px']!;
        final py = pxPy['py']!;

        if (agentImg != null) {
          canvas.save();
          final path = Path()..addOval(Rect.fromCircle(center: Offset(px, py), radius: pR * 0.9));
          canvas.clipPath(path);
          canvas.drawImageRect(
            agentImg,
            Rect.fromLTWH(0, 0, agentImg.width.toDouble(), agentImg.height.toDouble()),
            Rect.fromCircle(center: Offset(px, py), radius: pR * 0.9),
            Paint()..colorFilter = const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]), 
          );
          canvas.drawRect(Rect.fromLTWH(px-pR, py-pR, pR*2, pR*2), Paint()..color = Colors.black45);
          canvas.restore();
        } else {
          canvas.drawCircle(Offset(px, py), pR * 0.9, Paint()..color = const Color(0xFF1E1E2A));
        }

        canvas.drawCircle(Offset(px, py), pR * 0.9, Paint()..color = teamColor..style = PaintingStyle.stroke..strokeWidth = 1.5 * scale);
        
        final s = pR * 0.4;
        final xPaint = Paint()..color = Colors.white70..strokeWidth = 1.8 * scale..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(px - s, py - s), Offset(px + s, py + s), xPaint);
        canvas.drawLine(Offset(px + s, py - s), Offset(px - s, py + s), xPaint);
        continue;
      }

      double? px, py;
      if (pos != null && pos['x'] != null && pos['y'] != null) {
        final pp = gameToPixel(pos['x'], pos['y'], mapName, W, H);
        px = pp['px']; py = pp['py'];
      } else {
        final fut = deathTimeMap[idx];
        if (fut != null) {
          final pp = gameToPixel(fut['loc']['x'], fut['loc']['y'], mapName, W, H);
          px = pp['px']; py = pp['py'];
        }
      }
      
      if (px == null || py == null) continue;

      // Spike Carrier outer ring
      if (idx == round['spike_carrier'] && spike['planted'] != true) {
        canvas.drawCircle(
          Offset(px, py), 
          (pR + 5) * scale, 
          Paint()..color = orangeColor..style = PaintingStyle.stroke..strokeWidth = 1.5*scale
        );
      }

      // Drawing agent icon
      if (agentImg != null) {
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(px, py), radius: pR)));
        canvas.drawImageRect(
          agentImg,
          Rect.fromLTWH(0, 0, agentImg.width.toDouble(), agentImg.height.toDouble()),
          Rect.fromCircle(center: Offset(px, py), radius: pR),
          Paint(),
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(px, py), pR, Paint()..color = teamColor);
      }

      // Border with small shadow
      canvas.drawCircle(
        Offset(px, py), 
        pR, 
        Paint()
          ..color = teamColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * scale
      );

      // Name label
      final nameSpan = TextSpan(
        text: info['name'],
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(9, 10 * scale),
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          fontFamily: 'Inter',
          shadows: [Shadow(blurRadius: 5, color: Colors.black.withOpacity(0.95))]
        ),
      );
      final tp2 = TextPainter(text: nameSpan, textDirection: TextDirection.ltr, textAlign: TextAlign.center);
      tp2.layout();
      tp2.paint(canvas, Offset(px - tp2.width / 2, py + pR + 3 * scale));
    }
  }

  @override
  bool shouldRepaint(covariant ReplayPainter oldDelegate) {
    return timeMs != oldDelegate.timeMs || killFlashes.length != oldDelegate.killFlashes.length;
  }
}
