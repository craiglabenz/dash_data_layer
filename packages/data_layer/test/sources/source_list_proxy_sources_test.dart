import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';
import 'operation_builders.dart';

void main() {
  group('SourceList with partial and incomplete ProxySources', () {
    late ProxySource<TestModel> readOnlySource;
    late ProxySource<TestModel> writeOnlySource;
    late ProxySource<TestModel> partialSource;
    late ProxySource<TestModel> emptySource;

    bool readOnlyGetByIdCalled = false;
    bool readOnlyGetItemsCalled = false;
    bool writeOnlySetItemCalled = false;
    bool writeOnlySetItemsCalled = false;
    bool writeOnlyDeleteCalled = false;
    bool writeOnlySendMessageCalled = false;
    bool partialGetByIdCalled = false;
    bool partialSetItemCalled = false;

    setUp(() {
      readOnlyGetByIdCalled = false;
      readOnlyGetItemsCalled = false;
      writeOnlySetItemCalled = false;
      writeOnlySetItemsCalled = false;
      writeOnlyDeleteCalled = false;
      writeOnlySendMessageCalled = false;
      partialGetByIdCalled = false;
      partialSetItemCalled = false;

      // 1. Read-only ProxySource (only implements getById, getItems, getByIds)
      readOnlySource = ProxySource<TestModel>(
        bindings: TestModel.bindings,
        sourceType: SourceType.remote,
        getByIdHandler: (op) async {
          readOnlyGetByIdCalled = true;
          return TestModel(id: op.itemId, msg: 'read_only_val');
        },
        getItemsHandler: (op) async {
          readOnlyGetItemsCalled = true;
          return [const TestModel(id: 'r1', msg: 'read_only_list')];
        },
        getByIdsHandler: (op) async {
          return [const TestModel(id: 'r1', msg: 'read_only_ids')];
        },
      );

      // 2. Write-only ProxySource (only implements setItem, setItems, delete,
      // sendMessage)
      writeOnlySource = ProxySource<TestModel>(
        bindings: TestModel.bindings,
        sourceType: SourceType.remote,
        setItemHandler: (op) async {
          writeOnlySetItemCalled = true;
          return op.item;
        },
        setItemsHandler: (op) async {
          writeOnlySetItemsCalled = true;
          return op.items.toList();
        },
        deleteHandler: (op) async {
          writeOnlyDeleteCalled = true;
          return DeleteSuccess<TestModel>(op.details);
        },
        sendMessageHandler: (op) async {
          writeOnlySendMessageCalled = true;
          return const TestModel(id: 'msg-id', msg: 'sent_msg');
        },
      );

      // 3. Partial ProxySource (only implements getById and setItem)
      partialSource = ProxySource<TestModel>(
        bindings: TestModel.bindings,
        sourceType: SourceType.remote,
        getByIdHandler: (op) async {
          partialGetByIdCalled = true;
          return TestModel(id: op.itemId, msg: 'partial_val');
        },
        setItemHandler: (op) async {
          partialSetItemCalled = true;
          return op.item;
        },
      );

      // 4. Completely Empty ProxySource (implements nothing)
      emptySource = ProxySource<TestModel>(
        bindings: TestModel.bindings,
        sourceType: SourceType.remote,
      );
    });

    test(
      'completes all CRUD and message operations without throwing '
      'UnimplementedError',
      () async {
        final sourceList = SourceList<TestModel>(
          sources: [
            readOnlySource,
            writeOnlySource,
            partialSource,
            emptySource,
          ],
          bindings: TestModel.bindings,
          getTime: DateTime.now,
        );

        final details = RequestDetails();

        // --- 1. getById ---
        final getResult = await sourceList.getById(gro('123', details));
        expect(getResult, isA<ReadSuccess<TestModel>>());
        expect(
          (getResult as ReadSuccess<TestModel>).item?.msg,
          'read_only_val',
        );
        expect(readOnlyGetByIdCalled, isTrue);
        expect(partialGetByIdCalled, isFalse); // First matching source returned

        // --- 2. getItems ---
        final getItemsResult = await sourceList.getItems(grlo(details));
        expect(getItemsResult, isA<ReadListSuccess<TestModel>>());
        expect(readOnlyGetItemsCalled, isTrue);

        // --- 3. getByIds ---
        final getByIdsResult = await sourceList.getByIds(
          grido({'r1'}, details),
        );
        expect(getByIdsResult, isA<ReadListSuccess<TestModel>>());

        // --- 4. setItem ---
        final setItemResult = await sourceList.setItem(
          gwo(const TestModel(id: '123', msg: 'Saved'), details),
        );
        expect(setItemResult, isA<WriteSuccess<TestModel>>());
        expect(writeOnlySetItemCalled, isTrue);
        expect(partialSetItemCalled, isTrue);

        // --- 5. setItems ---
        final setItemsResult = await sourceList.setItems(
          gwlo([const TestModel(id: '123', msg: 'SavedList')], details),
        );
        expect(setItemsResult, isA<WriteListSuccess<TestModel>>());
        expect(writeOnlySetItemsCalled, isTrue);

        // --- 6. delete ---
        final deleteResult = await sourceList.delete(gdo('123', details));
        expect(deleteResult, isA<DeleteSuccess<TestModel>>());
        expect(writeOnlyDeleteCalled, isTrue);

        // --- 7. sendMessage ---
        final sendMsgResult = await sourceList.sendMessage(
          SendMessageOperation<TestModel>(
            operationId: 'op_msg',
            message: 'hello',
            details: details,
            createdAt: DateTime.now(),
          ),
        );
        expect(sendMsgResult, isA<WriteSuccess<TestModel?>>());
        expect(writeOnlySendMessageCalled, isTrue);
      },
    );

    test(
      'SourceList with only read-only source gracefully skips write operations',
      () async {
        final sourceList = SourceList<TestModel>(
          sources: [readOnlySource],
          bindings: TestModel.bindings,
          getTime: DateTime.now,
        );

        final details = RequestDetails();

        // Write operations return success (skipped by empty/unsupported sources)
        final setItemResult = await sourceList.setItem(
          gwo(const TestModel(id: '1', msg: 'test'), details),
        );
        expect(setItemResult, isA<WriteSuccess<TestModel>>());

        final deleteResult = await sourceList.delete(gdo('1', details));
        expect(deleteResult, isA<DeleteSuccess<TestModel>>());

        // Read operations succeed
        final getResult = await sourceList.getById(gro('1', details));
        expect(getResult, isA<ReadSuccess<TestModel>>());
        expect(
          (getResult as ReadSuccess<TestModel>).item?.msg,
          'read_only_val',
        );
      },
    );

    test(
      'SourceList with only write-only source gracefully handles '
      'read operations',
      () async {
        final sourceList = SourceList<TestModel>(
          sources: [writeOnlySource],
          bindings: TestModel.bindings,
          getTime: DateTime.now,
        );

        final details = RequestDetails();

        // Read operations safely return empty/null results because no
        // source supported read
        final getResult = await sourceList.getById(gro('1', details));
        expect(getResult, isA<ReadSuccess<TestModel>>());
        expect((getResult as ReadSuccess<TestModel>).item, isNull);

        final getItemsResult = await sourceList.getItems(grlo(details));
        expect(getItemsResult, isA<ReadListSuccess<TestModel>>());
        expect((getItemsResult as ReadListSuccess<TestModel>).items, isEmpty);

        // Write operations succeed
        final setItemResult = await sourceList.setItem(
          gwo(const TestModel(id: '1', msg: 'test'), details),
        );
        expect(setItemResult, isA<WriteSuccess<TestModel>>());
        expect(writeOnlySetItemCalled, isTrue);
      },
    );

    test(
      'SourceList with only empty source gracefully handles all operations',
      () async {
        final sourceList = SourceList<TestModel>(
          sources: [emptySource],
          bindings: TestModel.bindings,
          getTime: DateTime.now,
        );

        final details = RequestDetails();

        final getResult = await sourceList.getById(gro('1', details));
        expect(getResult, isA<ReadSuccess<TestModel>>());
        expect((getResult as ReadSuccess<TestModel>).item, isNull);

        final setItemResult = await sourceList.setItem(
          gwo(const TestModel(id: '1', msg: 'test'), details),
        );
        expect(setItemResult, isA<WriteSuccess<TestModel>>());
      },
    );
  });
}
