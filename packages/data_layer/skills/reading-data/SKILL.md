---
name: reading-data
description: Reading data involves calling getById, getByIds, or getItems on a Repository.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

Reading data involves calling getById, getByIds, or getItems on a Repository.

## Reading collections of data

To read lists or collections of data, call `getItems`.

```dart
final items = await myRepository.getItems();
```

### Choosing what data to read

```dart
final details = RequestDetails(
  filter: MyFilter(),
  pagination: Pagination.page(1, pageSize: 25),
);

/// Loads the first 25 items which are included by `MyFilter`,
/// whatever that means in your application.
final result = await userRepository.getItems(details);
```

Filters and pagination must only be set when calling `getItems`, as their behavior would be contradictory and undefined during `getById` or `getByIds`.

> Note: Passing pagination or filters to a read request will bypass local caches unless that exact requets with those exact filter and pagination values has already been seen. In the above scenario. even if local Sources have 25 or more records available, they will not be returned, because it is not the job of local Sources to know whether they have the *correct* 25 users that the server would return if asked in this way.

## Reading a single record

When you know the exact document or database record you want to load, call `getById`.

```dart
final item = await myRepository.getById('abc');
```

## Reading a known set of records

When you know the exact set of documents or database records you want to load, call `getByIds`.

```dart
final item = await myRepository.getByIds(<String>{'abc', 'xyz'});
```

## Deciding where to read data from

There are 4 primary types of reads one can perform, as designated by the 4 values on the `RequestType` enum. They are:

* `RequestType.local`, which only calls the associated method on `SourceType.local` sources.
* `RequestType.allLocal`, which bypasses pkg:data_layer's request-based caching and returns all locally available records from any `SourceType.local` sources.
* `RequestType.global`, which cascades from local to remote sources, returning the first non-empty data found. This is the default value.
* `RequestType.refresh`, which skips `SourceType.local` sources and only asks `SourceType.remote` sources for data; but then caches any data found within local sources.

```dart
// Bypass local caching and force the repository to load fresh data from the server.
final items = myRepository.getItems(
  details: RequestDetails(
    requestType: .refresh,
  ),
);
```