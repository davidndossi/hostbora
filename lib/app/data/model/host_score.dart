class HostScoreComponent {
  HostScoreComponent({
    required this.key,
    required this.label,
    required this.points,
    required this.max,
    required this.pct,
    required this.applicable,
  });

  factory HostScoreComponent.fromJson(Map<String, dynamic> json) {
    return HostScoreComponent(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      points: _toDouble(json['points']),
      max: _toDouble(json['max']),
      pct: _toDouble(json['pct']),
      applicable: json['applicable'] != false,
    );
  }

  final String key;
  final String label;
  final double points;
  final double max;
  final double pct;
  final bool applicable;
}

class HostScore {
  HostScore({
    required this.total,
    required this.max,
    required this.level,
    this.nextLevel,
    this.pointsToNext,
    this.headline,
    this.hint,
    this.components = const [],
  });

  factory HostScore.fromJson(Map<String, dynamic> json) {
    final raw = json['components'];
    return HostScore(
      total: _toInt(json['total']),
      max: _toInt(json['max'], fallback: 100),
      level: json['level']?.toString() ?? 'New Host',
      nextLevel: json['nextLevel']?.toString(),
      pointsToNext: _toInt(json['pointsToNext']),
      headline: json['headline']?.toString(),
      hint: json['hint']?.toString(),
      components: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => HostScoreComponent.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  final int total;
  final int max;
  final String level;
  final String? nextLevel;
  final int? pointsToNext;
  final String? headline;
  final String? hint;
  final List<HostScoreComponent> components;

  String get currentCopy => "You're currently a $level.";
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
