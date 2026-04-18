import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

import '../models/message_model.dart';

void main() {
  group(
    'MessageRepository',
    () {
      late LocalMemorySource<TestRecord> memorySource;
      late ProxySource<TestRecord> apiSource;
      late SourceList<TestRecord> sourceList;
      late MessageRepository<TestRecord, TestRecordMessage> repository;
      late Completer<TestRecord> apiUpdateCompleter;

      setUp(() {
        apiUpdateCompleter = Completer<TestRecord>();

        memorySource = LocalMemorySource<TestRecord>(
          bindings: TestRecord.bindings,
          now: () => DateTime(2025),
        );

        apiSource = ProxySource<TestRecord>(
          sourceType: SourceType.remote,
          bindings: TestRecord.bindings,
          createMessageHandler: (op) async {
            final payload = op.message as MessagePayload<TestRecordMessage>;
            return TestRecord(
              id: 'temp-id',
              value: payload.message.value ?? '',
              createdAt: DateTime(2025),
            );
          },
          updateMessageHandler: (op) async {
            return apiUpdateCompleter.future;
          },
        );

        sourceList = SourceList<TestRecord>(
          sources: [memorySource, apiSource],
          bindings: TestRecord.bindings,
          getTime: () => DateTime(2025),
        );

        repository = MessageRepository<TestRecord, TestRecordMessage>(
          sourceList,
          messageBindings: TestRecordMessage.bindings,
          getTime: () => DateTime(2025),
        );
      });

      test(
        'createMessage populates apiSource and caches in memorySource',
        () async {
          const msg = TestRecordMessage.create(value: 'Hello World');

          final created = await repository.createMessage(msg);

          expect(created, isNotNull);
          expect(created!.id, 'temp-id');
          expect(created.value, 'Hello World');

          // Verify local cache got populated correctly
          final cached = await memorySource.getById(
            ReadOperation<TestRecord>(
              operationId: '1',
              itemId: 'temp-id',
              details: RequestDetails.read(),
              createdAt: DateTime(2025),
            ),
          );

          expect(cached, isA<ReadSuccess<TestRecord>>());
          expect(
            (cached as ReadSuccess<TestRecord>).item!.value,
            'Hello World',
          );
        },
      );

      test(
        'updateMessage leaves memorySource alone while apiSource is pending',
        () async {
          // 1. Setup existing item directly in cache
          final existingRecord = TestRecord(
            id: '123',
            value: 'Old Value',
            createdAt: DateTime(2024),
          );
          await memorySource.setItem(
            WriteOperation<TestRecord>(
              operationId: 'initial',
              item: existingRecord,
              details: RequestDetails.write(),
              createdAt: DateTime(2025),
            ),
          );

          // Verify it's in memory
          final cachedBefore = await memorySource.getById(
            ReadOperation<TestRecord>(
              operationId: '1',
              itemId: '123',
              details: RequestDetails.read(),
              createdAt: DateTime(2025),
            ),
          );
          expect(
            (cachedBefore as ReadSuccess<TestRecord>).item!.value,
            'Old Value',
          );

          // 2. Send update message
          const msg = TestRecordMessage.update(value: 'New Value');

          // We don't await immediately, because we want to see if the cache
          // remains intact before the API responds
          final future = repository.updateMessage('123', msg);

          // Let the event loop execute memorySource.updateMessage before
          // pausing at the apiCompleter
          await Future<void>.delayed(Duration.zero);

          // 3. Very crucial: Memory source should retain the old value and take
          // no action.
          final cachedWhilstPending = await memorySource.getById(
            ReadOperation<TestRecord>(
              operationId: '2',
              itemId: '123',
              details: RequestDetails.read(),
              createdAt: DateTime(2025),
            ),
          );
          expect(cachedWhilstPending, isA<ReadSuccess<TestRecord>>());
          expect(
            (cachedWhilstPending as ReadSuccess<TestRecord>).item!.value,
            'Old Value',
          );

          // Now let the API complete with a different value so we can verify
          // the write-through back down to local sources
          apiUpdateCompleter.complete(
            TestRecord(
              id: '123',
              value: 'API Confirmed Value',
              createdAt: DateTime(2025),
            ),
          );

          final updated = await future;

          expect(updated, isNotNull);
          expect(updated!.id, '123');
          expect(updated.value, 'API Confirmed Value');

          // Final cache check ensures that local memory gets the final T from
          // the server
          final cachedFinal = await memorySource.getById(
            ReadOperation<TestRecord>(
              operationId: '3',
              itemId: '123',
              details: RequestDetails.read(),
              createdAt: DateTime(2025),
            ),
          );
          expect(
            (cachedFinal as ReadSuccess<TestRecord>).item!.value,
            'API Confirmed Value',
          );
        },
      );
    },
  );
}
