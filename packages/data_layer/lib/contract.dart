import 'package:data_layer/data_layer.dart';

/// Adds [getById] to a data contract.
mixin ReadMixin<T> {
  /// Loads the instance of [T] whose primary key is found at
  /// [ReadOperation.itemId].
  Future<ReadResult<T>> getById(ReadOperation<T> operation);

  /// Loads all instances of [T] whose primary key is in the set at
  /// [ReadByIdsOperation.itemIds].
  ///
  /// This could in theory be a version of [getItems] with a specific `IdsIn`
  /// filter, but that would complicate the extra caching logic handled by this
  /// method. The source of that complication is the difference between a
  /// "where in" filter and a generic filter. The difference is that with
  /// a "where in" filter, you know when you are still missing objects and can
  /// forward that request onto the next source just to fill in the gaps.
  /// However, with a generic filter, you do not know whether or not you are
  /// missing any records and thus cannot be clever with the a request to the
  /// next source.
  ///
  /// This method makes use of that extra knowledge afforded by a "where in"
  /// filter to load records efficiently; which is what would be lost, or at
  /// least greatly complicated, if this method was rolled into calling
  /// [getItems] with an equivalent filter.
  Future<ReadListResult<T>> getByIds(ReadByIdsOperation<T> operation);

  /// Loads all instances of [T] that satisfy any filtes or pagination on
  /// [ReadListOperation.details].
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation);
}

/// Introduces [setItem] to a data contract, but not [WriteMixin.setItems].
mixin SingleWriteMixin<T> {
  /// Persists [WriteOperation.item].
  Future<WriteResult<T>> setItem(WriteOperation<T> operation);
}

/// Introduces [setItem] and [setItems] to a data contract.
mixin WriteMixin<T> {
  /// Persists [WriteOperation.item].
  Future<WriteResult<T>> setItem(WriteOperation<T> operation);

  /// Persists all [WriteListOperation.items].
  Future<WriteListResult<T>> setItems(WriteListOperation<T> operation);

  /// Clears an item with the given [DeleteOperation.itemId] if one exists.
  Future<DeleteResult<T>> delete(DeleteOperation<T> operation);
}

/// Introduces message operations for creation and generic updates.
mixin MessageWriteMixin<T> on DataContract<T> {
  /// Sends a message object (e.g. for patching or decoupled creations).
  Future<WriteResult<T?>> sendMessage(SendMessageOperation<T> operation);

  @override
  Set<SourceOperationType> get supportedOperations => {
    ...super.supportedOperations,
    SourceOperationType.sendMessage,
  };
}

/// {@template DataContract}
/// Outline of core methods to which all data loaders must adhere.
/// {@endtemplate}
abstract class DataContract<T> with ReadMixin<T>, WriteMixin<T> {
  /// {@macro DataContract}
  const DataContract();

  /// The operations supported by this loader instance.
  /// Defaults to standard CRUD operations.
  Set<SourceOperationType> get supportedOperations => const {
    SourceOperationType.getById,
    SourceOperationType.getByIds,
    SourceOperationType.getItems,
    SourceOperationType.setItem,
    SourceOperationType.setItems,
    SourceOperationType.delete,
  };

  /// Returns whether this instance supports the given [SourceOperationType].
  bool supports(SourceOperationType type) => supportedOperations.contains(type);
}
