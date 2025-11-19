import 'package:data_layer/data_layer.dart'
    show Pagination, RequestDetails, RequestType;
import 'package:test/test.dart';

import '../models/test_model.dart';

void main() {
  final details = RequestDetails();
  final localDetails = RequestDetails(requestType: RequestType.local);
  final paginationDetails = RequestDetails(
    pagination: Pagination.page(1),
  );
  final page2Details = RequestDetails(
    pagination: Pagination.page(2),
  );
  final paginationDetailsWithFilter = RequestDetails(
    pagination: Pagination.page(1),
    filter: const MsgStartsWithFilter('abc'),
  );
  final page2DetailsWithFilter = RequestDetails(
    pagination: Pagination.page(2),
    filter: const MsgStartsWithFilter('abc'),
  );
  final localPaginationDetails = RequestDetails(
    requestType: RequestType.local,
    pagination: Pagination.page(1),
  );

  final localPaginationDetailsWithFilter = RequestDetails(
    requestType: RequestType.local,
    pagination: Pagination.page(1),
    filter: const MsgStartsWithFilter('abc'),
  );

  final localPage2Details = RequestDetails(
    requestType: RequestType.local,
    pagination: Pagination.page(2),
  );

  test('RequestTypes share cache keys despite different types', () {
    expect(details.cacheKey, equals(localDetails.cacheKey));
    expect(
      paginationDetailsWithFilter.cacheKey,
      equals(localPaginationDetailsWithFilter.cacheKey),
    );
    expect(
      paginationDetailsWithFilter.noPaginationCacheKey,
      equals(localPaginationDetailsWithFilter.noPaginationCacheKey),
    );
    expect(
      localPaginationDetails.cacheKey,
      equals(paginationDetails.cacheKey),
    );
    expect(
      localPaginationDetails.noPaginationCacheKey,
      equals(paginationDetails.noPaginationCacheKey),
    );
    expect(
      page2Details.noPaginationCacheKey,
      equals(localPage2Details.noPaginationCacheKey),
    );
    expect(
      page2Details.cacheKey,
      equals(localPage2Details.cacheKey),
    );
  });

  test(
    'RequestDetails and pagination RequestDetails share noPagiationCacheKey',
    () {
      expect(details.cacheKey, equals(paginationDetails.noPaginationCacheKey));
      expect(
        details.cacheKey,
        equals(localPaginationDetails.noPaginationCacheKey),
      );
    },
  );

  test('Details and paginated Details do not share cacheKeys', () {
    expect(details.cacheKey, isNot(equals(paginationDetails.cacheKey)));
    expect(details.cacheKey, isNot(equals(localPaginationDetails.cacheKey)));
  });

  test('Filters bust cacheKey matces', () {
    expect(
      details.cacheKey,
      isNot(equals(localPaginationDetailsWithFilter.noPaginationCacheKey)),
    );
    expect(
      details.cacheKey,
      isNot(equals(localPaginationDetailsWithFilter.cacheKey)),
    );
  });
  test('Paginated details have same noPaginationCacheKey but '
      'different cacheKeys', () {
    expect(
      paginationDetails.noPaginationCacheKey,
      equals(page2Details.noPaginationCacheKey),
    );
    expect(paginationDetails.cacheKey, isNot(equals(page2Details.cacheKey)));
  });
  test('Paginated details with same filters have same noPaginationCacheKey but '
      'different cacheKeys', () {
    expect(
      paginationDetailsWithFilter.noPaginationCacheKey,
      equals(page2DetailsWithFilter.noPaginationCacheKey),
    );
    expect(
      paginationDetailsWithFilter.cacheKey,
      isNot(equals(page2DetailsWithFilter.cacheKey)),
    );
  });
}
