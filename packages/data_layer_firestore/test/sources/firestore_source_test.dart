import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:data_layer/data_layer.dart' hide Source;
import 'package:data_layer_firestore/sources/firestore_filters.dart';
import 'package:data_layer_firestore/sources/firestore_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../models/test_model.dart';

// Concrete FirestoreFilter for testing
class TestFilter extends FirestoreFilter {
  const TestFilter(this.filterFn);

  final Query<Json> Function(Query<Json>) filterFn;

  @override
  Query<Json> apply(Query<Json> query) => filterFn(query);

  @override
  String get cacheKey => 'test-filter';

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
  group('FirestoreSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreSource<TestModel> source;
    late Bindings<TestModel> bindings;
    late CollectionReference<Json> collection;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      bindings = Bindings<TestModel>(
        getId: (item) => item.id,
        fromJson: TestModel.fromJson,
        toJson: (item) => item.toJson(),
      );
      source = FirestoreSource(
        firestore,
        bindings: bindings,
        collectionName: 'testModels',
      );
      collection = firestore.collection('testModels');
    });

    group('getById', () {
      test('returns success with data when document exists', () async {
        final data = {'name': 'Test Item'};
        final docRef = await collection.add(data);
        final operation = ReadOperation<TestModel>(
          operationId: 'op1',
          itemId: docRef.id,
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        final result = await source.getById(operation);

        expect(result, isA<ReadSuccess<TestModel>>());
        final success = result as ReadSuccess<TestModel>;
        expect(
          success.item,
          equals(TestModel.fromJson({'id': docRef.id, ...data})),
        );
      });

      test('returns success with null when document does not exist', () async {
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
      test('returns items and identifying missing ids', () async {
        final doc1 = await collection.add({'name': 'Item 1'});
        final doc2 = await collection.add({'name': 'Item 2'});
        const missingId = 'missing-id';

        final operation = ReadByIdsOperation<TestModel>(
          operationId: 'op3',
          itemIds: {doc1.id, doc2.id, missingId},
          details: RequestDetails.read(),
          createdAt: DateTime.now(),
        );

        final result = await source.getByIds(operation);

        expect(result, isA<ReadListResult<TestModel>>());
        final success = result as ReadListSuccess<TestModel>;

        expect(success.items.length, 2);
        expect(
          success.items.map((e) => e.id),
          containsAll([doc1.id, doc2.id]),
        );
        expect(success.missingItemIds, contains(missingId));
      });
    });

    group('getItems', () {
      test('returns all items when no filter provided', () async {
        await collection.add({'name': 'Item 1'});
        await collection.add({'name': 'Item 2'});

        final operation = ReadListOperation<TestModel>(
          operationId: 'op4',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        final result = await source.getItems(operation);

        final success = result as ReadListSuccess<TestModel>;
        expect(success.items.length, 2);
      });

      test('applies FirestoreFilter correctly', () async {
        await collection.add({'name': 'Item 1'});
        await collection.add({'name': 'Item 2'});
        await collection.add({'name': 'Item 3'});

        final filter = TestFilter(
          (query) => query.where('name', isEqualTo: 'Item 2'),
        );
        final operation = ReadListOperation<TestModel>(
          operationId: 'op5',
          details: RequestDetails(filter: filter),
          createdAt: DateTime.now(),
        );

        final result = await source.getItems(operation);

        final success = result as ReadListSuccess<TestModel>;
        expect(success.items.length, 1);
        expect(success.items.every((i) => i.name == 'Item 2'), isTrue);
      });

      test('throws UnsupportedError for non-FirestoreFilter', () async {
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

        expect(success.item.id, isNotNull);
        expect(success.item.name, 'New Item');

        final stored = await collection.doc(success.item.id).get();
        expect(stored.exists, isTrue);
      });

      test('updates existing item when id is present', () async {
        final doc = await collection.add({'name': 'Original'});
        final updatedItem = TestModel.fromJson({
          'id': doc.id,
          'name': 'Updated',
        });

        final operation = WriteOperation<TestModel>(
          operationId: 'op9',
          item: updatedItem,
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        final result = await source.setItem(operation);

        expect(result, isA<WriteSuccess<TestModel>>());

        final stored = await collection.doc(doc.id).get();
        expect(stored.data()!['name'], 'Updated');

        // Ensure ID wasn't written as a field (implementation detail check)
        expect(stored.data()!['id'], isNull);
      });
    });

    group('cleanData', () {
      test('converts root-level Timestamps to ISO 8601 strings', () {
        final timestamp = Timestamp.fromDate(DateTime.utc(2024));
        final data = {
          'name': 'Test',
          'createdAt': timestamp,
        };
        final cleaned = FirestoreSource.cleanData(data);
        expect(cleaned['createdAt'], equals('2024-01-01T00:00:00.000Z'));
      });

      test('converts nested Timestamps in Maps', () {
        final timestamp = Timestamp.fromDate(DateTime.utc(2024));
        final data = {
          'name': 'Test',
          'metadata': {
            'updatedAt': timestamp,
          },
        };
        // This currently FAILS because it returns early if no Timestamps at
        // root.
        final cleaned = FirestoreSource.cleanData(data);
        expect(
          (cleaned['metadata']! as Map)['updatedAt'],
          equals('2024-01-01T00:00:00.000Z'),
        );
      });

      test('converts nested Timestamps in Lists', () {
        final timestamp = Timestamp.fromDate(DateTime.utc(2024));
        final data = {
          'name': 'Test',
          'history': [
            {'at': timestamp},
          ],
        };
        // This also currently FAILS for same reason
        final cleaned = FirestoreSource.cleanData(data);
        expect(
          ((cleaned['history']! as List).first as Map)['at'],
          equals('2024-01-01T00:00:00.000Z'),
        );
      });

      test('handles lists with non-Map items', () {
        final data = {
          'name': 'Test',
          'tags': ['a', 'b'],
          'createdAt': Timestamp.now(),
        };
        // This will FAIL currently because (e as Json) in e.map(...)
        expect(() => FirestoreSource.cleanData(data), returnsNormally);
      });

      test('returns same object if empty', () {
        final data = <String, dynamic>{};
        final cleaned = FirestoreSource.cleanData(data);
        expect(cleaned, same(data));
      });

      test('returns same object if no Timestamps found', () {
        final data = {'name': 'Test', 'count': 1};
        final cleaned = FirestoreSource.cleanData(data);
        expect(cleaned, same(data));
      });
    });
  });

  group('cleanDataForWrite', () {
    test('converts root-level DateTimes to Timestamps', () {
      final dateTime = DateTime.utc(2024);
      final data = {
        'name': 'Test',
        'createdAt': dateTime,
      };
      final cleaned = FirestoreSource.cleanDataForWrite(data);
      expect(cleaned['createdAt'], isA<Timestamp>());
      expect(
        (cleaned['createdAt']! as Timestamp).toDate(),
        equals(dateTime.toLocal()),
      );
    });

    test('converts ISO 8601 string DateTimes to Timestamps', () {
      final dateTime = DateTime.utc(2024);
      final data = {
        'name': 'Test',
        'createdAt': dateTime.toIso8601String(),
      };
      final cleaned = FirestoreSource.cleanDataForWrite(data);
      expect(cleaned['createdAt'], isA<Timestamp>());
      expect(
        (cleaned['createdAt']! as Timestamp).toDate(),
        equals(dateTime.toLocal()),
      );
    });

    test('converts nested DateTimes in Maps', () {
      final dateTime = DateTime.utc(2024);
      final data = {
        'name': 'Test',
        'metadata': {
          'updatedAt': dateTime,
        },
      };
      final cleaned = FirestoreSource.cleanDataForWrite(data);
      expect((cleaned['metadata']! as Map)['updatedAt'], isA<Timestamp>());
      expect(
        ((cleaned['metadata']! as Map)['updatedAt'] as Timestamp).toDate(),
        equals(dateTime.toLocal()),
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
      final cleaned = FirestoreSource.cleanDataForWrite(data);
      expect(
        ((cleaned['history']! as List).first as Map)['at'],
        isA<Timestamp>(),
      );
      expect(
        (((cleaned['history']! as List).first as Map)['at'] as Timestamp)
            .toDate(),
        equals(dateTime.toLocal()),
      );
    });

    test('does not convert non-ISO strings to Timestamps', () {
      final data = {
        'name': 'Test User',
        'email': 'test@example.com',
        'shortDate': '2024-05-15',
        'title': 'Developer',
      };
      final cleaned = FirestoreSource.cleanDataForWrite(data);
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
      final cleaned = FirestoreSource.cleanDataForWrite(data);
      expect(cleaned['isoWithMs'], isA<Timestamp>());
      expect(cleaned['isoNoMs'], isA<Timestamp>());
      expect(cleaned['isoLocal'], isA<Timestamp>());

      final parsedMs = DateTime.parse('2024-05-15T10:30:00.123Z');
      expect(
        (cleaned['isoWithMs']! as Timestamp).toDate(),
        equals(parsedMs.toLocal()),
      );
    });

    test('returns same object if empty', () {
      final data = <String, dynamic>{};
      final cleaned = FirestoreSource.cleanDataForWrite(data);
      expect(cleaned, same(data));
    });

    test('returns same object if no DateTimes found', () {
      final data = {'name': 'Test', 'count': 1};
      final cleaned = FirestoreSource.cleanDataForWrite(data);
      expect(cleaned, same(data));
    });
  });
}
