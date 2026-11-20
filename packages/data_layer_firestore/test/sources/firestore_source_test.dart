import 'package:cloud_firestore/cloud_firestore.dart' as cf show Filter;
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

// Concrete FirestoreFilter using toFirestoreFilter() for testing OR/AND combos
class TestPredicateFilter extends FirestoreFilter {
  const TestPredicateFilter(this.predicate);

  final cf.Filter predicate;

  @override
  cf.Filter toFirestoreFilter() => predicate;

  @override
  String get cacheKey => 'test-predicate-filter';

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

      group('pagination', () {
        test('limits results by pageSize on first page', () async {
          await collection.add({'name': 'Item 1'});
          await collection.add({'name': 'Item 2'});
          await collection.add({'name': 'Item 3'});
          await collection.add({'name': 'Item 4'});
          await collection.add({'name': 'Item 5'});

          final operation = ReadListOperation<TestModel>(
            operationId: 'op_page1',
            details: RequestDetails.read(
              pagination: Pagination.page(1, pageSize: 2),
            ),
            createdAt: DateTime.now(),
          );

          final result = await source.getItems(operation);

          final success = result as ReadListSuccess<TestModel>;
          expect(success.items.length, 2);
          expect(
            success.items.map((i) => i.name).toList(),
            ['Item 1', 'Item 2'],
          );
        });

        test('skips items on subsequent pages', () async {
          await collection.add({'name': 'Item 1'});
          await collection.add({'name': 'Item 2'});
          await collection.add({'name': 'Item 3'});
          await collection.add({'name': 'Item 4'});
          await collection.add({'name': 'Item 5'});

          final opPage2 = ReadListOperation<TestModel>(
            operationId: 'op_page2',
            details: RequestDetails.read(
              pagination: Pagination.page(2, pageSize: 2),
            ),
            createdAt: DateTime.now(),
          );

          final result2 = await source.getItems(opPage2);
          final success2 = result2 as ReadListSuccess<TestModel>;
          expect(success2.items.length, 2);
          expect(
            success2.items.map((i) => i.name).toList(),
            ['Item 3', 'Item 4'],
          );

          final opPage3 = ReadListOperation<TestModel>(
            operationId: 'op_page3',
            details: RequestDetails.read(
              pagination: Pagination.page(3, pageSize: 2),
            ),
            createdAt: DateTime.now(),
          );

          final result3 = await source.getItems(opPage3);
          final success3 = result3 as ReadListSuccess<TestModel>;
          expect(success3.items.length, 1);
          expect(success3.items.map((i) => i.name).toList(), ['Item 5']);

          final opPage4 = ReadListOperation<TestModel>(
            operationId: 'op_page4',
            details: RequestDetails.read(
              pagination: Pagination.page(4, pageSize: 2),
            ),
            createdAt: DateTime.now(),
          );

          final result4 = await source.getItems(opPage4);
          final success4 = result4 as ReadListSuccess<TestModel>;
          expect(success4.items, isEmpty);
        });

        test('applies cursor-based pagination', () async {
          await collection.add({'name': 'Item 1'});
          final doc2 = await collection.add({'name': 'Item 2'});
          await collection.add({'name': 'Item 3'});
          await collection.add({'name': 'Item 4'});
          await collection.add({'name': 'Item 5'});

          final operation = ReadListOperation<TestModel>(
            operationId: 'op_cursor',
            details: RequestDetails.read(
              pagination: Pagination.cursor(doc2.id, pageSize: 2),
            ),
            createdAt: DateTime.now(),
          );

          final result = await source.getItems(operation);

          final success = result as ReadListSuccess<TestModel>;
          expect(success.items.length, 2);
          expect(
            success.items.map((i) => i.name).toList(),
            ['Item 3', 'Item 4'],
          );
        });

        test('applies both filter and pagination', () async {
          await collection.add({'name': 'Apple', 'type': 'fruit'});
          await collection.add({'name': 'Banana', 'type': 'fruit'});
          await collection.add({'name': 'Carrot', 'type': 'vegetable'});
          await collection.add({'name': 'Date', 'type': 'fruit'});

          final filter = TestFilter(
            (query) => query.where('type', isEqualTo: 'fruit'),
          );

          final operation = ReadListOperation<TestModel>(
            operationId: 'op_filter_page',
            details: RequestDetails.read(
              filter: filter,
              pagination: Pagination.page(1, pageSize: 2),
            ),
            createdAt: DateTime.now(),
          );

          final result = await source.getItems(operation);

          final success = result as ReadListSuccess<TestModel>;
          expect(success.items.length, 2);
          expect(
            success.items.map((i) => i.name).toList(),
            ['Apple', 'Banana'],
          );
        });
      });

      group('ComboFilter', () {
        test('applies ComboFilter with BooleanLogic.and', () async {
          await collection.add({'name': 'Apple', 'type': 'fruit'});
          await collection.add({'name': 'Banana', 'type': 'fruit'});
          await collection.add({'name': 'Apple', 'type': 'pie'});

          final filter = ComboFilter(
            [
              TestFilter((q) => q.where('name', isEqualTo: 'Apple')),
              TestFilter((q) => q.where('type', isEqualTo: 'fruit')),
            ],
            BooleanLogic.and,
          );
          final operation = ReadListOperation<TestModel>(
            operationId: 'op_combo_and',
            details: RequestDetails(filter: filter),
            createdAt: DateTime.now(),
          );

          final result = await source.getItems(operation);

          final success = result as ReadListSuccess<TestModel>;
          expect(success.items.length, 1);
          expect(success.items.single.name, 'Apple');
        });

        test('applies ComboFilter with BooleanLogic.or', () async {
          await collection.add({'name': 'Apple', 'type': 'fruit'});
          await collection.add({'name': 'Banana', 'type': 'fruit'});
          await collection.add({'name': 'Carrot', 'type': 'vegetable'});

          final filter = ComboFilter(
            [
              TestPredicateFilter(cf.Filter('name', isEqualTo: 'Apple')),
              TestPredicateFilter(cf.Filter('type', isEqualTo: 'vegetable')),
            ],
            BooleanLogic.or,
          );
          final operation = ReadListOperation<TestModel>(
            operationId: 'op_combo_or',
            details: RequestDetails(filter: filter),
            createdAt: DateTime.now(),
          );

          final result = await source.getItems(operation);

          final success = result as ReadListSuccess<TestModel>;
          expect(
            success.items.map((i) => i.name).toList(),
            containsAll(['Apple', 'Carrot']),
          );
          expect(success.items.length, 2);
        });

        test('applies nested ComboFilter with mixed AND/OR logic', () async {
          await collection.add({'name': 'Apple', 'type': 'fruit'});
          await collection.add({'name': 'Apple', 'type': 'pie'});
          await collection.add({'name': 'Carrot', 'type': 'vegetable'});

          final filter = ComboFilter(
            [
              ComboFilter(
                [
                  TestPredicateFilter(cf.Filter('name', isEqualTo: 'Apple')),
                  TestPredicateFilter(cf.Filter('type', isEqualTo: 'fruit')),
                ],
                BooleanLogic.and,
              ),
              TestPredicateFilter(cf.Filter('name', isEqualTo: 'Carrot')),
            ],
            BooleanLogic.or,
          );
          final operation = ReadListOperation<TestModel>(
            operationId: 'op_combo_nested',
            details: RequestDetails(filter: filter),
            createdAt: DateTime.now(),
          );

          final result = await source.getItems(operation);

          final success = result as ReadListSuccess<TestModel>;
          expect(success.items.length, 2);
          expect(
            success.items.map((i) => i.name).toList(),
            containsAll(['Apple', 'Carrot']),
          );
        });

        test(
          'throws UnsupportedError when BooleanLogic.or child lacks '
          'toFirestoreFilter',
          () async {
            final filter = ComboFilter(
              [
                TestFilter((q) => q.where('name', isEqualTo: 'Apple')),
                TestPredicateFilter(cf.Filter('name', isEqualTo: 'Banana')),
              ],
              BooleanLogic.or,
            );
            final operation = ReadListOperation<TestModel>(
              operationId: 'op_combo_or_unsupported',
              details: RequestDetails(filter: filter),
              createdAt: DateTime.now(),
            );

            expect(
              () => source.getItems(operation),
              throwsUnsupportedError,
            );
          },
        );

        test(
          'throws UnsupportedError when ComboFilter contains '
          'non-FirestoreFilter',
          () async {
            final filter = ComboFilter(
              [
                TestFilter((q) => q.where('name', isEqualTo: 'Apple')),
                UnknownFilter(),
              ],
              BooleanLogic.and,
            );
            final operation = ReadListOperation<TestModel>(
              operationId: 'op_combo_unknown',
              details: RequestDetails(filter: filter),
              createdAt: DateTime.now(),
            );

            expect(
              () => source.getItems(operation),
              throwsUnsupportedError,
            );
          },
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

    group('deleteItem', () {
      test('deletes existing document successfully', () async {
        final doc = await collection.add({'name': 'To Delete'});
        final operation = DeleteOperation<TestModel>(
          operationId: 'del1',
          itemId: doc.id,
          details: RequestDetails.write(),
          createdAt: DateTime.now(),
        );

        final result = await source.deleteItem(operation);
        expect(result, isA<DeleteSuccess<TestModel>>());

        final stored = await collection.doc(doc.id).get();
        expect(stored.exists, isFalse);
      });
    });

    group('deleteItems', () {
      test('deletes all documents when no filter specified', () async {
        await collection.add({'name': 'Item 1'});
        await collection.add({'name': 'Item 2'});

        final operation = DeleteListOperation<TestModel>(
          operationId: 'delList1',
          details: RequestDetails.delete(),
          createdAt: DateTime.now(),
        );

        final result = await source.deleteItems(operation);
        expect(result, isA<DeleteSuccess<TestModel>>());

        final remaining = await collection.get();
        expect(remaining.docs, isEmpty);
      });

      test('deletes only matching documents when filter specified', () async {
        await collection.add({'name': 'Delete Me', 'type': 'A'});
        final doc2 = await collection.add({'name': 'Keep Me', 'type': 'B'});

        final filter = TestFilter(
          (query) => query.where('type', isEqualTo: 'A'),
        );
        final operation = DeleteListOperation<TestModel>(
          operationId: 'delList2',
          details: RequestDetails.delete(filter: filter),
          createdAt: DateTime.now(),
        );

        final result = await source.deleteItems(operation);
        expect(result, isA<DeleteSuccess<TestModel>>());

        final remaining = await collection.get();
        expect(remaining.docs.length, 1);
        expect(remaining.docs.first.id, doc2.id);
      });

      test('deletes matching documents when ComboFilter specified', () async {
        await collection.add({'name': 'Delete A', 'type': 'A'});
        await collection.add({'name': 'Delete B', 'type': 'B'});
        final docC = await collection.add({'name': 'Keep C', 'type': 'C'});

        final filter = ComboFilter(
          [
            TestPredicateFilter(cf.Filter('type', isEqualTo: 'A')),
            TestPredicateFilter(cf.Filter('type', isEqualTo: 'B')),
          ],
          BooleanLogic.or,
        );
        final operation = DeleteListOperation<TestModel>(
          operationId: 'delListCombo',
          details: RequestDetails.delete(filter: filter),
          createdAt: DateTime.now(),
        );

        final result = await source.deleteItems(operation);
        expect(result, isA<DeleteSuccess<TestModel>>());

        final remaining = await collection.get();
        expect(remaining.docs.length, 1);
        expect(remaining.docs.first.id, docC.id);
      });
    });

    group('raw', () {
      test('merges json map into existing document', () async {
        final doc = await collection.add({
          'name': 'Original Name',
          'age': 30,
        });

        await source.raw(doc.id, {
          'age': 31,
          'city': 'San Francisco',
        });

        final stored = await collection.doc(doc.id).get();
        expect(stored.data()!['name'], 'Original Name');
        expect(stored.data()!['age'], 31);
        expect(stored.data()!['city'], 'San Francisco');
      });

      test('creates document if it does not exist', () async {
        await source.raw('new-doc-id', {
          'name': 'New Document',
          'status': 'active',
        });

        final stored = await collection.doc('new-doc-id').get();
        expect(stored.exists, isTrue);
        expect(stored.data()!['name'], 'New Document');
        expect(stored.data()!['status'], 'active');
      });

      test('cleans date fields in raw map before write', () async {
        final now = DateTime.utc(2024, 5, 20);
        await source.raw('doc-with-date', {
          'timestamp': now,
        });

        final stored = await collection.doc('doc-with-date').get();
        expect(stored.data()!['timestamp'], isA<Timestamp>());
        expect(
          (stored.data()!['timestamp']! as Timestamp).toDate(),
          equals(now.toLocal()),
        );
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
