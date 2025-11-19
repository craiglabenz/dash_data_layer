import 'dart:math';
import 'package:data_layer/data_layer.dart';
import 'package:equatable/equatable.dart';

class TestModel {
  const TestModel({required this.id, this.msg = defaultMessage});

  factory TestModel.randomId([String msg = defaultMessage]) => TestModel(
    id: Random().nextDouble().toString(),
    msg: msg,
  );

  factory TestModel.fromJson(Map<String, dynamic> json) => TestModel(
    id: json['id'] as String?,
    msg: json['msg'] as String,
  );

  final String? id;
  final String msg;

  static const defaultMessage = 'default';

  Map<String, dynamic> toJson() => {'id': id, 'msg': msg};

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          msg == other.msg;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll([id, msg]);

  @override
  String toString() => 'TestModel(id: $id, msg: $msg)';

  static final bindings = Bindings<TestModel>(
    fromJson: TestModel.fromJson,
    getDetailUrl: (id) => ApiUrl(path: 'test/$id'),
    getListUrl: () => const ApiUrl(path: 'test/'),
    toJson: (TestModel obj) => obj.toJson(),
    getId: (TestModel obj) => obj.id,
  );
}

class MsgStartsWithFilter extends Filter with EquatableMixin {
  const MsgStartsWithFilter(this.value);
  final String value;

  @override
  CacheKey get cacheKey => value;

  @override
  Json toJson() => {'value': value};

  @override
  Params toParams() => toJson().cast<String, String>();

  @override
  List<Object?> get props => [value];
}

class FakeSourceList<T> extends SourceList<T> {
  FakeSourceList(Bindings<T> bindings)
    : super(
        bindings: bindings,
        sources: [],
      );
  final objs = <T>[];

  void addObj(T obj) => objs.add(obj);

  @override
  Future<ReadResult<T>> getById(
    String id,
    RequestDetails details,
  ) => Future.value(
    ReadSuccess<T>(objs.first, details: details),
  );

  @override
  Future<ReadListResult<T>> getByIds(
    Set<String> ids,
    RequestDetails details,
  ) => Future.value(
    ReadListResult<T>.fromList([objs.first], details, {}, bindings.getId),
  );

  @override
  Future<ReadListResult<T>> getItems(RequestDetails details) => Future.value(
    ReadListResult<T>.fromList([objs.first], details, {}, bindings.getId),
  );

  @override
  Future<WriteResult<T>> setItem(T item, RequestDetails details) =>
      Future.value(WriteSuccess<T>(objs.first, details: details));

  @override
  Future<WriteListResult<T>> setItems(
    Iterable<T> items,
    RequestDetails details,
  ) => Future.value(WriteListSuccess<T>([objs.first], details: details));
}

/// Checks whether a model's given field name equals the given value.
///
/// Not the most performant class, as this re-serializes the model. Best used
/// only for tests.
class FieldEquals<T, Value> extends Filter with EquatableMixin {
  const FieldEquals(this.fieldName, this.value, this.getValue);
  final String fieldName;
  final Value? value;
  final Value? Function(T) getValue;

  @override
  List<Object?> get props => [fieldName, value, T.runtimeType];

  @override
  Json toJson() => <String, String>{
    fieldName: value.toString(),
  };

  @override
  Params toParams() => toJson().cast<String, String>();

  @override
  CacheKey get cacheKey => '$fieldName-equals-$value';
}
