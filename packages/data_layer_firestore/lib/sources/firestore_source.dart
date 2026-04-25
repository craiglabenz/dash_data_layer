import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'package:data_layer/data_layer.dart';
import 'package:data_layer_firestore/sources/firestore_filters.dart';
import 'package:logging/logging.dart';

/// {@template FirestoreSource}
/// Firestore implementation of [Source].
/// {@endtemplate}
class FirestoreSource<T> extends Source<T> with WatchableSource<T> {
  /// {@macro FirestoreSource}
  FirestoreSource(
    this.firestore, {
    required super.bindings,
    required this.collectionName,
    this.onCreateServerTimestampFields = const [],
    this.onUpdateServerTimestampFields = const [],
  }) {
    _log = Logger('FirestoreSource<$T>::$collectionName');
  }

  /// Firestore, baby!
  final FirebaseFirestore firestore;

  /// Fields that should be set to [FieldValue.serverTimestamp()] on create.
  final List<String> onCreateServerTimestampFields;

  /// Fields that should be set to [FieldValue.serverTimestamp()] on every write
  final List<String> onUpdateServerTimestampFields;

  /// The collection name from the Firestore console.
  final String collectionName;

  /// The Firestore collection for this source.
  CollectionReference<Json> get collection =>
      _collection ??= firestore.collection(collectionName);

  CollectionReference<Json>? _collection;

  late final Logger _log;

  @override
  Future<ReadResult<T>> getById(ReadOperation<T> operation) =>
      _guarded(() => _getById(operation), operation);

  Future<ReadResult<T>> _getById(ReadOperation<T> operation) =>
      collection.doc(operation.itemId).get().then((snapshot) {
        if (!snapshot.exists) {
          return ReadSuccess<T>(null, details: operation.details);
        }
        return ReadSuccess<T>(
          bindings.fromJson(
            cleanData(snapshot.data() ?? {})..addAll({'id': snapshot.id}),
          ),
          details: operation.details,
        );
      });

  @override
  Future<ReadListResult<T>> getByIds(ReadByIdsOperation<T> operation) =>
      _guarded(() => _getByIds(operation), operation);

  Future<ReadListResult<T>> _getByIds(ReadByIdsOperation<T> operation) =>
      collection
          .where(FieldPath.documentId, whereIn: operation.itemIds)
          .get()
          .then((snapshot) {
            final items = snapshot.docs
                .map(
                  (doc) => bindings.fromJson(
                    cleanData(doc.data())..addAll({'id': doc.id}),
                  ),
                )
                .toList();
            final missingIds = operation.itemIds.toSet().difference(
              snapshot.docs.map((doc) => doc.id).toSet(),
            );
            return ReadListResult<T>.fromList(
              items,
              operation.details,
              missingIds,
              bindings.getId,
            );
          });

  @override
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation) =>
      _guarded(() => _getItems(operation), operation);

  Future<ReadListResult<T>> _getItems(ReadListOperation<T> operation) {
    Query<Json> query = collection;
    if (operation.details.filter != null) {
      if (operation.details.filter is! FirestoreFilter) {
        throw UnsupportedError(
          'Filter ${operation.details.filter.runtimeType} is not supported',
        );
      }
      query = (operation.details.filter! as FirestoreFilter).apply(query);
    }
    return query.get().then((snapshot) {
      return ReadListResult<T>.fromList(
        snapshot.docs
            .map(
              (doc) => bindings.fromJson(
                cleanData(doc.data())..addAll({'id': doc.id}),
              ),
            )
            .toList(),
        operation.details,
        {},
        bindings.getId,
      );
    });
  }

  @override
  Future<WriteResult<T>> setItem(WriteOperation<T> operation) =>
      _guarded(() => _setItem(operation), operation);

  Future<WriteResult<T>> _setItem(WriteOperation<T> operation) {
    final existingId = bindings.getId(operation.item);
    final dataToWrite = bindings.toJson(operation.item)..remove('id');

    assert(() {
      if (operation.details.forceInsert && existingId == null) {
        throw StateError('Cannot force insert with no id');
      }
      return true;
    }(), 'Setting forceInsert to true for an object without an Id is an error');

    // Apply server timestamps for updates
    for (final field in onUpdateServerTimestampFields) {
      dataToWrite[field] = FieldValue.serverTimestamp();
    }
    if (existingId == null || operation.details.forceInsert) {
      // Apply server timestamps for create
      for (final field in onCreateServerTimestampFields) {
        dataToWrite[field] = FieldValue.serverTimestamp();
      }
    }

    if (existingId == null && !operation.details.forceInsert) {
      return collection.add(dataToWrite).then(
        (doc) async {
          final snapshot = await doc.get();
          return WriteSuccess<T>(
            bindings.fromJson(
              cleanData(snapshot.data() ?? {})..addAll({'id': snapshot.id}),
            ),
            details: operation.details,
          );
        },
      );
    }

    final snapshot = collection.doc(existingId);
    final writeFuture = operation.details.forceInsert
        ? snapshot.set(dataToWrite)
        : snapshot.update(dataToWrite);

    return writeFuture.then(
      (_) {
        return WriteSuccess<T>(
          bindings.fromJson(bindings.toJson(operation.item)),
          details: operation.details,
        );
      },
    );
  }

  @override
  Future<WriteListResult<T>> setItems(WriteListOperation<T> operation) =>
      throw UnimplementedError();

  @override
  Future<DeleteResult<T>> delete(DeleteOperation<T> operation) {
    return _guarded(() => _delete(operation), operation);
  }

  Future<DeleteResult<T>> _delete(DeleteOperation<T> operation) {
    return collection
        .doc(operation.itemId)
        .delete()
        .then(
          (_) => DeleteSuccess<T>(operation.details),
        );
  }

  @override
  SourceType sourceType = .remote;

  @override
  Stream<ReadResult<T>> watch(ReadOperation<T> operation) =>
      _guardedSync(() => _watch(operation), operation);

  Stream<ReadResult<T>> _watch(ReadOperation<T> operation) {
    return collection.doc(operation.itemId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return ReadSuccess<T>(null, details: operation.details);
      }
      return ReadSuccess<T>(
        bindings.fromJson(
          cleanData(snapshot.data() ?? {})..addAll({'id': snapshot.id}),
        ),
        details: operation.details,
      );
    });
  }

  @override
  Stream<ReadListResult<T>> watchByIds(ReadByIdsOperation<T> operation) =>
      _guardedSync(() => _watchByIds(operation), operation);

  Stream<ReadListResult<T>> _watchByIds(ReadByIdsOperation<T> operation) {
    return collection
        .where(FieldPath.documentId, whereIn: operation.itemIds)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(
                (doc) => bindings.fromJson(
                  cleanData(doc.data())..addAll({'id': doc.id}),
                ),
              )
              .toList();
          final missingIds = operation.itemIds.toSet().difference(
            snapshot.docs.map((doc) => doc.id).toSet(),
          );
          return ReadListResult<T>.fromList(
            items,
            operation.details,
            missingIds,
            bindings.getId,
          );
        });
  }

  @override
  Stream<ReadListResult<T>> watchList(ReadListOperation<T> operation) =>
      _guardedSync(() => _watchList(operation), operation);

  Stream<ReadListResult<T>> _watchList(ReadListOperation<T> operation) {
    Query<Json> query = collection;
    if (operation.details.filter != null) {
      if (operation.details.filter is! FirestoreFilter) {
        throw UnsupportedError(
          'Filter ${operation.details.filter.runtimeType} is not supported',
        );
      }
      query = (operation.details.filter! as FirestoreFilter).apply(query);
    }
    return query.snapshots().map((snapshot) {
      return ReadListResult<T>.fromList(
        snapshot.docs
            .map(
              (doc) => bindings.fromJson(
                cleanData(doc.data())..addAll({'id': doc.id}),
              ),
            )
            .toList(),
        operation.details,
        {},
        bindings.getId,
      );
    });
  }

  /// Converts Firebase [Timestamp] values into Dart [DateTime]s.
  static Json cleanData(Json data) {
    if (data.isEmpty) {
      return data;
    }

    Json? cleaned;

    for (final entry in data.entries) {
      final value = entry.value;
      final cleanedValue = _cleanValue(value);

      if (!identical(cleanedValue, value)) {
        cleaned ??= Map<String, dynamic>.from(data);
        cleaned[entry.key] = cleanedValue;
      }
    }

    return cleaned ?? data;
  }

  static Object? _cleanValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      return cleanData(value);
    }
    if (value is List) {
      List<Object?>? newList;
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        final cleanedItem = _cleanValue(item);
        if (!identical(cleanedItem, item)) {
          newList ??= List<Object?>.from(value);
          newList[i] = cleanedItem;
        }
      }
      return newList ?? value;
    }
    return value;
  }

  /// Converts Dart [DateTime]s into Firebase [Timestamp] values.
  static Json cleanDataForWrite(Json data) {
    if (data.isEmpty) {
      return data;
    }

    Json? cleaned;

    for (final entry in data.entries) {
      final value = entry.value;
      final cleanedValue = _cleanValueForWrite(value);

      if (!identical(cleanedValue, value)) {
        cleaned ??= Map<String, dynamic>.from(data);
        cleaned[entry.key] = cleanedValue;
      }
    }

    return cleaned ?? data;
  }

  static Object? _cleanValueForWrite(Object? value) {
    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }
    if (value is String) {
      final iso8601Regex = RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z)?$',
      );
      if (iso8601Regex.hasMatch(value)) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return Timestamp.fromDate(parsed);
        }
      }
    }
    if (value is Map<String, dynamic>) {
      return cleanDataForWrite(value);
    }
    if (value is List) {
      List<Object?>? newList;
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        final cleanedItem = _cleanValueForWrite(item);
        if (!identical(cleanedItem, item)) {
          newList ??= List<Object?>.from(value);
          newList[i] = cleanedItem;
        }
      }
      return newList ?? value;
    }
    return value;
  }

  Future<R> _guarded<R>(Future<R> Function() fn, Operation<T> operation) async {
    try {
      return await fn();
    } on FirebaseException catch (e) {
      _handleFirebaseException(e, operation);
      rethrow;
    } on Exception catch (e) {
      final description = _describeOperation(operation);
      _log.severe('Uncaught error: $e. $description');
      rethrow;
    }
  }

  R _guardedSync<R>(R Function() fn, Operation<T> operation) {
    try {
      return fn();
    } on FirebaseException catch (e) {
      _handleFirebaseException(e, operation);
      rethrow;
    } on Exception catch (e) {
      final description = _describeOperation(operation);
      _log.severe('Uncaught error: $e. $description');
      rethrow;
    }
  }

  void _handleFirebaseException(
    FirebaseException e,
    Operation<T> operation,
  ) {
    final description = _describeOperation(operation);
    switch (e.code) {
      case 'permission-denied':
        _log.severe('Permission denied: ${e.message}. $description');
      case 'not-found':
        _log.severe('Not found: ${e.message}. $description');
      case 'unavailable':
        _log.severe('The service is currently unavailable (offline?).');
      case 'unauthenticated':
        _log.severe('User must be logged in to perform this action.');
      case 'deadline-exceeded':
        _log.severe('The operation took too long to complete.');
      default:
        _log.severe(
          'Uncaught Firebase error ${e.code} :: ${e.message}. $description',
        );
    }
  }

  String _describeOperation(Operation<T> operation) {
    return switch (operation) {
      ReadOperation<T>() =>
        'Failed to read $collectionName/${operation.itemId}',
      ReadByIdsOperation<T>() =>
        'Failed to read $collectionName/${operation.itemIds}',
      ReadListOperation<T>() => 'Failed to read $collectionName',
      WriteOperation<T>() =>
        'Failed to write $collectionName/${bindings.getId(operation.item)}',
      WriteListOperation<T>() => 'Failed to write $collectionName',
      DeleteOperation<T>() =>
        'Failed to delete $collectionName/${operation.itemId}',
      SendMessageOperation<T>() => throw UnimplementedError(),
    };
  }

  @override
  Future<WriteResult<T>> sendMessage(SendMessageOperation<T> operation) =>
      throw UnimplementedError(
        'FirestoreSource does not support sending messages by default.',
      );
}
