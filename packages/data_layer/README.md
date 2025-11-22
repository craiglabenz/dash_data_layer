[![pub package](https://img.shields.io/pub/v/data_layer.svg)](https://pub.dartlang.org/packages/data_layer)

# Data Layer

Pure Dart package for isolating data layer abstractions from the rest of your app.

# Motivation

Correctly managing data is one of the most important parts of any app. Always loading data from the server every time you need it is easy, but not performant or offline-friendly. That suggests caching data; but as cache invalidation is one of the 3 hard problems in computer science, *there be dragons*.

`pkg:data_layer` aims to provide a simple, yet powerful, way to manage data in your app.

# Architecture

Everything in `pkg:data_layer` resolves around satisfying the `DataContract` interface. This interface has 6 primary methods:

* `getById` - Retrieves a single item by its Id. Does not support filters or pagination.
* `getByIds` - Retrieves a list of items by their Ids. Does not support filters or pagination.
* `getItems` - Retrieves a list of items, optionally filtered or paginated.
* `setItem` - Persists a single item.
* `setItems` - Persists a list of items.
* `deleteItem` - Deletes a single item.

The primary class the rest of your app will encounter is the `Repository`, which typically defines handlers for all of the above methods, but may decide to define only a subset if appropriate for a given use case.

Within a `Repository` is the all-important `SourceList`, which manages juggling data between an arbitrary list of `Source` objects. The `SourceList` class is the core of `pkg:data_layer`. You should not need to subclass or alter its behavior, as any special behavior should be coded into the `Repository` or `Source` layers.

Understanding the `SourceList` is key to understanding `pkg:data_layer`. See the [detailed description of the `SourceList`](#understanding-the-sourcelist) below.

`Source` objects are the primary means of loading and persisting data. `Source` objects can either be `.local` or `.remote`, which designates whether the data is loaded from a local cache or a remote server, respectively.

# Index

- [Motivation](#motivation)
- [Architecture](#architecture)
- [Features](#features)
- [Getting started](#getting-started)
- [Creating a Repository](#creating-a-repository)
- [Instantiating a Repository](#instantiating-a-repository)
- [Understanding the SourceList](#understanding-the-sourcelist)
- [Defining data bindings](#defining-data-bindings)
- [Loading data](#loading-data)
- [Filtering data](#filtering-data)
- [Pagination](#pagination)
- [Managing cached data](#managing-cached-data)
- [Creating a Local Source](#creating-a-local-source)
- [Extending a Local Source](#extending-a-local-source)
- [Creating a Remote Source](#creating-a-remote-source)
- [Extending a Remote Source](#extending-a-remote-source)


## Features

- Powerful data repositories which handle data fetching, caching, and invalidation.
- Local memory data sources for fast access to previously loaded data
- API data sources for loading data from a REST server
- Canonical REST client to power those API data sources
- Write-thru caching of loaded data
- Deterministic invalidation of cached data
- Extensibility to work with any data source, including Hive, SQLite, ServerPod, etc.

## Getting started

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  data_layer: ^0.0.1-beta.4
```

## Creating a Repository

The `Repository` class is the primary entry point for your application to access data. It is designed to be subclassed for each data type in your application.

```dart
class UserRepository extends Repository<User> {
  UserRepository(SourceList<User> sourceList) : super(sourceList);
}
```

The `Repository` base class provides default implementations for `getById`, `getByIds`, `getItems`, `setItem`, `setItems`, and `delete`. You can override these methods to add domain-specific logic, but often the default implementation which immediately delegates to its `SourceList` is sufficient.

## Instantiating a Repository

Instantiating a `Repository` usually amounts to instantiating a `SourceList` object. Most objects need to be passed the data type in question's `Bindings` definition.

```dart
final userRepository = UserRepository(
  SourceList<User>(
    bindings: userBindings,
    sources: [
      LocalSource<User>(bindings: userBindings),
      ApiSource<User>(
        bindings: userBindings,
        restClient: restClient,
      ),
    ],
  ),
);
```

You should always put more local, more immediate sources first, as they will be read first.

## Understanding the SourceList

The `SourceList` class is a request-based read-thru cache whose behavior is best explained by example.

Consider an empty `SourceList` with a single `LocalSource` and a single `ApiSource`. Your first action may be to read data, like so:

```dart
final users = await userRepository.getItems();
```

First, the `SourceList` will attempt to read data from its local sources. If no data is found, it will then attempt to read data from its remote sources. If data is found in a remote `Source`, it will be written to the local `Source`.

Critically, this cached data is tied to the exact request that made yielded it. If you make a different request like below, the local `Source` will not have a cache hit and the `SourceList` will once again continue on to its remote `Source`.

```dart
/// Not a cache hit - will once again request data from the server
final activeUsers = await userRepository.getItems(
  RequestDetails(filter: ActiveUsersFilter(), pagination: Pagination.page(1)),
);
```

At this point, repeating either of the previous function calls will yield cache hits from the local `Source`.

Next, you may want to write data, like so:

```dart
final savedUser = await userRepository.setItem(User(name: 'John Doe'));
```

The `SourceList` will detect a missing `id` value and will immediately write this value to the server for `id` generation. At which point, the returned value will be saved to the local `Source` and returned to the caller. Assuming the server generated an `id` of `abc`, the following call would yield a cache hit and not request the data from the server:

```dart
final johnDoe = await userRepository.getById('abc');
```

However, local sources are request-based and cannot know which requests would yield this new John Doe user. As such, right now the only way to read that user from the local `Source` is to either request it by its Id like above, or to load all locally available users by using `RequestType.allLocal`:

```dart
/// Will contain the "John Doe" user
final allUsers = await userRepository.getItems(RequestDetails(requestType: .allLocal));
```

Saving data like this may cause you to distrust your request-based caches, as that new user may appear in future requests,but if so, is not yet included in the cached results for those requests if previously submitted. Any time you want to force a request to go to the server, you should use `RequestType.refresh`.

```dart
/// Will go to the server first and then write any returned records back to local
/// sources, leading to "John Doe"'s inclusion in this request's cache if the
/// server returns it in its response.
final activeUsers = await userRepository.getItems(
  RequestDetails(
    filter: ActiveUsersFilter(),
    pagination: Pagination.page(1),
    requestType: RequestType.refresh,
  ),
);
```

## Defining data bindings

To make your data types work with `pkg:data_layer`, you need to define `Bindings`. These bindings tell the data layer how to serialize/deserialize your objects, how to extract their IDs, and where to find them on the server.

```dart
final userBindings = Bindings<User>(
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
  getDetailUrl: (id) => ApiUrl(path: '/users/$id'),
  getListUrl: () => ApiUrl(path: '/users'),
);
```

If your data type supports local creation (generating an ID client-side or handling unsaved objects), use `CreationBindings`:

```dart
final userBindings = CreationBindings<User>(
  // ... same as above
  save: (user) => user.copyWith(id: Uuid().v4()),
);
```

## Loading data

Data is loaded using the standard methods on your `Repository`:

- `getById(String id)`: Fetches a single item.
- `getByIds(Set<String> ids)`: Fetches multiple items by ID.
- `getItems({RequestDetails? details, bool allLocal = false})`: Fetches a list of items, optionally filtered or paginated.
   If `allLocal` is true, all local data is returned regardless of any request-caching information.

You can customize the request using `RequestDetails`:

```dart
final details = RequestDetails(
  requestType: .global, // Default value; returns whatever non-empty data is first returned by a `Source`
);
final users = await userRepository.getItems(details);
```

The default `RequestType` is `.global`, which considers the first data source to return data to be the "correct" data. This means
that the default behavior is to read and honor locally cached data.

Other `RequestType` values are:

- `.refresh`: Bypasses local sources and only considers remote sources.
- `.local`: Only considers local sources.
- `.allLocal`: Returns all local data regardless of any request-caching information.

## Filtering data

Data requests can be filtered using `RequestDetails` when calling `getItems`:

```dart
final details = RequestDetails(
  requestType: .global,
  filter: UserFilter(isActive: true), // Apply filters
);
final users = await userRepository.getItems(details);
```

It is the job of any remote `Source` to apply this filter to its request in `getItems`. For example, the `ApiSource`
calls its filters `toParams` function (which defaults to calling `toJson`) and then applies those parameters to the
querystring of the request. Naturally, it is assumed that the remote server will apply the filter to any database queries
it executes.

Filters and pagination can be used together.

## Pagination

Similar to filtering, pagination is handled by the `ApiSource` and is applied to the request in `getItems`.

```dart
final details = RequestDetails(
  requestType: .global,
  pagination: Pagination.page(1, pageSize: 10),
);
final users = await userRepository.getItems(details);
```

It is the job of any remote `Source` to apply this pagination to its request in `getItems`. For example, the `ApiSource`
calls its pagination `toParams` function (which defaults to calling `toJson`) and then applies those parameters to the
querystring of the request. Naturally, it is assumed that the remote server will apply the pagination to any database queries
it executes.

Filters and pagination can be used together.

## Managing cached data

`pkg:data_layer` automatically caches data in local sources when it is fetched from remote sources. This "write-through"
caching strategy ensures that subsequent requests can be served locally if possible.

`pkg:data_layer`'s caching strategy consists of two layers to keep requests separate without duplicating the full volume
of cached records. The first layer is a map of request hashes to the IDs of the records returned by that request. The second
layer is a map of IDs to the actual records. The request hashing strategy is based on the `RequestDetails` object
passed to `getItems` and uses `md5` instead of typical Dart `hashCodes`, as the latter are unreliable from one execution
of your application to the next and would lead to cache misses.

The fields included in this critical `md5` hash are only `filters` and `pagination`. See more in [Forcing cache misses](#forcing-cache-misses)
for the implications of this behavior.

### Reading cached data

Understanding how `pkg:data_layer` caches data is important for managing your application's performance.

Data is cached on a per-request basis. This means that the results from a request with one set of parameters can never
lead to cache hit for a request with different parameters (even to the same `Repository`). Consider the following scenario
which begins with entirely empty caches and moves through multiple requests from different parts of your application:

```dart
final activeUsersRequestDetails = RequestDetails(
  requestType: .global,
  filter: UserFilter(isActive: true),
);

/// Loads `users` from the server and caches their information in any `LocalSource` objects.
/// Note that global requests like this are risky and will fetch as much data as your
/// server will return in a single response, and are thus only safe for small data sets.
/// If your server automatically paginates requests (which is smart), this `Repository` will not
/// know about that pagination and will potentially cause bugs. Read on for details about how to
/// handle pagination.
final users = await userRepository.getItems(activeUsersRequestDetails);

/// Some time later, elsewhere, using the same `Repository`, you request the same data (as indicated
/// by using the same `RequestDetails` object). This request will be considered a cache hit and all
/// records will be returned from local persistence.
final users = await userRepository.getItems(activeUsersRequestDetails);

/// Elsewhere, load users by Ids. Any users with Ids in the set are loaded from local persistence if possible.
/// Any users with Ids not in the set are fetched from remote sources. The `SourceList` class handles
/// this logic on your behalf.
final usersById = await userRepository.getByIds(
  {'1', '2', '3'},
  // RequestDetails is optional when calling `getByIds` or `getById`, and if
  // supplied, MUST NOT have `filter` or `pagination` values.
);

/// Elsewhere, load a single user by Id. If this Id has been loaded before, it will be pulled from the local cache.
/// If the Id has not been loaded before, it will be fetched from remote sources.
 final usersById = await userRepository.getById(
  '4',
  // RequestDetails is optional when calling `getByIds` or `getById`, and if
  // supplied, MUST NOT have `filter` or `pagination` values.
);

/// Elsewhere, on a different screen, you request active users with pagination.
final paginatedActiveUsersRequest = RequestDetails(
  requestType: .global,
  filter: UserFilter(isActive: true),
  pagination: Pagination.page(1),
);

/// This `RequestDetails` object will have a different md5 hash code from the earlier
/// `activeUsersRequestDetails` object, so the `Repository` class will send a fresh
/// request to the server for only the first page of data. The reason for this is
/// because, even though it is possible that all of these records are already cached,
/// if you care about pagination you cannot assume your local repository will know
/// how the server would paginate results. If you do not care about pagination and
/// only want performant UIs, consider using all of your cached data and a
/// `ListView.builder`, or similar.
///
/// Any records that are already cached will not be re-cached. Instead, their Ids
/// will be added to the `paginatedActiveUsersRequest` object's Id cache.
final users = await userRepository.getItems(paginatedActiveUsersRequest);

/// Elsewhere, your user interacts with a part of your UI that requires sorted users.
final sortedActiveUsersRequestDetails = RequestDetails(
  requestType: .global,
  filter: UserFilter(isActive: true, sortBy: '-name'),
);

/// This `RequestDetails` object will also have a different md5 hash code from any
/// prior object and will thus cause a new request to be sent to the server. Like before,
/// any records that are already cached will not be re-cached. Instead, their Ids
/// will be added to the `sortedActiveUsersRequestDetails` object's Id cache.
final users = await userRepository.getItems(sortedActiveUsersRequestDetails);

/// Note that if you are confident you already have all the users you need, you can
/// duplicate your earlier request, enjoy a cache hit and sort the results in memory.
final users = await userRepository.getItems(activeUsersRequestDetails);
users.sort((a, b) => a.name.compareTo(b.name));
```

### Forcing cache misses

To force a cache miss, use `.refresh` for the `RequestType` parameter.

```dart
/// Loads all users created within the last 7 days
final users = await userRepository.getItems(
  RequestDetails(requestType: .refresh, filters: CreatedWithin(const Duration(days: 7))),
);
```

This will bypass any local sources, fetch data from remote sources, and then cache any returned
results in local sources. These records will then be available as cache hits for future requests.

Later, if you want to read that same data from the cache, you can do so by not providing any
`RequestDetails` object (or providing a `RequestDetails` object with a `requestType` value of `.global`).

```dart
/// Will return the same users from the cache that were returned in the prior call
final users = await userRepository.getItems(
  RequestDetails(filters: CreatedWithin(const Duration(days: 7))),
);
```

If, upon app launch, you know you need to refresh this data again, simply use `.refresh` again when loading the data.

### Clearing cached data

To clear local persistance caches, call `.clear` on the repository. For more fine-grained control, call this
on individual `Source` objects.

```dart
// Clear all local data for this repository
await userRepository.clear();

// Clear data for a specific request
await userRepository.clearForRequest(details);
```

## Creating a Local Source

A `LocalSource` stores data on the device. It requires two persistence engines: one for the items themselves (`LocalSourcePersistence`) and one for the cache metadata (`CachePersistence`).

The package comes with `LocalMemorySource` for in-memory caching:

```dart
final localSource = LocalMemorySource<User>(userBindings);
```

For examples of other local caches, see `pkg:data_layer_hive`.

## Extending a Local Source

To create a persistent local source (e.g., using Hive or SQLite), you need to implement `LocalSourcePersistence` and `CachePersistence`.

```dart
class HiveUserPersistence implements LocalSourcePersistence<User> {
  // Implement methods to store/retrieve Users from Hive
}

class HiveCachePersistence implements CachePersistence {
  // Implement methods to store cache keys and ID mappings
}

final hiveSource = LocalSource(
  HiveUserPersistence(),
  HiveCachePersistence(),
  bindings: userBindings,
);
```

This serves as an example, but if you specifically need `Hive` support, you should use `pkg:data_layer_hive`.

## Creating a Remote Source

An `ApiSource` fetches data from a remote server. It requires a `RestApi` client to make the actual network requests.

```dart
final restApi = RestApi(
  apiBaseUrl: 'https://api.example.com',
  headersBuilder: () => {
    'Authorization': 'Bearer $myToken',
  },
);

final apiSource = ApiSource<User>(
  bindings: userBindings,
  restApi: restApi,
);
```

## Extending a Remote Source

The `ApiSource` class is generic and should work for most RESTful APIs. However, if you need to handle
non-standard response formats or complex batching logic, you can subclass `ApiSource`, or start from
scratch by subclassing `Source`.

```dart
class MyCustomApiSource extends Source<User> {
  MyCustomApiSource({super.bindings});

  @override
  SourceType get sourceType => SourceType.remote;

  /// Override more methods...
}
```
