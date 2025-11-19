import 'package:crypt/crypt.dart';
import 'package:data_layer/data_layer.dart';
import 'package:equatable/equatable.dart';

/// The product of [RequestDetails.cacheKey].
typedef CacheKey = String;

/// {@template RequestDetails}
/// Container for meta-information a [Source] will use to return the desired
/// data.
/// {@endtemplate}
class RequestDetails extends Equatable {
  /// {@macro RequestDetails}
  RequestDetails({
    this.filter,
    this.requestType = defaultRequestType,
    this.pagination,
    this.shouldOverwrite = defaultShouldOverwrite,
  });

  /// Read-friendly constructor for [RequestDetails].
  factory RequestDetails.read({
    RequestType requestType = defaultRequestType,
    Filter? filter,
    Pagination? pagination,
  }) => RequestDetails(
    requestType: requestType,
    filter: filter,
    pagination: pagination,
  );

  /// Write-friendly constructor for [RequestDetails]. Write [RequestDetails]
  /// surprisingly contain pagination details for the purposes of write-through
  /// caches.
  factory RequestDetails.write({
    RequestType requestType = defaultRequestType,
    bool shouldOverwrite = defaultShouldOverwrite,
    Pagination? pagination,
  }) => RequestDetails(
    requestType: requestType,
    shouldOverwrite: shouldOverwrite,
    pagination: pagination,
  );

  /// Serializes this request information to send to the server.
  factory RequestDetails.fromJson(Json data) => RequestDetails(
    filter: data['filter'] != null
        ? Filter.fromJson(data['filter']! as Json)
        : null,
    shouldOverwrite: data['shouldOverwrite']! as bool,
    pagination: Pagination.fromJson(data['pagination']! as Json),
    requestType: RequestType.values.byName(data['requestType']! as String),
  );

  /// Serializes this request information to send to the server.
  Json toJson() => <String, Object?>{
    'filter': filter?.toJson(),
    'requestType': requestType.name,
    'shouldOverwrite': shouldOverwrite,
    'pagination': pagination?.toJson(),
  };

  /// {@macro RequestType}
  final RequestType requestType;

  /// Optional [Filter] for this request.
  final Filter? filter;

  /// Whether this request should overwrite existing data.
  final bool shouldOverwrite;

  /// Pagination details for this data request.
  final Pagination? pagination;

  /// Default [Pagination] details.
  final defaultPagination = Pagination.page(1);

  /// Default [RequestType].
  static const RequestType defaultRequestType = RequestType.global;

  /// Default value for [shouldOverwrite].
  static const defaultShouldOverwrite = true;

  @override
  List<Object?> get props => [
    requestType,
    shouldOverwrite,
    filter?.hashCode,
    pagination,
  ];

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
    requestType: RequestType.local,
    pagination: pagination,
    filter: filter,
    shouldOverwrite: shouldOverwrite,
  );

  @override
  String toString() =>
      'RequestDetails(requestType: $requestType, filter: '
      '$filter, pagination: $pagination)';

  /// Asserts that this instane [isEmpty]. The lone string parameter is useful
  /// for easily seeing where this assertion was called.
  void assertEmpty(String functionName) {
    assert(isEmpty, 'Must not supply filters or pagination to $functionName');
  }

  /// True if this request would rather return empty data than go off-device.
  bool get isLocal => switch (requestType) {
    RequestType.local => true,
    RequestType.refresh => false,
    RequestType.global => false,
  };
}

/// {@template Pagination}
/// Page index and size information for a read request, or a write request if
/// we are caching loaded data to a local [Source].
/// {@endtemplate}
class Pagination extends Equatable {
  /// {@macro Pagination}
  const Pagination({required this.pageSize, required this.page});

  /// Convenience constructor.
  ///
  /// {@macro Pagination}
  factory Pagination.page(int page, {int pageSize = defaultPageSize}) =>
      Pagination(pageSize: pageSize, page: page);

  /// Deserializes a [Pagination] object.
  factory Pagination.fromJson(Json data) => Pagination(
    page: data['page']! as int,
    pageSize: data['pageSize']! as int,
  );

  /// Maximum number of records this data request should contain.
  final int pageSize;

  /// Page number of this request. Returned data is assumed to skip
  /// "(page - 1) * pageSize" earlier records.
  final int page;

  /// Default number of records to include in a page.
  static const defaultPageSize = 20;

  @override
  List<Object?> get props => [pageSize, page];

  /// Variant of [hashCode] with persistent Ids across application launches.
  CacheKey get cacheKey => '$pageSize-$page';

  @override
  String toString() => 'Pagination(pageSize: $pageSize, page: $page)';

  /// Serializes this pagination.
  Json toJson() => <String, Object?>{
    'page': page,
    'pageSize': pageSize,
  };

  /// Serializes this pagination for use in a request.
  Params toParams() => toJson().cast<String, String>();
}
