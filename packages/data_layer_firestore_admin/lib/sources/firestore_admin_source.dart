import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:data_layer_firestore_admin/sources/firestore_admin_filters.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart'
    hide Filter, WriteResult;
import 'package:logging/logging.dart';

/// {@template FirestoreAdminSource}
/// Firestore implementation of [Source] using `pkg:google_cloud_firestore`.
/// {@endtemplate}
class FirestoreAdminSource<T> extends Source<T> with WatchableSource<T> {
  /// {@macro FirestoreAdminSource}
  FirestoreAdminSource(
    this.firestore, {
    required super.bindings,
    required this.collectionName,
    this.onCreateServerTimestampFields = const [],
    this.onUpdateServerTimestampFields = const [],
  }) {
    _log = Logger('FirestoreAdminSource<$T>::$collectionName');
  }

  /// Firestore instance.
  final Firestore firestore;

  /// Fields that should be set to [FieldValue.serverTimestamp] on create.
  final List<String> onCreateServerTimestampFields;

  /// Fields that should be set to [FieldValue.serverTimestamp] on every write.
  final List<String> onUpdateServerTimestampFields;

  /// The collection name from the Firestore console.
  final String collectionName;

  /// The Firestore collection for this source.
  CollectionReference<DocumentData> get collection =>
      _collection ??= firestore.collection(collectionName);

  CollectionReference<DocumentData>? _collection;

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

  Future<ReadListResult<T>> _getByIds(ReadByIdsOperation<T> operation) async {
    if (operation.itemIds.isEmpty) {
      return ReadListResult<T>.fromList(
        [],
        operation.details,
        {},
        bindings.getId,
      );
    }

    if (operation.itemIds.length <= 30) {
      final docRefs = operation.itemIds.map(collection.doc).toList();
      return collection
          .where(FieldPath.documentId, WhereFilter.isIn, docRefs)
          .get()
          .then((snapshot) => _processSnapshotDocs(snapshot.docs, operation));
    }

    final chunks = operation.itemIds.toList().chunks(30).toList();
    final snapshots = await Future.wait(
      chunks.map(
        (chunk) => collection
            .where(
              FieldPath.documentId,
              WhereFilter.isIn,
              chunk.map(collection.doc).toList(),
            )
            .get(),
      ),
    );

    final allDocs = snapshots.expand((s) => s.docs).toList();
    return _processSnapshotDocs(allDocs, operation);
  }

  ReadListResult<T> _processSnapshotDocs(
    List<DocumentSnapshot<DocumentData>> docs,
    ReadByIdsOperation<T> operation,
  ) {
    final items = docs
        .map(
          (doc) => bindings.fromJson(
            cleanData(doc.data() ?? {})..addAll({'id': doc.id}),
          ),
        )
        .toList();
    final missingIds = operation.itemIds.toSet().difference(
      docs.map((doc) => doc.id).toSet(),
    );
    return ReadListResult<T>.fromList(
      items,
      operation.details,
      missingIds,
      bindings.getId,
    );
  }

  @override
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation) =>
      _guarded(() => _getItems(operation), operation);

  Future<ReadListResult<T>> _getItems(ReadListOperation<T> operation) {
    Query<DocumentData> query = collection;
    if (operation.details.filter != null) {
      if (operation.details.filter is! FirestoreAdminFilter) {
        throw UnsupportedError(
          'Filter ${operation.details.filter.runtimeType} is not supported',
        );
      }
      query = (operation.details.filter! as FirestoreAdminFilter).apply(query);
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
    var dataToWrite = bindings.toJson(operation.item)..remove('id');

    assert(() {
      if (operation.details.forceInsert && existingId == null) {
        throw StateError('Cannot force insert with no id');
      }
      return true;
    }(), 'Setting forceInsert to true for an object without an Id is an error');

    // Apply server timestamps for updates
    for (final field in onUpdateServerTimestampFields) {
      dataToWrite[field] = FieldValue.serverTimestamp;
    }
    if (existingId == null || operation.details.forceInsert) {
      // Apply server timestamps for create
      for (final field in onCreateServerTimestampFields) {
        dataToWrite[field] = FieldValue.serverTimestamp;
      }
    }

    dataToWrite = cleanDataForWrite(dataToWrite);

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

  /// Merges an arbitrary [Json] map into the document with [id].
  Future<void> raw(String id, Json map) async {
    final dataToWrite = cleanDataForWrite(map);
    try {
      await collection
          .doc(id)
          .set(dataToWrite, options: const SetOptions.merge());
    } on FirestoreException catch (e) {
      _log.severe(
        'Failed to merge raw data into $collectionName/$id: ${e.message}',
      );
      rethrow;
    } on Exception catch (e) {
      _log.severe(
        'Uncaught error merging raw data into $collectionName/$id: $e',
      );
      rethrow;
    }
  }

  @override
  SourceType sourceType = SourceType.remote;

  @override
  Stream<ReadResult<T>> watch(WatchOperation<T> operation) =>
      throw UnimplementedError(
        'google_cloud_firestore does not support realtime stream watching.',
      );

  @override
  Stream<ReadListResult<T>> watchByIds(WatchByIdsOperation<T> operation) =>
      throw UnimplementedError(
        'google_cloud_firestore does not support realtime stream watching.',
      );

  @override
  Stream<ReadListResult<T>> watchList(WatchListOperation<T> operation) =>
      throw UnimplementedError(
        'google_cloud_firestore does not support realtime stream watching.',
      );

  /// Converts Firebase [Timestamp] values into ISO 8601 strings.
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
        final cleanedValue = _cleanValue(item);
        if (!identical(cleanedValue, item)) {
          newList ??= List<Object?>.from(value);
          newList[i] = cleanedValue;
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

  Future<R> _guarded<R>(
    Future<R> Function() fn,
    Operation<T> operation,
  ) async {
    try {
      return await fn();
    } on FirestoreException catch (e) {
      _handleFirestoreException(e, operation);
      rethrow;
    } on Exception catch (e) {
      final description = _describeOperation(operation);
      _log.severe('Uncaught error: $e. $description');
      rethrow;
    }
  }

  void _handleFirestoreException(
    FirestoreException e,
    Operation<T> operation,
  ) {
    final description = _describeOperation(operation);
    switch (e.code) {
      case 'permission_denied':
        _log.severe('Permission denied: ${e.message}. $description');
      case 'not_found':
        _log.severe('Not found: ${e.message}. $description');
      case 'unavailable':
        _log.severe('The service is currently unavailable (offline?).');
      case 'unauthenticated':
        _log.severe('User must be logged in to perform this action.');
      case 'deadline_exceeded':
        _log.severe('The operation took too long to complete.');
      default:
        _log.severe(
          'Uncaught Firestore error ${e.code} :: ${e.message}. $description',
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
      SendMessageOperation<T>() => 'Failed to send message to $collectionName',
      WatchOperation<T>() =>
        'Failed to watch $collectionName/${operation.itemId}',
      WatchByIdsOperation<T>() =>
        'Failed to watch $collectionName/${operation.itemIds}',
      WatchListOperation<T>() => 'Failed to watch $collectionName',
    };
  }
}

extension _ListChunkX<T> on List<T> {
  Iterable<List<T>> chunks(int size) sync* {
    for (var i = 0; i < length; i += size) {
      yield sublist(i, i + size > length ? length : i + size);
    }
  }
}
