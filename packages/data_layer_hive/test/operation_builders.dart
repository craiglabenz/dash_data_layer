import 'package:data_layer/data_layer.dart';

import 'src/models/test_model.dart';

DateTime Function() _now = () => DateTime.now().toUtc();

/// get ReadOperation
ReadOperation<TestModel> gro(String itemId, RequestDetails details) =>
    ReadOperation<TestModel>(
      operationId: 'abc',
      itemId: itemId,
      details: details,
      createdAt: _now(),
    );

/// get ReadListOperation
ReadListOperation<TestModel> grlo(RequestDetails details) =>
    ReadListOperation<TestModel>(
      operationId: 'abc',
      details: details,
      createdAt: _now(),
    );

/// get ReadByIdsOperation
ReadByIdsOperation<TestModel> grido(
  Set<String> itemIds,
  RequestDetails details,
) => ReadByIdsOperation<TestModel>(
  operationId: 'abc',
  itemIds: itemIds,
  details: details,
  createdAt: _now(),
);

/// get WriteOperation
WriteOperation<TestModel> gwo(TestModel item, RequestDetails details) =>
    WriteOperation<TestModel>(
      operationId: 'abc',
      item: item,
      details: details,
      createdAt: _now(),
    );

/// get WriteListOperation
WriteListOperation<TestModel> gwlo(
  Iterable<TestModel> items,
  RequestDetails details,
) => WriteListOperation<TestModel>(
  operationId: 'abc',
  items: items,
  details: details,
  createdAt: _now(),
);

/// get DeleteOperation
DeleteOperation<TestModel> gdo(String itemId, RequestDetails details) =>
    DeleteOperation<TestModel>(
      operationId: 'abc',
      itemId: itemId,
      details: details,
      createdAt: _now(),
    );
