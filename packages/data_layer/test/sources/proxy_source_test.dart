import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

void main() {
  group('ProxySource supportedOperations', () {
    test('reports only provided handlers in supportedOperations', () {
      final partialProxy = ProxySource<TestModel>(
        bindings: TestModel.bindings,
        sourceType: SourceType.remote,
        getByIdHandler: (op) async => TestModel(id: op.itemId, msg: 'Test'),
      );

      expect(
        partialProxy.supportedOperations,
        contains(SourceOperationType.getById),
      );
      expect(
        partialProxy.supportedOperations,
        isNot(contains(SourceOperationType.getItems)),
      );
      expect(
        partialProxy.supportedOperations,
        isNot(contains(SourceOperationType.setItem)),
      );
      expect(
        partialProxy.supportedOperations,
        isNot(contains(SourceOperationType.delete)),
      );
      expect(
        partialProxy.supportedOperations,
        isNot(contains(SourceOperationType.deleteItems)),
      );
      expect(
        partialProxy.supportedOperations,
        isNot(contains(SourceOperationType.sendMessage)),
      );

      expect(partialProxy.supports(SourceOperationType.getById), isTrue);
      expect(partialProxy.supports(SourceOperationType.setItem), isFalse);
      expect(partialProxy.supports(SourceOperationType.deleteItems), isFalse);
    });

    test('includes deleteItems when deleteItemsHandler is provided', () async {
      var called = false;
      final proxy = ProxySource<TestModel>(
        bindings: TestModel.bindings,
        sourceType: SourceType.remote,
        deleteItemsHandler: (op) async {
          called = true;
          return DeleteSuccess<TestModel>(op.details);
        },
      );

      expect(
        proxy.supportedOperations,
        contains(SourceOperationType.deleteItems),
      );
      expect(proxy.supports(SourceOperationType.deleteItems), isTrue);

      final details = RequestDetails.write();
      final result = await proxy.deleteItems(
        DeleteListOperation<TestModel>(
          operationId: 'del1',
          details: details,
          createdAt: DateTime.now(),
        ),
      );
      expect(result, isSuccess);
      expect(called, isTrue);
    });

    test(
      'includes sendMessage in supportedOperations when sendMessageHandler '
      'is provided',
      () {
        final messageProxy = ProxySource<TestModel>(
          bindings: TestModel.bindings,
          sourceType: SourceType.remote,
          sendMessageHandler: (op) async =>
              const TestModel(id: '1', msg: 'Msg'),
        );

        expect(
          messageProxy.supportedOperations,
          contains(SourceOperationType.sendMessage),
        );
        expect(messageProxy.supports(SourceOperationType.sendMessage), isTrue);
      },
    );
  });

  group('SourceList with partial ProxySource', () {
    test(
      'skips unsupported operations without throwing UnimplementedError',
      () async {
        // Partial source that only handles getById
        final partialSource = ProxySource<TestModel>(
          bindings: TestModel.bindings,
          sourceType: SourceType.remote,
          getByIdHandler: (op) async =>
              TestModel(id: op.itemId, msg: 'FromProxy'),
        );

        final sourceList = SourceList<TestModel>(
          sources: [partialSource],
          bindings: TestModel.bindings,
          getTime: DateTime.now,
        );

        // setItem is unsupported by partialSource, so SourceList skips it
        // and succeeds safely
        final setItemResult = await sourceList.setItem(
          WriteOperation<TestModel>(
            operationId: '1',
            item: const TestModel(id: '123', msg: 'Item'),
            details: RequestDetails.write(),
            createdAt: DateTime.now(),
          ),
        );
        expect(setItemResult, isA<WriteSuccess<TestModel>>());

        // getById IS supported by partialSource
        final getResult = await sourceList.getById(
          ReadOperation<TestModel>(
            operationId: '2',
            itemId: '123',
            details: RequestDetails.read(),
            createdAt: DateTime.now(),
          ),
        );
        expect(getResult, isA<ReadSuccess<TestModel>>());
        expect((getResult as ReadSuccess<TestModel>).item?.msg, 'FromProxy');
      },
    );

    test('Operation.type matches operation type', () {
      final readOp = ReadOperation<TestModel>(
        operationId: '1',
        itemId: 'abc',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );
      expect(readOp.type, SourceOperationType.getById);

      final writeOp = WriteOperation<TestModel>(
        operationId: '2',
        item: const TestModel(id: '1', msg: 'Test'),
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );
      expect(writeOp.type, SourceOperationType.setItem);
    });
  });
}
