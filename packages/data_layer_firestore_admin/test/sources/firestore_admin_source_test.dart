import 'package:data_layer/data_layer.dart' hide Source;
import 'package:data_layer_firestore_admin/sources/firestore_admin_filters.dart';
import 'package:data_layer_firestore_admin/sources/firestore_admin_source.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart'
    as gcf
    hide Filter;
import 'package:google_cloud_firestore/src/firestore.dart' as gcf_internal;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

class MockFirestore extends Mock implements gcf.Firestore {}

class MockCollectionReference extends Mock
    implements gcf.CollectionReference<gcf.DocumentData> {
  @override
  gcf.CollectionReference<U> withConverter<U>({
    gcf_internal.FromFirestore<U>? fromFirestore,
    gcf_internal.ToFirestore<U>? toFirestore,
  }) => throw UnimplementedError();

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}

class MockDocumentReference extends Mock
    implements gcf.DocumentReference<gcf.DocumentData> {
  @override
  gcf.DocumentReference<U> withConverter<U>({
    gcf_internal.FromFirestore<U>? fromFirestore,
    gcf_internal.ToFirestore<U>? toFirestore,
  }) => throw UnimplementedError();

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}

class MockDocumentSnapshot extends Mock
    implements gcf.DocumentSnapshot<gcf.DocumentData> {}

class MockQuerySnapshot extends Mock
    implements gcf.QuerySnapshot<gcf.DocumentData> {}

class MockQueryDocumentSnapshot extends Mock
    implements gcf.QueryDocumentSnapshot<gcf.DocumentData> {
  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}

class MockQuery extends Mock implements gcf.Query<gcf.DocumentData> {
  @override
  gcf.Query<U> withConverter<U>({
    gcf_internal.FromFirestore<U>? fromFirestore,
    gcf_internal.ToFirestore<U>? toFirestore,
  }) => throw UnimplementedError();

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}

class MockWriteResult extends Mock implements gcf.WriteResult {}

// Concrete FirestoreAdminFilter for testing
class TestAdminFilter extends Filter with FirestoreAdminFilter {
  const TestAdminFilter(this.filterFn);

  final gcf.Query<gcf.DocumentData> Function(
    gcf.Query<gcf.DocumentData>,
  )
  filterFn;

  @override
  gcf.Query<gcf.DocumentData> apply(gcf.Query<gcf.DocumentData> query) =>
      filterFn(query);

  @override
  String get cacheKey => 'test-admin-filter';

  @override
  Map<String, String> toParams() => {};

  @override
  Json toJson() => {};
}

// Unknown Filter for testing unsupported filters
class UnknownFilter extends Filter {
  @override
  String get cacheKey => 'unknown';

  @override
  Json toJson() => {};

  @override
  Map<String, String> toParams() => {};
}

void main() {
  setUpAll(() {
    registerFallbackValue(gcf.FieldPath.documentId);
    registerFallbackValue(gcf.WhereFilter.equal);
  });

  group('FirestoreAdminSource', () {
    late MockFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late Bindings<TestModel> bindings;
    late FirestoreAdminSource<TestModel> source;

    setUp(() {
      mockFirestore = MockFirestore();
      mockCollection = MockCollectionReference();

      when(
        () => mockFirestore.collection('testModels'),
      ).thenReturn(mockCollection);

      bindings = Bindings<TestModel>(
        getId: (item) => item.id,
        fromJson: TestModel.fromJson,
        toJson: (item) => item.toJson(),
      );

      source = FirestoreAdminSource(
        mockFirestore,
        bindings: bindings,
        collectionName: 'testModels',
        onCreateServerTimestampFields: ['createdAt'],
        onUpdateServerTimestampFields: ['updatedAt'],
      );
    });

    group('getById', () {
      test('returns success with data when document exists', () async {
        final mockDoc = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockCollection.doc('doc1')).thenReturn(mockDoc);
        when(mockDoc.get).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.id).thenReturn('doc1');
        when(mockSnapshot.data).thenReturn({'name': 'Test Item'});

        final operation = ReadOperation<TestModel>(
          operationId: 'op1',
          itemId: 'doc1',
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        final result = await source.getById(operation);

        expect(result, isA<ReadSuccess<TestModel>>());
        final success = result as ReadSuccess<TestModel>;
        expect(
          success.item,
          equals(const TestModel(id: 'doc1', name: 'Test Item')),
        );
      });

      test('returns success with null when document does not exist', () async {
        final mockDoc = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockCollection.doc('non-existent')).thenReturn(mockDoc);
        when(mockDoc.get).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        final operation = ReadOperation<TestModel>(
          operationId: 'op2',
          itemId: 'non-existent',
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        final result = await source.getById(operation);

        expect(result, isA<ReadSuccess<TestModel>>());
        final success = result as ReadSuccess<TestModel>;
        expect(success.item, isNull);
      });
    });

    group('getByIds', () {
      test('returns empty result when itemIds is empty', () async {
        final operation = ReadByIdsOperation<TestModel>(
          operationId: 'op3_empty',
          itemIds: {},
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        final result = await source.getByIds(operation);

        expect(result, isA<ReadListResult<TestModel>>());
        final success = result as ReadListSuccess<TestModel>;
        expect(success.items, isEmpty);
        expect(success.missingItemIds, isEmpty);
      });

      test('returns items and identifies missing ids', () async {
        final mockDoc1 = MockDocumentReference();
        final mockDoc2 = MockDocumentReference();
        final mockDoc3 = MockDocumentReference();

        when(() => mockCollection.doc('doc1')).thenReturn(mockDoc1);
        when(() => mockCollection.doc('doc2')).thenReturn(mockDoc2);
        when(() => mockCollection.doc('missing3')).thenReturn(mockDoc3);

        final mockQuery = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnap1 = MockQueryDocumentSnapshot();
        final mockDocSnap2 = MockQueryDocumentSnapshot();

        when(
          () => mockCollection.where(
            gcf.FieldPath.documentId,
            gcf.WhereFilter.isIn,
            [mockDoc1, mockDoc2, mockDoc3],
          ),
        ).thenReturn(mockQuery);

        when(mockQuery.get).thenAnswer((_) async => mockQuerySnapshot);
        when(
          () => mockQuerySnapshot.docs,
        ).thenReturn([mockDocSnap1, mockDocSnap2]);

        when(() => mockDocSnap1.id).thenReturn('doc1');
        when(mockDocSnap1.data).thenReturn({'name': 'Item 1'});

        when(() => mockDocSnap2.id).thenReturn('doc2');
        when(mockDocSnap2.data).thenReturn({'name': 'Item 2'});

        final operation = ReadByIdsOperation<TestModel>(
          operationId: 'op3',
          itemIds: {'doc1', 'doc2', 'missing3'},
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        final result = await source.getByIds(operation);

        expect(result, isA<ReadListResult<TestModel>>());
        final success = result as ReadListSuccess<TestModel>;

        expect(success.items.length, 2);
        expect(
          success.items.map((e) => e.id),
          containsAll(['doc1', 'doc2']),
        );
        expect(success.missingItemIds, contains('missing3'));
      });
    });

    group('getItems', () {
      test('returns all items when no filter provided', () async {
        final mockSnapshot = MockQuerySnapshot();
        final mockDocSnap1 = MockQueryDocumentSnapshot();
        final mockDocSnap2 = MockQueryDocumentSnapshot();

        when(mockCollection.get).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([mockDocSnap1, mockDocSnap2]);

        when(() => mockDocSnap1.id).thenReturn('doc1');
        when(mockDocSnap1.data).thenReturn({'name': 'Item 1'});

        when(() => mockDocSnap2.id).thenReturn('doc2');
        when(mockDocSnap2.data).thenReturn({'name': 'Item 2'});

        final operation = ReadListOperation<TestModel>(
          operationId: 'op4',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        final result = await source.getItems(operation);

        final success = result as ReadListSuccess<TestModel>;
        expect(success.items.length, 2);
      });

      test('applies FirestoreAdminFilter correctly', () async {
        final mockQuery = MockQuery();
        final mockSnapshot = MockQuerySnapshot();
        final mockDocSnap = MockQueryDocumentSnapshot();

        when(mockQuery.get).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([mockDocSnap]);

        when(() => mockDocSnap.id).thenReturn('doc2');
        when(mockDocSnap.data).thenReturn({'name': 'Item 2'});

        final filter = TestAdminFilter((q) => mockQuery);
        final operation = ReadListOperation<TestModel>(
          operationId: 'op5',
          details: RequestDetails(filter: filter),
          createdAt: DateTime.now(),
        );

        final result = await source.getItems(operation);

        final success = result as ReadListSuccess<TestModel>;
        expect(success.items.length, 1);
        expect(success.items.single.name, 'Item 2');
      });

      test('throws UnsupportedError for non-FirestoreAdminFilter', () async {
        final operation = ReadListOperation<TestModel>(
          operationId: 'op6',
          details: RequestDetails(filter: UnknownFilter()),
          createdAt: DateTime.now(),
        );

        expect(
          () => source.getItems(operation),
          throwsUnsupportedError,
        );
      });
    });

    group('setItem', () {
      test('creates new item when id is null', () async {
        final mockDoc = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockCollection.add(any())).thenAnswer((_) async => mockDoc);
        when(() => mockDoc.id).thenReturn('new-id');
        when(mockDoc.get).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.id).thenReturn('new-id');
        when(mockSnapshot.data).thenReturn({'name': 'New Item'});

        const item = TestModel(name: 'New Item');
        final operation = WriteOperation<TestModel>(
          operationId: 'op7',
          item: item,
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        final result = await source.setItem(operation);

        expect(result, isA<WriteSuccess<TestModel>>());
        final success = result as WriteSuccess<TestModel>;

        expect(success.item.id, 'new-id');
        expect(success.item.name, 'New Item');

        final captured =
            verify(() => mockCollection.add(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['createdAt'], equals(gcf.FieldValue.serverTimestamp));
        expect(captured['updatedAt'], equals(gcf.FieldValue.serverTimestamp));
      });

      test('updates existing item when id is present', () async {
        final mockDoc = MockDocumentReference();
        when(() => mockCollection.doc('existing-id')).thenReturn(mockDoc);
        when(
          () => mockDoc.update(any()),
        ).thenAnswer((_) async => MockWriteResult());

        const item = TestModel(id: 'existing-id', name: 'Updated');
        final operation = WriteOperation<TestModel>(
          operationId: 'op8',
          item: item,
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        final result = await source.setItem(operation);

        expect(result, isA<WriteSuccess<TestModel>>());
        final success = result as WriteSuccess<TestModel>;
        expect(success.item, equals(item));

        final captured =
            verify(() => mockDoc.update(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['name'], 'Updated');
        expect(captured['updatedAt'], equals(gcf.FieldValue.serverTimestamp));
        expect(captured.containsKey('createdAt'), isFalse);
      });

      test('force inserts item when forceInsert is true', () async {
        final mockDoc = MockDocumentReference();
        when(() => mockCollection.doc('existing-id')).thenReturn(mockDoc);
        when(
          () => mockDoc.set(any()),
        ).thenAnswer((_) async => MockWriteResult());

        const item = TestModel(id: 'existing-id', name: 'Forced');
        final operation = WriteOperation<TestModel>(
          operationId: 'op9',
          item: item,
          details: RequestDetails(forceInsert: true),
          createdAt: DateTime.now(),
        );

        final result = await source.setItem(operation);

        expect(result, isA<WriteSuccess<TestModel>>());
        verify(() => mockDoc.set(any())).called(1);
      });
    });

    group('delete', () {
      test('deletes document successfully', () async {
        final mockDoc = MockDocumentReference();
        when(() => mockCollection.doc('doc1')).thenReturn(mockDoc);
        when(mockDoc.delete).thenAnswer((_) async => MockWriteResult());

        final operation = DeleteOperation<TestModel>(
          operationId: 'op10',
          itemId: 'doc1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        final result = await source.delete(operation);
        expect(result, isA<DeleteSuccess<TestModel>>());
        verify(mockDoc.delete).called(1);
      });
    });

    group('raw', () {
      test('merges json map with SetOptions.merge()', () async {
        final mockDoc = MockDocumentReference();
        when(() => mockCollection.doc('raw-doc')).thenReturn(mockDoc);
        when(
          () => mockDoc.set(any(), options: const gcf.SetOptions.merge()),
        ).thenAnswer((_) async => MockWriteResult());

        await source.raw('raw-doc', {
          'field1': 'val1',
          'field2': 123,
        });

        final captured =
            verify(
              () => mockDoc.set(
                captureAny(),
                options: const gcf.SetOptions.merge(),
              ),
            ).captured.single as Map<String, dynamic>;
        expect(captured['field1'], 'val1');
        expect(captured['field2'], 123);
      });

      test('cleans date fields in raw map before write', () async {
        final mockDoc = MockDocumentReference();
        when(() => mockCollection.doc('date-doc')).thenReturn(mockDoc);
        when(
          () => mockDoc.set(any(), options: const gcf.SetOptions.merge()),
        ).thenAnswer((_) async => MockWriteResult());

        final now = DateTime.utc(2024, 5, 20);
        await source.raw('date-doc', {
          'timestamp': now,
        });

        final captured =
            verify(
              () => mockDoc.set(
                captureAny(),
                options: const gcf.SetOptions.merge(),
              ),
            ).captured.single as Map<String, dynamic>;
        expect(captured['timestamp'], isA<gcf.Timestamp>());
      });
    });

    group('unsupported watch methods', () {
      test('watch throws UnimplementedError', () {
        final operation = WatchOperation<TestModel>(
          operationId: 'op_w1',
          itemId: 'doc1',
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );
        expect(() => source.watch(operation), throwsUnimplementedError);
      });

      test('watchByIds throws UnimplementedError', () {
        final operation = WatchByIdsOperation<TestModel>(
          operationId: 'op_w2',
          itemIds: {'doc1'},
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );
        expect(() => source.watchByIds(operation), throwsUnimplementedError);
      });

      test('watchList throws UnimplementedError', () {
        final operation = WatchListOperation<TestModel>(
          operationId: 'op_w3',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );
        expect(() => source.watchList(operation), throwsUnimplementedError);
      });
    });

    group('cleanData', () {
      test('converts root-level Timestamps to ISO 8601 strings', () {
        final timestamp = gcf.Timestamp.fromDate(DateTime.utc(2024));
        final data = {
          'name': 'Test',
          'createdAt': timestamp,
        };
        final cleaned = FirestoreAdminSource.cleanData(data);
        expect(cleaned['createdAt'], equals('2024-01-01T00:00:00.000Z'));
      });

      test('converts nested Timestamps in Maps', () {
        final timestamp = gcf.Timestamp.fromDate(DateTime.utc(2024));
        final data = {
          'name': 'Test',
          'metadata': {
            'updatedAt': timestamp,
          },
        };
        final cleaned = FirestoreAdminSource.cleanData(data);
        expect(
          (cleaned['metadata']! as Map)['updatedAt'],
          equals('2024-01-01T00:00:00.000Z'),
        );
      });

      test('converts nested Timestamps in Lists', () {
        final timestamp = gcf.Timestamp.fromDate(DateTime.utc(2024));
        final data = {
          'name': 'Test',
          'history': [
            {'at': timestamp},
          ],
        };
        final cleaned = FirestoreAdminSource.cleanData(data);
        expect(
          ((cleaned['history']! as List).first as Map)['at'],
          equals('2024-01-01T00:00:00.000Z'),
        );
      });

      test('handles lists with non-Map items', () {
        final data = {
          'name': 'Test',
          'tags': ['a', 'b'],
          'createdAt': gcf.Timestamp.now(),
        };
        expect(
          () => FirestoreAdminSource.cleanData(data),
          returnsNormally,
        );
      });

      test('returns same object if empty', () {
        final data = <String, dynamic>{};
        final cleaned = FirestoreAdminSource.cleanData(data);
        expect(cleaned, same(data));
      });

      test('returns same object if no Timestamps found', () {
        final data = {'name': 'Test', 'count': 1};
        final cleaned = FirestoreAdminSource.cleanData(data);
        expect(cleaned, same(data));
      });
    });

    group('cleanDataForWrite', () {
      test('converts root-level DateTimes to Timestamps', () {
        final dateTime = DateTime.utc(2024);
        final data = {
          'name': 'Test',
          'createdAt': dateTime,
        };
        final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
        expect(cleaned['createdAt'], isA<gcf.Timestamp>());
      });

      test('converts ISO 8601 string DateTimes to Timestamps', () {
        final dateTime = DateTime.utc(2024);
        final data = {
          'name': 'Test',
          'createdAt': dateTime.toIso8601String(),
        };
        final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
        expect(cleaned['createdAt'], isA<gcf.Timestamp>());
      });

      test('converts nested DateTimes in Maps', () {
        final dateTime = DateTime.utc(2024);
        final data = {
          'name': 'Test',
          'metadata': {
            'updatedAt': dateTime,
          },
        };
        final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
        expect(
          (cleaned['metadata']! as Map)['updatedAt'],
          isA<gcf.Timestamp>(),
        );
      });

      test('converts nested DateTimes in Lists', () {
        final dateTime = DateTime.utc(2024);
        final data = {
          'name': 'Test',
          'history': [
            {'at': dateTime},
          ],
        };
        final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
        expect(
          ((cleaned['history']! as List).first as Map)['at'],
          isA<gcf.Timestamp>(),
        );
      });

      test('handles lists with non-Map items', () {
        final data = {
          'name': 'Test',
          'tags': ['a', 'b'],
          'createdAt': DateTime.now(),
        };
        expect(
          () => FirestoreAdminSource.cleanDataForWrite(data),
          returnsNormally,
        );
      });

      test('does not convert non-ISO strings to Timestamps', () {
      final data = {
        'name': 'Test User',
        'email': 'test@example.com',
        'shortDate': '2024-05-15',
        'title': 'Developer',
      };
      final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
      expect(cleaned['name'], equals('Test User'));
      expect(cleaned['email'], equals('test@example.com'));
      expect(cleaned['shortDate'], equals('2024-05-15'));
      expect(cleaned['title'], equals('Developer'));
    });

    test('converts ISO 8601 strings with various formats to Timestamps', () {
      final data = {
        'isoWithMs': '2024-05-15T10:30:00.123Z',
        'isoNoMs': '2024-05-15T10:30:00Z',
        'isoLocal': '2024-05-15T10:30:00',
      };
      final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
      expect(cleaned['isoWithMs'], isA<gcf.Timestamp>());
      expect(cleaned['isoNoMs'], isA<gcf.Timestamp>());
      expect(cleaned['isoLocal'], isA<gcf.Timestamp>());
    });

    test('returns same object if empty', () {
      final data = <String, dynamic>{};
      final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
      expect(cleaned, same(data));
    });

    test('returns same object if no DateTimes found', () {
      final data = {'name': 'Test', 'count': 1};
      final cleaned = FirestoreAdminSource.cleanDataForWrite(data);
      expect(cleaned, same(data));
    });
  });

    group('exception handling', () {
      test('logs and rethrows FirestoreException', () async {
        final mockDoc = MockDocumentReference();
        when(() => mockCollection.doc('err-doc')).thenReturn(mockDoc);
        when(mockDoc.get).thenThrow(
          gcf.FirestoreException(
            gcf.FirestoreClientErrorCode.permissionDenied,
            'Permission denied',
          ),
        );

        final operation = ReadOperation<TestModel>(
          operationId: 'op_err1',
          itemId: 'err-doc',
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        expect(
          () => source.getById(operation),
          throwsA(isA<gcf.FirestoreException>()),
        );
      });

      test('logs and rethrows uncaught Exception', () async {
        final mockDoc = MockDocumentReference();
        when(() => mockCollection.doc('err-doc2')).thenReturn(mockDoc);
        when(mockDoc.get).thenThrow(Exception('Generic error'));

        final operation = ReadOperation<TestModel>(
          operationId: 'op_err2',
          itemId: 'err-doc2',
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        expect(
          () => source.getById(operation),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
