[![pub package](https://img.shields.io/pub/v/data_layer.svg)](https://pub.dartlang.org/packages/data_layer)

# Data Layer

Data Layer is a pure Dart package for declarative data fetching and caching.

# Motivation

Correctly managing data is one of the most important parts of any app and failure to separate it from state management plays a significant role in complicating one's codebase.

Further, naive approaches like always loading data from the server every time you need it are easy, but not performant or offline-friendly. This suggests *caching* data; but as cache invalidation is one of the three hard problems in computer science, *there be dragons*.

`pkg:data_layer` aims to provide a simple, yet powerful, way to manage data in your app.

# Architecture

Everything in `pkg:data_layer` resolves around satisfying the `DataContract` interface. This interface has the following primary methods:

* `getById` - Retrieves a single item by its Id. Does not support filters or pagination.
* `getByIds` - Retrieves a list of items by their Ids. Does not support filters or pagination.
* `getItems` - Retrieves a list of items. Pagination is recommended and filters are (of course) optional.
* `setItem` - Persists a single item.
* `setItems` - Persists a list of items.
* `deleteItem` - Deletes a single item.

Additionally, three streaming equivalents of the read methods exist:

* `watch` - Streams updates to a single item by its Id.
* `watchList` - Streams updates to the set of items which satisfy the given request.
* `watchByIds` - Streams updates to a list of items by their Ids.

The primary class from `pkg:data_layer` which the rest of your app will encounter is `Repository`, which defaults to defining handlers for all of the above methods, but may decide to define only a subset if appropriate for a given use case. (For example, a read-only data endpoint may throw `UnimplementedError` exceptions for `setItem`, `setItems`, and `deleteItem`.)

Within a `Repository` is the all-important `SourceList`, which manages juggling data between an arbitrary list of `Source` objects. The `SourceList` class is the core of `pkg:data_layer`. You should not need to subclass or alter its behavior, as any special behavior should be coded into the `Repository` or `Source` layers.

Understanding the `SourceList` is key to understanding `pkg:data_layer`. See the [detailed description of the `SourceList`](#understanding-the-sourcelist) below.

`Source` objects are the primary means of loading and persisting data. `Source` objects can either be `.local` or `.remote`, which designates whether the data is loaded from a local cache or a remote server, respectively.

# Index

- [Motivation](#motivation)
- [Architecture](#architecture)
- [Features](#features)
- [Getting started](#getting-started)
- [Data layer principles](#data-layer-principles)
- [Creating a Repository](#creating-a-repository)
- [Instantiating a Repository](#instantiating-a-repository)
- [Understanding the SourceList](#understanding-the-sourcelist)
- [Defining data bindings](#defining-data-bindings)
- [Loading data](#loading-data)
- [Filtering data](#filtering-data)
- [Pagination](#pagination)
- [Streaming data](#streaming-data)
- [Managing cached data](#managing-cached-data)
- [Retrying operations](#retrying-operations)
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
- Extensibility to work with any data source, including Hive, SQLite, ServerPod, Firebase, etc.
- Failed operation retry, including exponential backoff and connectivity management

## Getting started

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  data_layer: latest

  # Optional, but allows data_layer caches to survive application restarts
  data_layer_hive: latest

  # Optional, but allows data_layer Repositories to manage lost connectivity
  data_layer_flutter: latest
```

## Data layer principles

The following principles are for most data layers across most apps, not just apps using this package.

### Data layer objects should PROBABLY be singletons

If you have a `Repository` which loads and caches `User` objects, it should probably exist for the entire life of your app and should never be duplicated. Blocs or Providers come and go with the lifecycle of the screen they power, but data layer objects can often power many different screens and should not be disposed of.

### Data layer objects should COMPLETELY OWN their data type

Once you initialize a `Repository` for a single data type, that should be the preferred way of loading those records across your entire app. If, in some instances, you need an altered form of that data and cannot use your first `Repository`, you should create a new `Repository` for that altered form of the data.

For example, imagine you have a very large data structure which is partially loaded on a list view and then only fully loaded on a detail view after a user selects one of your objects. You should consider having two repositories, `ListMyObjectRepository` and `DetailMyObjectRepository`, each with their own `SourceList` and sources.

You should NOT create two different `UserRepository` objects simply because two areas of your app load different sets of users. Instead, lean on the `SourceList`'s request-based caching mechanisms to handle the filtering and pagination of your data from a single `UserRepository`.

## Creating a Repository

The `Repository` class is the primary entry point for your application to access data. It is designed to be subclassed for each data type in your application.

```dart
class UserRepository extends Repository<User> {
  UserRepository(super.sourceList);
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

Optionally, you can activate retries by providing a `RetryPolicy` to the `SourceList` constructor.

```dart
final userRepository = UserRepository(
  SourceList<User>(
    bindings: userBindings,
    retryPolicy: DefaultRetryPolicy(...),
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

For more information on `DefaultRetryPolicy`, see [Retrying operations](#retrying-operations).

## Understanding the SourceList

The `SourceList` class is a request-based read-thru cache whose behavior is best explained by example.

The `SourceList` exists to juggle caching the responses from remote sources into the storage mechanism of local sources. As such, the general shape of a SourceList is as follows:

```dart
  SourceList(
    ...
    sources: [
      MyLocalSource(), // In-memory, Hive, or similar
      MyRemoteSource(), // RESTful API, Serverpod, Firebase, Supabase, etc
    ],
  )
```

It is possible to have more than one local source, but the most immediate sources must always be listed first. For example, the following definition is good:

```dart
SourceList(
    ...
    sources: [
      InMemoryLocalSource(),
      HiveSource(),
      ApiSource(),
    ],
  )
```

Whereas the following definition is wasteful:

```dart
SourceList(
    ...
    sources: [
      // Placing the HiveSource before the InMemorySource means the InMemorySource
      // will never be meaningfully read and should be deleted.
      HiveSource(),
      // This Source will have records cached to it, but all reads will be satisfied
      // by the HiveSource first, so that cache will be pure bloat.
      InMemoryLocalSource(),
      ApiSource(),
    ],
  )
```

Multiple local sources are only useful if one is durable for true offline caching, like sqlite3 or Hive, but deemed not fast enough for immediate reads. In general, this is probably not the case and you should consider using a single local source first.

Consider an empty `SourceList` with a single in memory local `Source` and a single RESTful API-powered remote `Source`, like the above. Your first action may be to read data, like so:

```dart
final users = await userRepository.getItems();
```

First, the `SourceList` will attempt to read data from its local sources. If no data is found, it will then attempt to read data from its remote sources. If data is found in a remote `Source`, it will be written to the local `Source`.

Critically, this cached data is tied to the exact request that yielded it. If you make a different request, like below, the local `Source` will not have a cache hit and the `SourceList` will once again continue on to its remote `Source`.

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

The `SourceList` will detect a missing `id` value and immediately write this value to the server for `id` generation. At which point, the returned value will be saved to the local `Source` and returned to the caller. Assuming the server generated an `id` of `"abc"`, the following call would yield a cache hit and not request the data from the server:

```dart
final johnDoe = await userRepository.getById('abc');
```

However, local sources are request-based and cannot know which requests would yield this new John Doe user. As such, right now the only way to read that user from the local `Source` is to either request it by its Id like above, or to load all locally available users by using `RequestType.allLocal`:

```dart
/// Will contain the "John Doe" user
final allUsers = await userRepository.getItems(
  RequestDetails(requestType: .allLocal),
);
```

Saving data like this may cause you to distrust your request-based caches, as that new user would possibly appear in future requests sent to the server. However, if those requests were previously submitted and are cached, your newly written records are not yet included in any request-based caches. Thus, any time you want to force a request to go to the server, you should use `RequestType.refresh`.

It is the job of your state management solution to track this and determine which `RequestType` to use at a given moment.

```dart
/// Will go to the server first and then write any returned records back to local
/// sources, leading to "John Doe"'s inclusion in this request's cache if the
/// server returns it in its response.
final activeUsers = await userRepository.getItems(
  RequestDetails(
    filter: ActiveUsersFilter(),
    pagination: Pagination.page(1),
    requestType: .refresh,
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

- `getById(String id, [RequestDetails? details])`: Fetches a single item.
- `getByIds(Set<String> ids, [RequestDetails? details])`: Fetches multiple items by ID.
- `getItems({RequestDetails? details})`: Fetches a list of items, optionally filtered or paginated.

You can customize any of these requests using `RequestDetails`:

```dart
final details = RequestDetails(
  requestType: .global, // Default value; returns whatever non-empty data is first returned by a `Source`
);
final users = await userRepository.getItems(details);
```

The default `RequestType` is `.global`, which considers the first data source to return data to be the "correct" data. This means that the default behavior is to read and honor locally cached data.

Other `RequestType` values are:

- `.refresh`: Bypasses local sources and only considers remote sources.
- `.local`: Only considers local sources - cache hit or nothing!
- `.allLocal`: Returns all local data regardless of any request-caching information. Also, does not consider remote sources.

> Note: The difference between `.local` and `.allLocal` is that `.local` is request-based and will only return data that was specifically returned by a remote source for that exact request. Meanwhile, `.allLocal` will return all local data regardless of any request-caching information.

## Filtering data

Data requests can be filtered using `RequestDetails` when calling `getItems`:

```dart
final details = RequestDetails(
  requestType: .global,
  filter: UserFilter(isActive: true), // Apply filters
);
final users = await userRepository.getItems(details);
```

It is the job of any remote `Source` to apply this filter to its request in `getItems`. For example, the `ApiSource` calls its filters `toParams` function (which defaults to calling `toJson`) and then applies those parameters to the querystring of the request. Naturally, it is assumed that the remote server will apply the filter to any database queries it executes.

Filters and pagination can be used together.

### Local evaluation of filters

This never happens. Filters are never applied to local data due to the risk of false-positives. If you make a filtered request to the server, any local `Source` objects will cache those records as belonging to those requests. However, if you happen to have cached a few records which match a given filter, local evaluation of the filter would very likely not result in expected behavior. Consider the following:

```dart
/// Saves this new user to the server and caches it locally *by its Id*.
final newUser = await UserRepository.setItem(User(isActive: true));

/// Loads active users from the repository.
///
/// Critically, the `newUser` object above will not lead to a cache hit, because
/// this request has never been made before and thus no local cache exists for
/// it. This is important because you have no way of knowing how many other
/// active users exist which the server would return when asked.
///
/// Thus, the `SourceList` powering this repository will send the following
/// request to the server, which will return active users as per your business
/// logic rules. Of course, consider including pagination to limit the number of
/// records returned.
///
/// This represents why caching is request-based and why filters are never
/// evaluated locally.
final activeUsers = await userRepository.getItems(RequestDetails(filter: ActiveUsersFilter()));
```

The fact that filters are never applied locally has implications for fast-paced applications with highly time-sensitive data. In such cases, it is recommended to use `RequestType.refresh` to force a `SourceList` to skip reading any local sources and instead go straight back to your remote sources.

Consider the following scenario:

```dart
final messages = await messageRepository.getItems(
  RequestDetails(filters: MessagesSentInLast(Duration(seconds: 1))),
);

// At this point, 1-second old messages are all cached locally. However, more than a second later, none of those messages should still belong to that dataset. However, the following request would still yield all of the stale "1-second old" messages:

final staleMessages = await messageRepository.getItems(
  RequestDetails(filters: MessagesSentInLast(Duration(seconds: 1))),
);
```

Thus, for highly time sensitive data, is probably bet to use `RequestType.refresh` to force a `SourceList` to skip reading any local sources and instead go straight back to your remote sources.

## Pagination

Similar to filtering, pagination is handled by the `ApiSource` and is applied to the request in `getItems`.

```dart
final details = RequestDetails(
  requestType: .global,
  pagination: Pagination.page(1, pageSize: 10),
);
final users = await userRepository.getItems(details);
```

It is the job of any remote `Source` to apply this pagination to its request in `getItems`. For example, the `ApiSource` calls its pagination `toParams` function (which defaults to calling `toJson`) and then applies those parameters to the querystring of the request. Naturally, it is assumed that the remote server will apply the pagination to any database queries it executes.

Filters and pagination can be used together.

## Streaming data

To stream data, you need to implement the 3 streaming methods on `WatchableSource`. Naturally, this requires establishing a contract with your backend for live updates. Serverpod and Supabase provide great websocket support, of course Firebase is known for its real-time capabilities; but either way, it is the job of a `WatchableSource` author to produce a stream that emits new objects whenever data changes.

For an experimental `FirestoreSource`, see the `data_layer_firestore` package. (Work in progress.)


## Managing cached data

`pkg:data_layer` automatically caches data in local sources when it is fetched from remote sources. This "write-through" caching strategy ensures that subsequent requests can be served locally if possible.

`pkg:data_layer`'s caching strategy consists of two layers to keep requests separate without duplicating the full volume of cached records. The first layer is a map of request hashes to the IDs of the records returned by that request. The second layer is a map of IDs to the actual records. The request hashing strategy is based on the `RequestDetails` object passed to `getItems` and uses `md5` instead of typical Dart `hashCodes`, as the latter are unreliable from one execution of your application to the next and would lead to cache misses.

This two-layer caching strategy means that two requests which return the same set of records will not cache those shared records twice, but will instead each store pointers to their payloads.

The `RequestDetails` fields included in this critical `md5` hash are only `filters` and `pagination`. See more in [Forcing cache misses](#forcing-cache-misses) for the implications of this behavior.

### Reading cached data

Understanding how `pkg:data_layer` caches data is important for managing your application's performance.

Data is cached on a per-request basis. This means that the results from a request with one set of parameters can never lead to cache hit for a request with different parameters (even to the same `Repository`). Consider the following scenario which begins with entirely empty caches and moves through multiple requests from different parts of your application:

```dart
final activeUsersRequestDetails = RequestDetails(
  requestType: .global,
  // [UserFilter] is a hypothetical filter class that you write.
  filter: UserFilter(isActive: true),
);

/// Loads `users` from the server and caches their information in any
/// `LocalSource` objects. Note that global requests like this are risky and
/// will fetch as much data as your server will return in a single response, and
/// are thus only safe for small data sets.
///
/// If your server automatically paginates requests (which is smart), this
/// `Repository` will not know about that pagination, because it was not
/// specified in the `RequestDetails` object, and will potentially cause bugs.
/// Read on for details about how to intentionally handle pagination.
final users = await userRepository.getItems(activeUsersRequestDetails);

/// Some time later, elsewhere, using the same `Repository`, you request the
/// same data (as indicated by using the same `RequestDetails` object). This
/// request will be considered a cache hit and all records will be returned from
/// local persistence.
final users = await userRepository.getItems(activeUsersRequestDetails);

/// Elsewhere, load users by Ids. Any users with Ids in the set are loaded from
/// local persistence if possible. Any users with Ids not in the set are fetched
/// from remote sources. The `SourceList` class handles this logic on your behalf.
final usersById = await userRepository.getByIds(
  {'1', '2', '3'},
  // RequestDetails is optional when calling `getByIds` or `getById`, and if
  // supplied, MUST NOT have `filter` or `pagination` values.
);

/// Elsewhere, load a single user by Id. If this Id has been loaded before, it
/// will be pulled from the local cache. If the Id has not been loaded before,
/// it will be fetched from remote sources.
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
  RequestDetails(
    requestType: .refresh,
    filters: CreatedWithin(const Duration(days: 7)),
  ),
);
```

This will bypass any local sources, fetch data from remote sources, and then cache any returned results in local sources. These records will then be available as cache hits for future requests.

Any records previously cached against this request will not be deleted, but they will be dropped from the mapping for this specific request. This means that they will still be eligible for cache hits when you request those records by their Ids, but they will not be included in the results for this specific request again, made with the `.local` or `.global` request types.

```dart
/// Will return the same users from the cache that were returned in the prior call
final users = await userRepository.getItems(
  // The default `RequestType` value is `.global`, which loads data from anywhere
  RequestDetails(
    // [CreatedWithin] is a hypothetical filter class that you write.
    filters: CreatedWithin(const Duration(days: 7)),
  ),
);
```

If, upon app launch, you know you need to refresh this data again, use `.refresh` again when loading the data. It is the job of your state management solution to track when to use `.refresh`.

### Expiring cached data

By default, cached data does not expire. However, any time you write data to a `LocalSource`, you can specify a `ttl` (time to live) value to expire the data after a certain amount of time. Doing so will not automatically remove the data at that time, but will cause `LocalSource`s to return `null` when next asked for that data. Additionally, the stale data will be deleted at this time.

Your state management will not automatically be made aware of expired data when its `ttl` elapses, as `Repository` classes and their inner `SourceList` objects do not watch for these implicit timers to expire and broadcast any signals. In a scenario where you have reduced tolerance for stale data, you should use `RequestType.refresh` to force a `SourceList` to skip reading any local sources and instead go straight back to your remote sources.

If you know you always want to cache data for a limited period if time, you can supply a `ttl` value to the `LocalSource` itself, instead of each `RequestDetails` object. Note that a `ttl` value attached to a `RequestDetails` object will override any `ttl` value attached to the `LocalSource`, only for that cache write.

### Cleaning up disappearing data

Consider the following situation. First, you fetch a list of records from the server and cache them locally.

```dart
// Reads data from the server (assuming no cache hits), loading [User1] and [User2]
final users = await userRepository.getItems(
  RequestDetails(filters: MyFilter()),
);
/// Users == [User1, User2]
```

At this point, your `UserRepository` will have cached `User1` and `User2` to any local sources. However, later, imagine you force a cache miss and send the same request to the server.

```dart
/// Forces a local cache miss and repeats the same request from before; this time returning only [User2]
final users = await userRepository.getItems(
  RequestDetails(requestType: .refresh, filters: MyFilter()),
);
/// Users == [User2]
```

However, this time, only `User2` was returned. What would you expect from the following call to `getItems`?

```dart
/// My default, all sources attempt to satisfy requests from local sources first; and since data definitely exists locally for `MyFilter()`, no request will be sent to the server.
final users = await userRepository.getItems(
  RequestDetails(filters: MyFilter()),
);
```

Should `users` contain both [User1] and [User2], or just [User2]? `pkg:data_layer` makes the opinionated choice that only [User2] will be returned, because the last time this request was made, the server communicated that now only [User2] lives within that dataset.

[User1] will have been removed from the cache associated with `MyFilter()`. Further, if [User1] was not associated with any other requests at all, it will be deleted locally; thereby removing it from the following request, as well:

```dart
// [.allLocal] reads all locally available data, regardless of request, and makes no request to the server.
final users = await userRepository.getItems(
  RequestDetails(requestType: .allLocal, filters: MyFilter()),
);
/// Users only contains [User2]
```

### Clearing cached data

To clear local persistance caches, call `.clear` on the repository. For more fine-grained control, call this on individual `Source` objects.

```dart
// Clear all local data for this repository
await userRepository.clear();

// Clear data for a specific request
await userRepository.clearForRequest(details);
```

## Retrying operations

To activate Data Layer's automatic retry capabilities, provide `RetryPolicy()` object to a `SourceList`.

Reasonable defaults are provided by the `DefaultRetryPolicy` class, but that still requires that you provide a `readsPersistence` and `writesPersistence` engine.

### OperationPersistence

The concept of "operation persistence" is to store a complete representation of any read or write operation that you want to retry. This is useful for operations that fail due to connectivity issues or server errors.

`DefaultRetryPolicy` uses two `OperationPersistence` objects to store failed operations: one for reads and one for writes. The reason for this is because reads have no side effects and so can safely be retried the next time the data is requested, even if that is not until the next time the app launches. Writes, on the other hand, are expected to have side effects, so they are saved in a Hive box for more durable retry logic.

For this reason, the typical way to use `DefaultRetryPolicy` is like so:

```dart
final retryPolicy = DefaultRetryPolicy(
  readsPersistence: InMemoryOperationPersistence(),
  writesPersistence: HiveOperationPersistence(),
  // Optional, but recommended to provide a non-null value.
  maxRetries: 3,
);
```

### Opting out of retries

Setting the `RequestDetails.shouldRetry` property to `false` will cause the `SourceList` to not retry the operation.

> Note: It is possible to implement a faulty `RetryPolicy` class which fails to honor this field, so don't do that.

## Creating a Local Source

A `LocalSource` stores data on the device. The inner design of a `LocalSource` optimizes for an easy extension / implementation experience at the cost of minor boilerplate when instantiating your new source.

> Note: This is why `LocalMemorySource` is provided - it implements all of the required interfaces for you. The same is true for `HiveSource` out of `pkg:data_layer_hive`.

`LocalSource` objects divide their persistence into three components: `itemsCache`, `requestCache`, and `paginatedRequestCache`. The `itemsCache` is responsible for storing the actual data, while the `requestCache` is responsible for storing metadata about the requests that were made. The `paginatedRequestCache` is responsible for storing metadata about the paginated requests that were made.

Additionally, two of these three cache objects are themselves a layered caching mechanism to invisibly honor the `ttl` (time to live) values that you specify when writing data. This prevents new `LocalSource` implementations from having to reimplement this same logic.

> Note: Avoiding re-implementation of `ttl` logic is why the `LocalSource`'s inner design is so abstract.

The package comes with `LocalMemorySource` for in-memory caching:

```dart
final localSource = LocalMemorySource<User>(userBindings);
```

For examples of other local caches, see `pkg:data_layer_hive`.

## Extending a Local Source

To create a persistent local source (e.g., using Hive or SQLite), you need to implement `SourceCache` for the persistence engine you are adding.

```dart
class HiveCache<T> extends SourceCache<T> {
  // Implement methods to store/retrieve Users from Hive
}

// Then you can create a Hive-powered local source by passing in the correct
// persistence engines.
final hiveSource = LocalSource<User>(
  itemsCache: ExpiringCache<User>(
    cache: HiveCache<User>(),
    cacheExpiryTimes: HiveCache<DateTime>(),
  ),
  requestCache: ExpiringCache<Set<String>>(
    cache: HiveCache<Set<String>>(),
    cacheExpiryTimes: HiveCache<DateTime>(),
  ),
  paginatedRequestCache: HiveCache<Set<String>>(),
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

The `ApiSource` class is generic and should work for most RESTful APIs. However, if you need to handle non-standard response formats or complex batching logic, you can subclass `ApiSource`, or start from scratch by subclassing `Source`.

```dart
class MyCustomApiSource extends Source<User> {
  MyCustomApiSource({super.bindings});

  @override
  SourceType get sourceType => SourceType.remote;

  /// Override more methods...
}
```
