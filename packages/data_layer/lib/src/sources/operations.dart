import 'package:data_layer/data_layer.dart' show RequestDetails;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'operations.freezed.dart';
part 'operations.g.dart';

/// {@template Operation}
/// Carrier for all information required to describe a data operation.
///
/// This is source-independent, which means it does not contain details like
/// which URLs might return the requested data. That information is contained
/// by the sources to which these objects are passed.
/// {@endtemplate}
@Freezed(genericArgumentFactories: true)
sealed class Operation<T> with _$Operation<T> {
  const Operation._();

  /// A single item read operation that failed.
  const factory Operation.getItem({
    required String operationId,
    required String itemId,
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadOperation;

  /// A multi-item read operation that failed.
  const factory Operation.getItems({
    required String operationId,
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadListOperation;

  /// A multi-item read-by-ids operation that failed.
  const factory Operation.getByIds({
    required String operationId,
    required Set<String> itemIds,
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadByIdsOperation;

  /// A single item write operation that failed.
  const factory Operation.setItem({
    required String operationId,
    required RequestDetails details,
    // required Json data,
    required T item,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WriteOperation;

  /// A multi-item write operation that failed.
  const factory Operation.setItems({
    required String operationId,
    required RequestDetails details,
    required Iterable<T> items,
    // required List<Json> data,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WriteListOperation;

  /// A single item delete operation that failed.
  const factory Operation.delete({
    required String operationId,
    required String itemId,
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = DeleteOperation;

  factory Operation.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$OperationFromJson(json, fromJsonT);

  /// Increments the retry count of this operation.
  R retry<R>() => copyWith(attemptNumber: attemptNumber + 1) as R;
}
