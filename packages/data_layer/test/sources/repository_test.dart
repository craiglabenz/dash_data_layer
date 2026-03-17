import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

void main() {
  final sl = FakeSourceList<TestModel>(TestModel.bindings)
    ..addObj(const TestModel(id: 'does not matter'));
  final repo = Repository<TestModel>(sl);
  const TestModel obj = TestModel(id: 'also does not matter');

  group('Repository methods should pass through to SourceList', () {
    final emptyDetails = RequestDetails();
    test('including getById', () async {
      expect(
        await repo.getById('also does not matter', emptyDetails),
        isA<TestModel>(),
      );
    }, timeout: const Timeout(Duration(seconds: 1)));
    test(
      'including getById with missingIds',
      () async {
        final (items, missingIds) = await repo.getByIds({
          'also does not matter',
        }, emptyDetails);
        expect(items, isA<List<TestModel>>());
        expect(missingIds, isA<Set<String>>());
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test(
      'including getItems',
      () async {
        expect(
          await repo.getItems(details: emptyDetails),
          isA<List<TestModel>>(),
        );
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
    test(
      'including setItem',
      () async {
        expect(
          await repo.setItem(obj, emptyDetails),
          isA<TestModel>(),
        );
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
    test(
      'including setItems',
      () async {
        expect(
          await repo.setItems([obj], emptyDetails),
          isA<List<TestModel>>(),
        );
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('including watch', () async {
      final stream = repo.watch('also does not matter', emptyDetails);
      final futureFirst = stream.first;

      await Future<void>.delayed(const Duration(milliseconds: 10));
      sl.watchController.add(
        ReadResult<TestModel>.success(obj, details: emptyDetails),
      );
      expect(await futureFirst, isA<TestModel>());
    }, timeout: const Timeout(Duration(seconds: 1)));

    test('including watchList', () async {
      final stream = repo.watchList(details: emptyDetails);
      final futureFirst = stream.first;

      await Future<void>.delayed(const Duration(milliseconds: 10));
      sl.watchListController.add(
        ReadListResult<TestModel>.fromList(
              [obj],
              emptyDetails,
              const {},
              TestModel.bindings.getId,
            )
            as ReadListSuccess<TestModel>,
      );
      expect(await futureFirst, isA<List<TestModel>>());
    }, timeout: const Timeout(Duration(seconds: 1)));

    test('including watchByIds', () async {
      final stream = repo.watchByIds(
        {'also does not matter'},
        emptyDetails,
      );
      final futureFirst = stream.first;

      await Future<void>.delayed(const Duration(milliseconds: 10));
      sl.watchByIdsController.add(
        ReadListResult<TestModel>.fromList(
              [obj],
              emptyDetails,
              const {},
              TestModel.bindings.getId,
            )
            as ReadListSuccess<TestModel>,
      );
      final (items, missing) = await futureFirst;
      expect(items, isA<List<TestModel>>());
      expect(missing, isA<Set<String>>());
    }, timeout: const Timeout(Duration(seconds: 1)));
  });
}
