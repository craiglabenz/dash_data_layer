import 'package:data_layer/data_layer.dart';

/// Adds [getById] to a data contract.
mixin ReadMixin<T> {
  /// Loads the instance of [T] whose primary key is [id].
  Future<ReadResult<T>> getById(
    String id,
    RequestDetails details,
  );

  /// Loads all instances of [T] whose primary key is in the set [ids].
  ///
  /// This could in theory be a version of [getItems] with a specific `IdsIn`
  /// filter, but that would complicate the extra caching logic handled by this
  /// method. The source of that complication is the difference between a
  /// "where in" filter and a generic filter. The difference is that with
  /// a "where in" filter, you know when you are still missing objects and can
  /// forward that request onto the server just to fill in the gaps. However,
  /// with a generic filter, you do not know whether or not you are
  /// missing any records and thus cannot be clever with the final request to
  /// the server.
  ///
  /// This method makes use of that extra knowledge afforded by a "where in"
  /// filter to load records efficiently; which is what would be lost if this
  /// method was rolled into calling [getItems] with an equivalent filter.
  Future<ReadListResult<T>> getByIds(
    Set<String> ids,
    RequestDetails details,
  );

  /// Loads all instances of [T] that satisfy any filtes or pagination on
  /// [details].
  Future<ReadListResult<T>> getItems(RequestDetails details);
}

/// Introduces [setItem] to a data contract, but not [WriteMixin.setItems].
mixin SingleWriteMixin<T> {
  /// Persists [item].
  Future<WriteResult<T>> setItem(T item, RequestDetails details);
}

/// Introduces [setItem] and [setItems] to a data contract.
mixin WriteMixin<T> {
  /// Persists [item].
  Future<WriteResult<T>> setItem(T item, RequestDetails details);

  /// Persists all [items].
  Future<WriteListResult<T>> setItems(
    Iterable<T> items,
    RequestDetails details,
  );

  /// Clears an item with the given [id] if one exists.
  Future<DeleteResult<T>> delete(String id, RequestDetails details);
}

/// {@template DataContract}
/// Outline of core methods to which all data loaders must adhere.
/// {@endtemplate}
abstract class DataContract<T> with ReadMixin<T>, WriteMixin<T> {
  /// {@macro DataContract}
  const DataContract();
}
