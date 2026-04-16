import 'package:crypt/crypt.dart';
import 'package:data_layer/data_layer.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart' show JsonConverter;

/// The product of [RequestDetails.cacheKey].
typedef CacheKey = String;

/// {@template RequestDetails}
/// Meta-information a [Source] will use to return the desired data.
///
/// [RequestDetails] instances are extremely central to pkg:data_layer, as local
/// sources use their unique [cacheKey] value to decide whether they have
/// relevant information for a given request.
///
/// Note that the following code represents implementation details for sources
/// and is hidden from end developers by the simpler API found on the
/// [Repository] class. But, it is still demonstrative.
///
/// ```dart
/// final localSource = LocalMemorySource<T>();
/// 
/// await localSource.setItems(
///   WriteListOperation<T>(
///     items: [MyClass('a'), MyClass('b')],
///     details: RequestDetails.write(
///       filter: ActiveItemsFilter(),
///     ),
///   ),
/// );
/// 
/// final items = await localSource.getItems(
///   ReadByIdsOperation<T>(
///     operationId: Uuid.v7(),
///     details: RequestDetails.read(
///       filter: ActiveItemsFilter(),
///     ),
///   ),
/// );
///
/// // `items` will contain both 'a' and 'b' because the two RequestDetails
/// // instances will produce matching cacheKeys.
/// // `items = [MyClass('a'), MyClass('b')]`
///
/// final someMoreItems = localSource.getItems(
///   ReadByIdsOperation<T>(
///     operationId: Uuid.v7(),
///     details: RequestDetails(),
///   ),
/// );
/// 
/// // Unless other operations have also taken place, `someMoreItems` will be
/// // an empty list, because the `LocalSource` has never received a write
/// // operation with a `RequestDetails` which produced the same `cacheKey` as
/// // that which is produced by the empty `RequestDetails()` instance.
/// ```
/// {@endtemplate}
class RequestDetails extends Equatable {
  /// {@macro RequestDetails}
  RequestDetails({
    this.filter,
    this.forceInsert = false,
    this.requestType = defaultRequestType,
    this.pagination,
    this.shouldRetry = true,
    this.ttl,
  });

  /// Read-friendly constructor for [RequestDetails].
  factory RequestDetails.read({
    RequestType requestType = defaultRequestType,
    Filter? filter,
    Pagination? pagination,
    bool shouldRetry = true,
  }) => RequestDetails(
    requestType: requestType,
    filter: filter,
    pagination: pagination,
    shouldRetry: shouldRetry,
  );

  /// Write-friendly constructor for [RequestDetails]. Write [RequestDetails]
  /// surprisingly contain pagination details for the purposes of write-through
  /// caches.
  ///
  /// To set caches to auto-expire, supply a non-null value for [ttl],
  /// which will cause [LocalSource] objects to stop returning this data after
  /// that amount of time. This is a write-time-only operation; reads cannot
  /// determine their desired TTL. If you suspect that a read has sensitive
  /// enough needs to tighten its acceptable TTL, consider using
  /// `RequestType.refresh` instead to fetch the latest data from the server.
  factory RequestDetails.write({
    RequestType requestType = defaultRequestType,
    bool shouldRetry = true,
    bool forceInsert = false,
    Pagination? pagination,
    Duration? ttl,
  }) => RequestDetails(
    forceInsert: forceInsert,
    requestType: requestType,
    pagination: pagination,
    shouldRetry: shouldRetry,
    ttl: ttl,
  );

  /// Serializes this request information to send to the server.
  factory RequestDetails.fromJson(Json data) => RequestDetails(
    filter: data['filter'] != null
        ? Filter.fromJson(data['filter']! as Json)
        : null,
    forceInsert: data['forceInsert'] as bool? ?? false,
    pagination: data['pagination'] != null
        ? Pagination.fromJson(data['pagination']! as Json)
        : null,
    requestType: RequestType.values.byName(
      (data['requestType'] ?? RequestType.global.name) as String,
    ),
    shouldRetry: data['shouldRetry'] as bool? ?? true,
    ttl: data['ttl'] != null
        ? Duration(microseconds: data['ttl']! as int)
        : null,
  );

  /// Serializes this request information to send to the server.
  Json toJson() => <String, Object?>{
    'forceInsert': forceInsert,
    'filter': filter?.toJson(),
    'pagination': pagination?.toJson(),
    'requestType': requestType.name,
    'shouldRetry': shouldRetry,
    'ttl': ttl?.inMicroseconds,
  };

  /// Tells sources, especially remote sources, to insert this data even though
  /// it may already have an Id. This can be paired with [CreationBindings]
  /// which assign Ids on the client.
  final bool forceInsert;

  /// True if this request should be retried according to a [RetryPolicy]. Note
  /// that this does not guarantee retries; it merely means the [Operation] is
  /// opted-in to the chance at a retry, according to policy.
  ///
  /// This field is not ever sent to the server, as it is a local detail. It is
  /// also not used in the cache key, as it is operational and not a property
  /// of the data being requested.
  final bool shouldRetry;

  /// {@macro RequestType}
  final RequestType requestType;

  /// Optional [Filter] for this request.
  final Filter? filter;

  /// Pagination details for this data request.
  final Pagination? pagination;

  /// Default [Pagination] details.
  static const defaultPagination = Pagination._(
    page: 1,
    pageSize: Pagination.defaultPageSize,
    cursor: null,
  );

  /// Default [RequestType].
  static const RequestType defaultRequestType = RequestType.global;

  @override
  List<Object?> get props => [
    forceInsert,
    requestType,
    filter?.hashCode,
    pagination,
    shouldRetry,
    ttl,
  ];

  /// Duration after which cached data should be considered stale. Supplying a
  /// non-null value to this can force cache misses from local sources which
  /// contain data that is older than this duration.
  final Duration? ttl;

  /// Cache-key without any pagination, used to group up paginated requests
  /// together in a [LocalSource]'s cache.
  late final CacheKey noPaginationCacheKey = _getNoPaginationCacheKey();

  /// Collapses this request into a key suitable for local memory caching.
  /// This key should incorporate everything about this request EXCEPT the
  /// requestType, as that would create false-positive variance.
  late final CacheKey cacheKey = _getCacheKey();

  CacheKey _getCacheKey() =>
      Crypt.sha256(getCacheKeyInputs(), rounds: 1, salt: '').hash;

  /// Used to assemble all the inputs to this object's full cache key.
  String getCacheKeyInputs() => <String>[
    filter?.cacheKey ?? '-cache-',
    pagination?.cacheKey ?? '-page-',
  ].join('-');

  CacheKey _getNoPaginationCacheKey() =>
      Crypt.sha256(getNoPaginationCacheKeyInputs(), rounds: 1, salt: '').hash;

  /// Used to assemble all the inputs to this object's no-pagination cache key.
  String getNoPaginationCacheKeyInputs() => [
    filter?.cacheKey ?? '-cache-',
    '-page-', // to represent `null` pagination
  ].join('-');

  /// True if [filter] AND [pagination] are empty.
  bool get isEmpty => filter == null && pagination == null;

  /// True if [filter] OR [pagination] are not empty.
  bool get isNotEmpty => !isEmpty;

  /// Copy of this RequestDetails without any filters, pagination, or other
  /// do-dads which would segment up a data set. This is used for saving the
  /// global list alongside any sliced / filtered lists.
  RequestDetails get empty => RequestDetails(requestType: requestType);

  /// Equivalent [RequestDetails] but for the removal of a global or refresh
  /// [RequestType].
  RequestDetails localCopy() => RequestDetails(
    forceInsert: forceInsert,
    requestType: .local,
    pagination: pagination,
    filter: filter,
    ttl: ttl,
  );

  @override
  String toString() =>
      'RequestDetails(requestType: $requestType, forceInsert: $forceInsert, '
      'filter: $filter, pagination: $pagination, ttl: $ttl)';

  /// Asserts that this instane [isEmpty]. The lone string parameter is useful
  /// for easily seeing where this assertion was called.
  void assertEmpty(String functionName) {
    assert(isEmpty, 'Must not supply filters or pagination to $functionName');
  }

  /// True if this request would rather return empty data than go off-device.
  bool get isLocal => switch (requestType) {
    RequestType.local => true,
    RequestType.allLocal => true,
    RequestType.refresh => false,
    RequestType.global => false,
  };

  /// True if this request will attempt to go off-device.
  bool get isRemote => !isLocal;
}

/// {@template Pagination}
/// Page index and size information for a read request, or a write request if
/// we are caching loaded data to a local [Source].
/// {@endtemplate}
class Pagination extends Equatable {
  /// {@macro Pagination}
  const Pagination._({
    required this.pageSize,
    required this.page,
    required this.cursor,
  });

  /// Page-style pagination.
  ///
  /// {@macro Pagination}
  factory Pagination.page(int page, {int pageSize = defaultPageSize}) =>
      Pagination._(pageSize: pageSize, page: page, cursor: null);

  /// Cursor-style pagination.
  ///
  /// {@macro Pagination}
  factory Pagination.cursor(
    String cursor, {
    int pageSize = defaultPageSize,
  }) => Pagination._(pageSize: pageSize, page: null, cursor: cursor);

  /// Deserializes a [Pagination] object.
  factory Pagination.fromJson(Json data) => Pagination._(
    page: data['page'] as int?,
    pageSize: data['pageSize'] as int?,
    cursor: data['cursor']! as String?,
  );

  /// Maximum number of records this data request should contain.
  final int? pageSize;

  /// Page number of this request. Returned data is assumed to skip
  /// "(page - 1) * pageSize" earlier records.
  final int? page;

  /// Cursor-style pagination token. This should indicate the last item of all
  /// loaded data.
  final String? cursor;

  /// Default number of records to include in a page.
  static const defaultPageSize = 20;

  @override
  List<Object?> get props => [pageSize, page];

  /// Variant of [hashCode] with persistent Ids across application launches.
  CacheKey get cacheKey =>
      '$pageSize-${page ?? "nopage"}-${cursor ?? "nocursor"}';

  @override
  String toString() =>
      'Pagination(pageSize: $pageSize, page: $page, cursor: $cursor)';

  /// Serializes this pagination.
  Json toJson() => <String, Object?>{
    'page': page,
    'pageSize': pageSize,
    'cursor': cursor,
  };

  /// Serializes this pagination for use in a request.
  Params toParams() => (toJson()..removeWhere((key, value) => value == null))
      .cast<String, String>();
}

/// {@template RequestDetailsConverter}
/// Converter for [RequestDetails] to be used in freezed classes.
/// {@endtemplate}
class RequestDetailsConverter extends JsonConverter<RequestDetails, Json> {
  /// {@macro RequestDetailsConverter}
  const RequestDetailsConverter();

  @override
  RequestDetails fromJson(Json json) => RequestDetails.fromJson(json);

  @override
  Json toJson(RequestDetails object) => object.toJson();
}
