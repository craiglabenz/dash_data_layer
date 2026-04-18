import 'package:data_layer/data_layer.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class TestRecord with _$TestRecord {
  const factory TestRecord({
    required String id,
    required String value,
    required DateTime createdAt,
  }) = _TestRecord;

  factory TestRecord.fromJson(Map<String, dynamic> json) =>
      _$TestRecordFromJson(json);

  static final bindings = Bindings<TestRecord>(
    fromJson: TestRecord.fromJson,
    getDetailUrl: (id) => ApiUrl(path: 'records/$id'),
    getListUrl: () => const ApiUrl(path: 'records'),
    toJson: (obj) => obj.toJson(),
    getId: (obj) => obj.id,
  );
}

@freezed
sealed class TestRecordMessage
    with _$TestRecordMessage {
  const factory TestRecordMessage.create({
    required String value,
  }) = _TestRecordMessageCreate;

  const factory TestRecordMessage.update({
    String? value,
  }) = _TestRecordMessageUpdate;

  const TestRecordMessage._();

  factory TestRecordMessage.fromJson(Map<String, dynamic> json) =>
      _$TestRecordMessageFromJson(json);

  static final bindings = Bindings<TestRecordMessage>(
    fromJson: TestRecordMessage.fromJson,
    getDetailUrl: (_) => const ApiUrl(path: 'records'),
    getListUrl: () => const ApiUrl(path: 'records'),
    toJson: (obj) => obj.toJson(),
    getId: (obj) => null,
  );
}
