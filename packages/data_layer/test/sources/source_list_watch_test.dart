import 'dart:async';
import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';
import 'operation_builders.dart';

class CountingWatchableSource extends Source<TestModel>
    with WatchableSource<TestModel> {
  CountingWatchableSource({this.isRemote = true})
    : super(bindings: TestModel.bindings);

  final bool isRemote;

  @override
  SourceType get sourceType => isRemote ? SourceType.remote : SourceType.local;

  int listenCount = 0;
  int cancelCount = 0;

  final watchControllers =
      <CacheKey, StreamController<ReadResult<TestModel>>>{};
  final watchListControllers =
      <CacheKey, StreamController<ReadListResult<TestModel>>>{};
  final watchByIdsControllers =
      <CacheKey, StreamController<ReadListResult<TestModel>>>{};

  final watchController = StreamController<ReadResult<TestModel>>.broadcast();
  final watchListController =
      StreamController<ReadListResult<TestModel>>.broadcast();
  final watchByIdsController =
      StreamController<ReadListResult<TestModel>>.broadcast();

  @override
  Stream<ReadResult<TestModel>> watch(WatchOperation<TestModel> operation) {
    return Stream.multi((controller) {
      listenCount++;
      final sub = watchController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      final specificSub = watchControllers
          .putIfAbsent(operation.cacheKey, StreamController.broadcast)
          .stream
          .listen(controller.add, onError: controller.addError);
      controller.onCancel = () {
        sub.cancel().ignore();
        specificSub.cancel().ignore();
        cancelCount++;
      };
    });
  }

  @override
  Stream<ReadListResult<TestModel>> watchList(
    WatchListOperation<TestModel> operation,
  ) {
    return Stream.multi((controller) {
      listenCount++;
      final sub = watchListController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      final specificSub = watchListControllers
          .putIfAbsent(operation.cacheKey, StreamController.broadcast)
          .stream
          .listen(controller.add, onError: controller.addError);
      controller.onCancel = () {
        sub.cancel().ignore();
        specificSub.cancel().ignore();
        cancelCount++;
      };
    });
  }

  @override
  Stream<ReadListResult<TestModel>> watchByIds(
    WatchByIdsOperation<TestModel> operation,
  ) {
    return Stream.multi((controller) {
      listenCount++;
      final sub = watchByIdsController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      final specificSub = watchByIdsControllers
          .putIfAbsent(operation.cacheKey, StreamController.broadcast)
          .stream
          .listen(controller.add, onError: controller.addError);
      controller.onCancel = () {
        sub.cancel().ignore();
        specificSub.cancel().ignore();
        cancelCount++;
      };
    });
  }

  @override
  Future<DeleteResult<TestModel>> delete(
    DeleteOperation<TestModel> operation,
  ) async => throw UnimplementedError();

  @override
  Future<ReadResult<TestModel>> getById(
    ReadOperation<TestModel> operation,
  ) async => throw UnimplementedError();

  @override
  Future<ReadListResult<TestModel>> getByIds(
    ReadByIdsOperation<TestModel> operation,
  ) async => throw UnimplementedError();

  @override
  Future<ReadListResult<TestModel>> getItems(
    ReadListOperation<TestModel> operation,
  ) async => throw UnimplementedError();

  @override
  Future<WriteResult<TestModel>> setItem(
    WriteOperation<TestModel> operation,
  ) async => throw UnimplementedError();

  @override
  Future<WriteListResult<TestModel>> setItems(
    WriteListOperation<TestModel> operation,
  ) async => throw UnimplementedError();
}

void main() {
  group('SourceList.watch should', () {
    late CountingWatchableSource watchableSource;
    late LocalMemorySource<TestModel> cacheSource;
    late SourceList<TestModel> sourceList;

    setUp(() {
      watchableSource = CountingWatchableSource();
      cacheSource = LocalMemorySource<TestModel>(bindings: TestModel.bindings);
      sourceList = SourceList<TestModel>(
        sources: [cacheSource, watchableSource],
        bindings: TestModel.bindings,
        getTime: () => DateTime.now().toUtc(),
      );
    });

    test(
      'connect to inner source only once for same cache key and broadcast',
      () async {
        final op = gwo_watch('123', RequestDetails());
        final stream1 = sourceList.watch(op);
        final stream2 = sourceList.watch(op);

        expect(
          identical(stream1, stream2),
          isTrue,
          reason: 'Should return identical cached streams for same cache key',
        );

        expect(watchableSource.listenCount, 0);

        final sub1 = stream1.listen((_) {});
        await Future<void>.microtask(() {});

        expect(watchableSource.listenCount, 1);

        final sub2 = stream2.listen((_) {});
        await Future<void>.microtask(() {});
        expect(watchableSource.listenCount, 1);

        await sub1.cancel();
        await Future<void>.microtask(() {});
        expect(watchableSource.cancelCount, 0);

        await sub2.cancel();
        // Give time for the onCancel hook and remove from active list
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(watchableSource.cancelCount, 1);

        final stream3 = sourceList.watch(op);
        expect(identical(stream1, stream3), isFalse);
      },
    );

    test('automatically cache values into LocalSources', () async {
      final op = gwo_watch('123', RequestDetails());
      final stream = sourceList.watch(op);
      final sub = stream.listen((_) {});
      await Future<void>.microtask(() {});

      final initialRead = await cacheSource.getById(
        gro('123', RequestDetails(requestType: RequestType.local)),
      );
      expect(initialRead, isA<ReadSuccess<TestModel>>());
      expect((initialRead as ReadSuccess<TestModel>).item, isNull);

      const itemToPush = TestModel(id: '123', msg: 'Intercepted!');
      watchableSource.watchController.add(
        ReadSuccess(itemToPush, details: op.details),
      );

      // Allow async code inside stream subscription to settle
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final subsequentRead = await cacheSource.getById(
        gro('123', RequestDetails(requestType: RequestType.local)),
      );
      expect(subsequentRead, isA<ReadSuccess<TestModel>>());
      expect(
        (subsequentRead as ReadSuccess<TestModel>).item!.msg,
        'Intercepted!',
      );

      await sub.cancel();
    });

    test(
      'result in cache hits for subsequent SourceList.getById calls',
      () async {
        final watchOp = gwo_watch('123', RequestDetails());
        final stream = sourceList.watch(watchOp);
        final sub = stream.listen((_) {});
        await Future<void>.microtask(() {});

        const itemToPush = TestModel(id: '123', msg: 'StreamedValue');
        watchableSource.watchController.add(
          ReadSuccess(itemToPush, details: watchOp.details),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Read through SourceList with getById
        final getResult = await sourceList.getById(
          gro('123', RequestDetails()),
        );
        expect(getResult, isA<ReadSuccess<TestModel>>());
        final success = getResult as ReadSuccess<TestModel>;
        expect(success.item?.msg, 'StreamedValue');

        await sub.cancel();
      },
    );

    test('throw StateError if no WatchableSource found for request', () {
      final op = gwo_watch(
        '123',
        RequestDetails(requestType: RequestType.local),
      );
      // Local request will ignore the remote CountingWatchableSource
      expect(() => sourceList.watch(op), throwsA(isA<StateError>()));
    });

    test('propagate failures from inner source', () async {
      final op = gwo_watch('123', RequestDetails());
      final stream = sourceList.watch(op);

      ReadResult<TestModel>? lastResult;
      Object? lastError;

      final sub = stream.listen(
        (r) => lastResult = r,
        onError: (Object e) => lastError = e,
      );
      await Future<void>.microtask(() {});

      watchableSource.watchController.add(
        const ReadResult<TestModel>.failure(.serverError, 'foo error'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(lastResult, isA<ReadFailure<TestModel>>());
      expect(
        (lastResult as ReadFailure?)!.message,
        contains('foo error'),
      );
      expect(lastError, isNull);

      watchableSource.watchController.addError(Exception('stream error'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(lastError, isA<Exception>());
      expect(lastError.toString(), contains('stream error'));

      await sub.cancel();
    });
  });

  group('SourceList.watchList should', () {
    late CountingWatchableSource watchableSource;
    late LocalMemorySource<TestModel> cacheSource;
    late SourceList<TestModel> sourceList;

    setUp(() {
      watchableSource = CountingWatchableSource();
      cacheSource = LocalMemorySource<TestModel>(bindings: TestModel.bindings);
      sourceList = SourceList<TestModel>(
        sources: [cacheSource, watchableSource],
        bindings: TestModel.bindings,
        getTime: () => DateTime.now().toUtc(),
      );
    });

    test('cache items into LocalSources', () async {
      final op = gwlo_watch(RequestDetails());
      final stream = sourceList.watchList(op);
      final sub = stream.listen((_) {});
      await Future<void>.microtask(() {});

      final initialRead = await cacheSource.getItems(
        grlo(RequestDetails(requestType: RequestType.local)),
      );
      expect(initialRead, isA<ReadListSuccess<TestModel>>());
      expect((initialRead as ReadListSuccess<TestModel>).items, isEmpty);

      const item1 = TestModel(id: '1', msg: 'Intercepted 1!');
      const item2 = TestModel(id: '2', msg: 'Intercepted 2!');

      watchableSource.watchListController.add(
        ReadListResult.fromList(
              [item1, item2],
              op.details,
              const {},
              (i) => i.id,
            )
            as ReadListSuccess<TestModel>,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final subsequentRead = await cacheSource.getItems(
        grlo(RequestDetails(requestType: RequestType.local)),
      );
      expect(subsequentRead, isA<ReadListSuccess<TestModel>>());
      final items = (subsequentRead as ReadListSuccess<TestModel>).items;
      expect(items.length, 2);
      expect(items.map((i) => i.id), containsAll(['1', '2']));

      await sub.cancel();
    });

    test(
      'result in cache hits for subsequent SourceList.getItems calls',
      () async {
        final watchOp = gwlo_watch(RequestDetails());
        final stream = sourceList.watchList(watchOp);
        final sub = stream.listen((_) {});
        await Future<void>.microtask(() {});

        const item1 = TestModel(id: '1', msg: 'StreamedList1');
        const item2 = TestModel(id: '2', msg: 'StreamedList2');
        watchableSource.watchListController.add(
          ReadListResult.fromList(
                [item1, item2],
                watchOp.details,
                const {},
                (i) => i.id,
              )
              as ReadListSuccess<TestModel>,
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final getItemsResult = await sourceList.getItems(
          grlo(RequestDetails()),
        );
        expect(getItemsResult, isA<ReadListSuccess<TestModel>>());
        final success = getItemsResult as ReadListSuccess<TestModel>;
        expect(
          success.items.map((i) => i.msg),
          containsAll(['StreamedList1', 'StreamedList2']),
        );

        await sub.cancel();
      },
    );

    test('remove missing values from local sources', () async {
      final localOp = grlo(
        RequestDetails(filter: const MsgStartsWithFilter('old')),
      );
      await cacheSource.setItems(
        gwlo([
          const TestModel(id: '1', msg: 'old_msg'),
          const TestModel(id: '2', msg: 'old_msg_2'),
        ], localOp.details),
      );
      final cacheCheck = await cacheSource.getItems(localOp);
      expect((cacheCheck as ReadListSuccess<TestModel>).items, hasLength(2));

      final op = gwlo_watch(
        RequestDetails(filter: const MsgStartsWithFilter('old')),
      );
      final stream = sourceList.watchList(op);
      final sub = stream.listen((_) {});
      await Future<void>.microtask(() {});

      watchableSource.watchListController.add(
        ReadListResult<TestModel>.fromList(
              [const TestModel(id: '2', msg: 'old_msg_2')],
              op.details,
              const {},
              (i) => i.id,
            )
            as ReadListSuccess<TestModel>,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final subsequentRead = await cacheSource.getItems(
        grlo(
          RequestDetails(
            filter: const MsgStartsWithFilter('old'),
            requestType: .local,
          ),
        ),
      );

      expect(subsequentRead, isA<ReadListSuccess<TestModel>>());
      final items = (subsequentRead as ReadListSuccess<TestModel>).items;
      expect(items, hasLength(1));
      expect(items.first, const TestModel(id: '2', msg: 'old_msg_2'));

      final emptyRead = await cacheSource.getItems(
        grlo(RequestDetails(requestType: RequestType.local)),
      );
      expect((emptyRead as ReadListSuccess<TestModel>).items, isEmpty);

      await sub.cancel();
    });

    test('clear cache on empty return if RequestType is standard', () async {
      final localOp = grlo(
        RequestDetails(filter: const MsgStartsWithFilter('old')),
      );
      await cacheSource.setItems(
        gwlo([const TestModel(id: '1', msg: 'old_msg')], localOp.details),
      );

      final cacheCheck = await cacheSource.getItems(localOp);
      expect((cacheCheck as ReadListSuccess).items, isNotEmpty);

      final op = gwlo_watch(
        RequestDetails(filter: const MsgStartsWithFilter('old')),
      );
      final stream = sourceList.watchList(op);
      final sub = stream.listen((_) {});
      await Future<void>.microtask(() {});

      // Yield an empty list from watchList
      watchableSource.watchListController.add(
        ReadListResult<TestModel>.empty(op.details)
            as ReadListSuccess<TestModel>,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final checkAgain = await cacheSource.getItems(localOp);
      expect((checkAgain as ReadListSuccess).items, isEmpty);

      await sub.cancel();
    });

    test(
      'never cross the streams (in accordance with Ghostbusters lore)',
      () async {
        final op1 = gwlo_watch(
          RequestDetails(filter: const MsgStartsWithFilter('key1')),
        );
        final op2 = gwlo_watch(
          RequestDetails(filter: const MsgStartsWithFilter('key2')),
        );

        final stream1 = sourceList.watchList(op1);
        final stream2 = sourceList.watchList(op2);

        ReadListResult<TestModel>? lastResult1;
        ReadListResult<TestModel>? lastResult2;

        final sub1 = stream1.listen((r) => lastResult1 = r);
        final sub2 = stream2.listen((r) => lastResult2 = r);
        await Future<void>.microtask(() {});

        final controller1 = watchableSource.watchListControllers.putIfAbsent(
          op1.cacheKey,
          StreamController.broadcast,
        );

        const item1 = TestModel(id: '1', msg: 'stream1 payload');
        controller1.add(
          ReadListResult.fromList(
                [item1],
                op1.details,
                const {},
                (i) => i.id,
              )
              as ReadListSuccess<TestModel>,
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(lastResult1, isNotNull);
        expect(
          (lastResult1 as ReadListSuccess<TestModel>?)!.items.first.msg,
          'stream1 payload',
        );

        // Egon would be proud
        expect(lastResult2, isNull, reason: 'Never cross the streams!');

        await sub1.cancel();
        await sub2.cancel();
      },
    );
  });

  group('SourceList.watchByIds should', () {
    late CountingWatchableSource watchableSource;
    late LocalMemorySource<TestModel> cacheSource;
    late SourceList<TestModel> sourceList;

    setUp(() {
      watchableSource = CountingWatchableSource();
      cacheSource = LocalMemorySource<TestModel>(bindings: TestModel.bindings);
      sourceList = SourceList<TestModel>(
        sources: [cacheSource, watchableSource],
        bindings: TestModel.bindings,
        getTime: () => DateTime.now().toUtc(),
      );
    });

    test('cache items and delete missing items', () async {
      // First, seed the cache with an item that will be "missing" remotely
      await cacheSource.setItem(
        gwo(const TestModel(id: 'missing-id', msg: 'A'), RequestDetails()),
      );

      final cacheCheck = await cacheSource.getById(
        gro('missing-id', RequestDetails()),
      );
      expect((cacheCheck as ReadSuccess).item, isNotNull);

      final op = gwbido({'missing-id', 'found-id'}, RequestDetails());
      final stream = sourceList.watchByIds(op);
      final sub = stream.listen((_) {});
      await Future<void>.microtask(() {});

      watchableSource.watchByIdsController.add(
        ReadListResult.fromList(
              const [TestModel(id: 'found-id', msg: 'B')],
              op.details,
              const {'missing-id'},
              (i) => i.id,
            )
            as ReadListSuccess<TestModel>,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final subsequentFound = await cacheSource.getById(
        gro('found-id', RequestDetails()),
      );
      expect((subsequentFound as ReadSuccess<TestModel>).item, isNotNull);
      expect(subsequentFound.item!.msg, 'B');

      final subsequentMissing = await cacheSource.getById(
        gro('missing-id', RequestDetails()),
      );
      expect((subsequentMissing as ReadSuccess<TestModel>).item, isNull);

      await sub.cancel();
    });

    test('NOT delete missing items if request is local', () async {
      final localWatchableSource = CountingWatchableSource(isRemote: false);
      sourceList = SourceList<TestModel>(
        sources: [cacheSource, localWatchableSource],
        bindings: TestModel.bindings,
        getTime: () => DateTime.now().toUtc(),
      );

      await cacheSource.setItem(
        gwo(const TestModel(id: 'missing-id', msg: 'A'), RequestDetails()),
      );

      final op = gwbido(
        {'missing-id'},
        RequestDetails(requestType: RequestType.local),
      );
      final stream = sourceList.watchByIds(op);
      final sub = stream.listen((_) {});
      await Future<void>.microtask(() {});

      localWatchableSource.watchByIdsController.add(
        ReadListResult<TestModel>.empty(
              op.details,
              missingItemIds: const {'missing-id'},
            )
            as ReadListSuccess<TestModel>,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final subsequentMissing = await cacheSource.getById(
        gro('missing-id', RequestDetails()),
      );
      // It shouldn't be deleted because the request was essentially 'local',
      // so we don't treat the missing items as authoritative deletions from
      // remote.
      expect((subsequentMissing as ReadSuccess<TestModel>).item, isNotNull);

      await sub.cancel();
    });

    test(
      'result in cache hits for subsequent SourceList.getByIds calls',
      () async {
        final watchOp = gwbido({'id1', 'id2'}, RequestDetails());
        final stream = sourceList.watchByIds(watchOp);
        final sub = stream.listen((_) {});
        await Future<void>.microtask(() {});

        const item1 = TestModel(id: 'id1', msg: 'StreamedById1');
        const item2 = TestModel(id: 'id2', msg: 'StreamedById2');
        watchableSource.watchByIdsController.add(
          ReadListResult.fromList(
                [item1, item2],
                watchOp.details,
                const {},
                (i) => i.id,
              )
              as ReadListSuccess<TestModel>,
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final getByIdsResult = await sourceList.getByIds(
          grido({'id1', 'id2'}, RequestDetails()),
        );
        expect(getByIdsResult, isA<ReadListSuccess<TestModel>>());
        final success = getByIdsResult as ReadListSuccess<TestModel>;
        expect(
          success.items.map((i) => i.msg),
          containsAll(['StreamedById1', 'StreamedById2']),
        );
        expect(success.missingItemIds, isEmpty);

        await sub.cancel();
      },
    );
  });

  group('SourceList structure should', () {
    test('throw when two WatchableSources are provided', () {
      expect(
        () {
          SourceList<TestModel>(
            sources: [
              LocalMemorySource<TestModel>(bindings: TestModel.bindings),
              CountingWatchableSource(),
              CountingWatchableSource(),
            ],
            bindings: TestModel.bindings,
            getTime: () => DateTime.now().toUtc(),
          );
        },
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
