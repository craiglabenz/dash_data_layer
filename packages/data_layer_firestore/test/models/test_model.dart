import 'package:data_layer/data_layer.dart' show Json;
import 'package:flutter/foundation.dart';

/// Test model.
@immutable
class TestModel {
  /// Instantiates a [TestModel].
  const TestModel({required this.name, this.id});

  /// Json deserialization constructor.
  factory TestModel.fromJson(Json json) => TestModel(
    id: json['id'] as String?,
    name: json['name'] as String? ?? '',
  );

  /// Id of the object.
  final String? id;

  /// Name of the object.
  final String name;

  @override
  String toString() => 'TestModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TestModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  Json toJson() => {'id': id, 'name': name};
}
