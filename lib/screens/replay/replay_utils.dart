import 'dart:math' as math;

class MapTransform {
  final double xMultiplier;
  final double yMultiplier;
  final double xScalarToAdd;
  final double yScalarToAdd;

  const MapTransform({
    required this.xMultiplier,
    required this.yMultiplier,
    required this.xScalarToAdd,
    required this.yScalarToAdd,
  });
}

const mapConfigs = <String, MapTransform>{
  'Haven': MapTransform(xMultiplier: 7.5e-5, yMultiplier: -7.5e-5, xScalarToAdd: 1.09345, yScalarToAdd: 0.642728),
  'Ascent': MapTransform(xMultiplier: 7e-5, yMultiplier: -7e-5, xScalarToAdd: 0.813895, yScalarToAdd: 0.573242),
  'Split': MapTransform(xMultiplier: 7.8e-5, yMultiplier: -7.8e-5, xScalarToAdd: 0.842188, yScalarToAdd: 0.697578),
  'Fracture': MapTransform(xMultiplier: 7.8e-5, yMultiplier: -7.8e-5, xScalarToAdd: 0.556952, yScalarToAdd: 1.155886),
  'Bind': MapTransform(xMultiplier: 5.9e-5, yMultiplier: -5.9e-5, xScalarToAdd: 0.576941, yScalarToAdd: 0.967566),
  'Breeze': MapTransform(xMultiplier: 7e-5, yMultiplier: -7e-5, xScalarToAdd: 0.465123, yScalarToAdd: 0.833078),
  'Icebox': MapTransform(xMultiplier: 7.2e-5, yMultiplier: -7.2e-5, xScalarToAdd: 0.460214, yScalarToAdd: 0.304687),
  'Pearl': MapTransform(xMultiplier: 7.8e-5, yMultiplier: -7.8e-5, xScalarToAdd: 0.480469, yScalarToAdd: 0.916016),
  'Lotus': MapTransform(xMultiplier: 7.2e-5, yMultiplier: -7.2e-5, xScalarToAdd: 0.454789, yScalarToAdd: 0.917752),
  'Sunset': MapTransform(xMultiplier: 7.8e-5, yMultiplier: -7.8e-5, xScalarToAdd: 0.5, yScalarToAdd: 0.515625),
  'Abyss': MapTransform(xMultiplier: 8.1e-5, yMultiplier: -8.1e-5, xScalarToAdd: 0.5, yScalarToAdd: 0.5),
  'Corrode': MapTransform(xMultiplier: 7e-5, yMultiplier: -7e-5, xScalarToAdd: 0.526158, yScalarToAdd: 0.5),
};

String formatMs(int ms) {
  final totalS = ms ~/ 1000;
  final m = totalS ~/ 60;
  final s = totalS % 60;
  return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
}

String normalizeAgent(String agent) {
  return agent.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_');
}

Map<String, double> gameToPixel(dynamic xRaw, dynamic yRaw, String mapName, double width, double height) {
  final config = mapConfigs[mapName];
  if (config == null) return {'px': 0.0, 'py': 0.0};
  
  final x = (xRaw as num).toDouble();
  final y = (yRaw as num).toDouble();

  // NOTE: The formula SWAPS game_x and game_y as per API spec
  final nx = y * config.xMultiplier + config.xScalarToAdd;
  final ny = x * config.yMultiplier + config.yScalarToAdd;
  return {
    'px': nx * width,
    'py': ny * height,
  };
}

int getRoundDuration(Map<String, dynamic> round) {
  if (round['events'] == null) return 0;
  final events = round['events'] as List<dynamic>;
  if (events.isEmpty) return 0;
  int maxT = 0;
  for (var ev in events) {
    int t = ev['time_in_round_in_ms'] ?? 0;
    if (t > maxT) maxT = t;
  }
  return maxT + 5000; 
}

Map<String, Map<String, dynamic>> interpolatePlayers(Map<String, dynamic> round, int timeMs) {
  final positions = <String, Map<String, dynamic>>{};
  final events = (round['events'] as List<dynamic>?) ?? [];
  final eventsLen = events.length;
  
  if (eventsLen == 0) return positions;

  int e1Idx = -1;
  int e2Idx = -1;

  for (int i = 0; i < eventsLen; i++) {
    final t = events[i]['time_in_round_in_ms'] as int;
    if (t <= timeMs) {
      e1Idx = i;
    } else {
      e2Idx = i;
      break;
    }
  }

  if (e1Idx == -1) {
    if (e2Idx != -1) {
      final locs = events[e2Idx]['player_locations'] as List<dynamic>?;
      if (locs != null) {
        for (var p in locs) {
          positions[p['player_index'].toString()] = Map<String, dynamic>.from(p);
        }
      }
    }
    return positions;
  }

  final e1 = events[e1Idx];
  if (e2Idx == -1) {
    final locs = e1['player_locations'] as List<dynamic>?;
    if (locs != null) {
      for (var p in locs) {
        positions[p['player_index'].toString()] = Map<String, dynamic>.from(p);
      }
    }
    return positions;
  }

  final e2 = events[e2Idx];
  final t1 = e1['time_in_round_in_ms'] as int;
  final t2 = e2['time_in_round_in_ms'] as int;
  
  double factor = 0.0;
  if (t2 > t1) {
    factor = (timeMs - t1) / (t2 - t1);
  }

  final locs1 = e1['player_locations'] as List<dynamic>? ?? [];
  final locs2 = e2['player_locations'] as List<dynamic>? ?? [];

  final map2 = {for (var p in locs2) p['player_index'].toString(): p};

  for (var p1 in locs1) {
    final idx = p1['player_index'].toString();
    final p2 = map2[idx];
    
    if (p2 == null || !p1['is_alive']) {
      positions[idx] = Map<String, dynamic>.from(p1);
      continue;
    }

    final x1 = p1['x']?.toDouble();
    final y1 = p1['y']?.toDouble();
    final vr1 = p1['view_radians']?.toDouble();

    final x2 = p2['x']?.toDouble();
    final y2 = p2['y']?.toDouble();
    final vr2 = p2['view_radians']?.toDouble();

    if (x1 == null || y1 == null) {
      positions[idx] = Map<String, dynamic>.from(p1);
      continue;
    }
    if (x2 == null || y2 == null) {
      positions[idx] = Map<String, dynamic>.from(p1);
      continue;
    }

    double outX = x1 + (x2 - x1) * factor;
    double outY = y1 + (y2 - y1) * factor;
    double outVr = vr1 ?? 0;

    if (vr1 != null && vr2 != null) {
      double diff = (vr2 - vr1) % (math.pi * 2);
      if (diff > math.pi) diff -= math.pi * 2;
      if (diff < -math.pi) diff += math.pi * 2;
      outVr = vr1 + diff * factor;
    }

    positions[idx] = {
      'player_index': idx,
      'x': outX,
      'y': outY,
      'view_radians': outVr,
      'is_alive': true,
    };
  }

  return positions;
}

Map<String, dynamic> getSpikeState(Map<String, dynamic> round, int timeMs) {
  bool planted = false;
  Map<String, dynamic>? location;
  String? site;
  int plantedAt = 0;
  bool defused = false;

  final events = round['events'] as List<dynamic>? ?? [];
  for (var ev in events) {
    final t = ev['time_in_round_in_ms'] as int;
    if (t > timeMs) break;

    if (ev['event_type'] == 'plant') {
      planted = true;
      plantedAt = t;
      final data = ev['event_data'];
      if (data != null) {
        site = data['site']?.toString();
        location = data['plant_location'];
      }
    } else if (ev['event_type'] == 'defuse') {
      defused = true;
    }
  }

  return {
    'planted': planted,
    'location': location,
    'site': site,
    'plantedAt': plantedAt,
    'defused': defused,
  };
}
