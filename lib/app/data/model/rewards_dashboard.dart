class RewardChallenge {
  RewardChallenge({
    required this.key,
    required this.title,
    required this.description,
    required this.pct,
    required this.current,
    required this.target,
    required this.unit,
    required this.complete,
  });

  factory RewardChallenge.fromJson(Map<String, dynamic> json) {
    return RewardChallenge(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pct: _toInt(json['pct']),
      current: _toDouble(json['current']),
      target: _toDouble(json['target']),
      unit: json['unit']?.toString() ?? '',
      complete: json['complete'] == true,
    );
  }

  final String key;
  final String title;
  final String description;
  final int pct;
  final double current;
  final double target;
  final String unit;
  final bool complete;
}

class RewardEarnItem {
  RewardEarnItem({
    required this.key,
    required this.label,
    required this.points,
    required this.claimed,
  });

  factory RewardEarnItem.fromJson(Map<String, dynamic> json) {
    return RewardEarnItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      points: _toInt(json['points']),
      claimed: json['claimed'] == true,
    );
  }

  final String key;
  final String label;
  final int points;
  final bool claimed;
}

class RewardCatalogItem {
  RewardCatalogItem({
    required this.key,
    required this.label,
    required this.cost,
    this.description,
  });

  factory RewardCatalogItem.fromJson(Map<String, dynamic> json) {
    return RewardCatalogItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      cost: _toInt(json['cost']),
      description: json['description']?.toString(),
    );
  }

  final String key;
  final String label;
  final int cost;
  final String? description;
}

class RewardsDashboard {
  RewardsDashboard({
    required this.balance,
    required this.smsCredits,
    required this.academyCompleted,
    required this.challenges,
    required this.earn,
    required this.catalog,
  });

  factory RewardsDashboard.fromJson(Map<String, dynamic> json) {
    return RewardsDashboard(
      balance: _toInt(json['balance']),
      smsCredits: _toInt(json['smsCredits']),
      academyCompleted: json['academyCompleted'] == true,
      challenges: _list(json['challenges'], RewardChallenge.fromJson),
      earn: _list(json['earn'], RewardEarnItem.fromJson),
      catalog: _list(json['catalog'], RewardCatalogItem.fromJson),
    );
  }

  final int balance;
  final int smsCredits;
  final bool academyCompleted;
  final List<RewardChallenge> challenges;
  final List<RewardEarnItem> earn;
  final List<RewardCatalogItem> catalog;
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => parse(Map<String, dynamic>.from(item)))
      .toList();
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
