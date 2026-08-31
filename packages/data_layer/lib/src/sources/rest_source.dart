import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// {@template RestSource}
/// Subtype of [Source] which knows how to make network requests to load data.
/// {@endtemplate}
class RestSource<T> extends Source<T> with MessageWriteMixin<T> {
  /// {@macro RestSource}
  RestSource({
    required RestApi restApi,
    required this.getListUrl,
    required this.getDetailUrl,
    ApiUrl Function()? getCreateUrl,
    this.logLevel = Level.OFF,
    this.resultsKey = 'results',
    super.bindings,
    ITimer? timer,
  }) : api = restApi,
       _getCreateUrl = getCreateUrl,
       idsCurrentlyBeingFetched = <String>{},
       loadedItems = {},
       timer = timer ?? RealTimer(),
       queuedIds = <String>{};

  final _log = Logger('RestSource<$T>');

  /// Builder for list [ApiUrl] instances for this data type.
  final ApiUrl Function() getListUrl;

  /// Builder for detail [ApiUrl] instances for this data type.
  final ApiUrl Function(String id) getDetailUrl;

  final ApiUrl Function()? _getCreateUrl;

  /// Overrideable method which returns the creation Url for this data type. By
  /// default, this proxies to [getListUrl].
  ApiUrl getCreateUrl() => _getCreateUrl?.call() ?? getListUrl();

  /// Utility able to send network requests.
  final RestApi api;

  /// Clock-aware object used to batch Ids.
  final ITimer timer;

  /// Ids set to be loaded during the next batch.
  Set<String> queuedIds;

  /// Set of Ids currently being loaded, but which have not yet been resolved.
  Set<String> idsCurrentlyBeingFetched;

  /// Id-keyed store of [Completer] instances which are individually resolved
  /// when a batch is returned from the server.
  final Map<String, Completer<T?>> loadedItems;

  /// If supplied, is used to extract the list of items from the response body
  /// of [fetchItems] if the payload is wrapped in a Map.
  ///
  /// For example, if your API returns this:
  /// {
  ///   "results": [...]
  /// }
  ///
  /// Then you would set `resultsKey` to `results` (which is the default).
  ///
  /// If your API returns the requested objects directly, set this to null. It
  /// is an error to set this to null AND have your API return a Map.
  ///
  /// See also:
  ///   * [extractItemsFromJsonResponse] where this is evaluated.
  final String? resultsKey;

  /// Controls the level of logging.
  final Level logLevel;

  @override
  SourceType get sourceType => SourceType.remote;

  @override
  Future<ReadResult<T>> getById(ReadOperation<T> operation) async {
    final id = operation.itemId;
    if (!loadedItems.containsKey(id) || !loadedItems[id]!.isCompleted) {
      _log.log(logLevel, 'Maybe queuing Id $id');
      queueId(id);
    }
    return ReadSuccess(
      await loadedItems[id]!.future,
      details: operation.details,
    );
  }

  @override
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation) async {
    final Params params = <String, String>{};

    // Add a specified filter as query parameters
    if (operation.details.filter != null) {
      params.addAll(operation.details.filter!.toParams());
    }

    // Add all specified pagination as query parameters
    if (operation.details.pagination != null) {
      params.addAll(operation.details.pagination!.toParams());
    }

    final result = await fetchItems(params);

    return switch (result) {
      ApiSuccess() => ReadListResult.fromList(
        hydrateListResponse(result),
        operation.details,
        {},
        bindings.getId,
      ),
      ApiError() => ReadListResult.fromApiError(result),
    };
  }

  @override
  Future<ReadListResult<T>> getByIds(
    ReadByIdsOperation<T> operation,
  ) async {
    assert(
      operation.details.filter == null,
      'Must not supply filters to `getByIds`',
    );

    if (operation.itemIds.isEmpty) {
      return ReadListResult<T>.fromList(
        [],
        operation.details,
        {},
        bindings.getId,
      );
    }
    final Params params = serializeIdsForQueryString(operation.itemIds);

    final result = await fetchItems(params);

    switch (result) {
      case ApiSuccess():
        final items = hydrateListResponse(result);
        final itemsById = <String, T>{};
        for (final item in items) {
          // Objects from the server must always have an Id set.
          itemsById[bindings.getId(item)!] = item;
        }

        final missingItemIds = <String>{};
        for (final id in operation.itemIds) {
          if (!itemsById.containsKey(id)) {
            missingItemIds.add(id);
          }
        }
        return ReadListResult<T>.fromMap(
          itemsById,
          operation.details,
          missingItemIds,
        );
      case ApiError():
        return ReadListResult.fromApiError(result);
    }
  }

  /// Converts a set of Ids into a query parameter. This is a common query
  /// parameter format for this type of filter, but it can be overridden if
  /// needed for a given API.
  Params serializeIdsForQueryString(Set<String> ids) {
    return <String, String>{
      'id__in': ids.join(','),
    };
  }

  /// Prepares an Id to be loaded in the next batch.
  void queueId(String id) {
    if (!queuedIds.contains(id) && !idsCurrentlyBeingFetched.contains(id)) {
      _log.log(logLevel, 'Id $id not yet queued - adding to queue now');
      loadedItems[id] = Completer<T?>();
      queuedIds.add(id);
      timer
        ..cancel()
        ..start(const Duration(milliseconds: 1), loadDeferredIds);
    }
  }

  /// Submits any Ids currently in the queue for loading.
  Future<void> loadDeferredIds() async {
    _log.log(logLevel, 'Starting to load deferred ids: $queuedIds');
    queuedIds.forEach(idsCurrentlyBeingFetched.add);
    final ids = Set<String>.from(queuedIds);
    queuedIds.clear();
    final byIds = await getByIds(
      ReadByIdsOperation<T>(
        operationId: 'loadDeferredIds',
        itemIds: ids,
        details: RequestDetails(),
        createdAt: DateTime.now(),
      ),
    );
    switch (byIds) {
      case ReadListFailure():
        for (final id in ids) {
          loadedItems[id]!.complete(null);
        }
      case ReadListSuccess():
        for (final id in byIds.missingItemIds) {
          loadedItems[id]!.complete(null);
        }
        for (final id in byIds.itemsMap.keys) {
          if (!loadedItems.containsKey(id)) {
            continue;
          }
          if (!loadedItems[id]!.isCompleted) {
            idsCurrentlyBeingFetched.remove(id);
            loadedItems[id]!.complete(byIds.itemsMap[id]!);
            loadedItems.remove(id);
          }
        }
    }
  }

  /// Submits a network request for data.
  Future<ApiResult> fetchItems(Params? params) async {
    final request = ReadApiRequest(
      url: getListUrl(),
      params: params,
    );
    return api.get(request);
  }

  @override
  Future<WriteResult<T>> setItem(WriteOperation<T> operation) async {
    final isInserting =
        bindings.getId(operation.item) == null || operation.details.forceInsert;
    final request = WriteApiRequest(
      url: isInserting
          ? getCreateUrl()
          : getDetailUrl(bindings.getId(operation.item)!),
      body: bindings.toJson(operation.item),
    );

    final result = await (isInserting
        ? api.post(request)
        : api.update(request) //
          );

    switch (result) {
      case ApiSuccess():
        final responseItem = hydrateItemResponse(result);

        final writtenItem = responseItem ?? operation.item;
        if (bindings.getId(writtenItem) == null) {
          _log.shout(
            'Did not get Id from written saved $T :: ${operation.item}',
          );
          return WriteFailure<T>(FailureReason.serverError, 'Failed to set Id');
        }
        return WriteSuccess<T>(writtenItem, details: operation.details);
      case ApiError():
        return WriteResult.fromApiError(result);
    }
  }

  @override
  Future<WriteListResult<T>> setItems(
    WriteListOperation<T> operation,
  ) =>
      // TODO(craiglabenz): Could this have a default implementation?
      throw Exception(
        'RestSource.setItems is undefined, as your desired behavior is too '
        'unpredictable to be offered by pkg:data_layer directly.',
      );

  @override
  Future<DeleteResult<T>> deleteItem(DeleteOperation<T> operation) async {
    final request = WriteApiRequest(
      url: getDetailUrl(operation.itemId),
      body: null,
    );
    final result = await api.deleteItem(request);
    return switch (result) {
      ApiSuccess() => DeleteSuccess(operation.details),
      ApiError() => DeleteResult.fromApiError(result),
    };
  }

  @override
  Future<DeleteResult<T>> deleteItems(DeleteListOperation<T> operation) async {
    final params = <String, Object?>{};
    if (operation.details.filter != null) {
      params.addAll(operation.details.filter!.toParams());
    }
    final request = WriteApiRequest(
      url: getListUrl(),
      body: null,
      params: params.isNotEmpty ? params : null,
    );
    final result = await api.deleteItem(request);
    return switch (result) {
      ApiSuccess() => DeleteSuccess(operation.details),
      ApiError() => DeleteResult.fromApiError(result),
    };
  }

  @override
  Future<WriteResult<T?>> sendMessage(
    SendMessageOperation<T> operation,
  ) async {
    if (operation.message is! MessagePayload) {
      return WriteFailure<T?>(
        FailureReason.badRequest,
        'Message must be wrapped in MessagePayload',
      );
    }
    final payload = operation.message as MessagePayload;
    final isInserting =
        operation.targetId == null || operation.details.forceInsert;

    final request = WriteApiRequest(
      url: isInserting ? getCreateUrl() : getDetailUrl(operation.targetId!),
      body: payload.toJson(),
    );

    final result = await (isInserting
        ? api.post(request)
        : api.update(request));

    switch (result) {
      case ApiSuccess():
        final responseItem = hydrateItemResponse(result);
        if (responseItem == null) {
          return WriteFailure<T?>(
            FailureReason.serverError,
            'Failed to parse sent message response',
          );
        }
        return WriteSuccess<T?>(responseItem, details: operation.details);
      case ApiError():
        return WriteResult<T?>.fromApiError(result);
    }
  }

  /// Overrideable hook to extract the raw item payloads out of the response
  /// body.
  List<Json> extractItemsFromJsonResponse(JsonApiResultBody body) {
    switch (body.data) {
      case Map():
        assert(
          resultsKey != null && resultsKey!.isNotEmpty,
          'Cannot extract values from Map without a resultsKey',
        );
        assert(
          resultsKey == null || (body.data as Map).containsKey(resultsKey),
          'Expected key $resultsKey not found in Map',
        );
        final results = (body.data as Map)[resultsKey!];
        switch (results) {
          case List():
            return results.cast<Json>();
          case Map():
            return <Json>[results as Json];
          default:
            throw Exception(
              'Unexpected data type: ${results.runtimeType} in list response',
            );
        }
      case List():
        return body.data as List<Json>;
      case _:
        throw Exception(
          'Unexpected data type: ${body.data.runtimeType} in list response',
        );
    }
  }

  /// Overrideable hook to extract the raw item payloads out of the response
  /// body.
  Json extractItemFromJsonResponse(JsonApiResultBody body) {
    switch (body.data) {
      case Map():
        return body.data as Json;
      case List():
        final dataList = body.data as List;
        if (dataList.length != 1) {
          _log.severe(
            'Unexpectedly received ${dataList.length} items in detail response',
          );
        }
        return dataList.first as Json;
      case _:
        throw Exception(
          'Unexpected data type: ${body.data.runtimeType} in detail response',
        );
    }
  }

  /// Deserializes the result of a network request into the actual object(s).
  T? hydrateItemResponse(ApiSuccess success) {
    switch (success.body) {
      case HtmlApiResultBody():
        _log.warning('Received HTML response from ${success.url}');
        return null;
      case JsonApiResultBody():
        final rawData = extractItemFromJsonResponse(
          success.body as JsonApiResultBody,
        );
        return bindings.fromJson(rawData);
      case PlainTextApiResultBody():
        _log.warning('Received plain text response from ${success.url}');
        return null;
    }
  }

  /// Deserializes the results of a network request into the actual object(s).
  List<T> hydrateListResponse(ApiSuccess success) {
    switch (success.body) {
      case HtmlApiResultBody():
        _log.warning('Received HTML response from ${success.url}');
        return <T>[];
      case JsonApiResultBody():
        final rawData = extractItemsFromJsonResponse(
          success.body as JsonApiResultBody,
        );
        return rawData.map<T>(bindings.fromJson).toList();
      case PlainTextApiResultBody():
        _log.warning('Received plain text response from ${success.url}');
        return <T>[];
    }
  }
}
