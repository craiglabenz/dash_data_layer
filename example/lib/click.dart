import 'package:data_layer/data_layer.dart';

class Click {
  const Click({
    required this.delta,
    required this.clickedAt,
  });

  final int delta;
  final DateTime clickedAt;

  String get id => clickedAt.toIso8601String();

  Map<String, Object?> toJson() {
    return {
      'delta': delta,
      'clickedAt': clickedAt,
    };
  }

  factory Click.fromJson(Map<String, Object?> map) {
    return Click(
      delta: map['delta'] as int,
      clickedAt: DateTime.parse(map['clickedAt'] as String),
    );
  }

  @override
  int get hashCode => Object.hash(delta, clickedAt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Click &&
        delta == other.delta &&
        clickedAt == other.clickedAt;
  }

  @override
  String toString() {
    return 'Click(delta: $delta, clickedAt: $clickedAt)';
  }

  static Bindings<Click> get bindings => Bindings<Click>(
    fromJson: Click.fromJson,
    toJson: (Click obj) => obj.toJson(),
    getId: (Click obj) => obj.id,
    getDetailUrl: (String id) => ApiUrl(path: 'clicks/$id'),
    getListUrl: () => const ApiUrl(path: 'clicks/'),
  );
}
