/// Feed item representation for the Home screen.
/// Plain data model containing no business or presentation logic.
class HomeFeedItem {
  const HomeFeedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.category,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String category;

  factory HomeFeedItem.fromJson(Map<String, dynamic> json) {
    return HomeFeedItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] as String? ?? 'General',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
      };
}

/// Stat metric representation for operational overview.
class HomeStat {
  const HomeStat({
    required this.titleKey,
    required this.count,
    required this.iconCodePoint,
  });

  final String titleKey;
  final int count;
  final int iconCodePoint;
}
