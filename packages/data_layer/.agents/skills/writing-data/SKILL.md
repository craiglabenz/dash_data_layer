---
name: writing-data
description: Writing data involves calling setItem and, optionally, setItems on a Repository.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

Writing data involves calling setItem and, optionally, setItems on a Repository.

## Writing documents

To save a new piece of data, call `setItem`.

```dart
final savedItem = await myRepository.setItem(myNewObject);
```

If the given Repository only has local sources, this will essentially cache the given value on the user's device. If, however, the Repository has a remote source, this will attempt to save `myNewObject` to whatever database sits in waiting at the other end.

Filters and pagination must not be set when calling `setItem` or `setItems`, as they are read-only concepts and suggest programmer error.

## Inserting new records vs updating existing records

By default, object Ids are expected to be set by the server when the record is saved and inserted into the database. Therefore, sources are expected to "POST" (or whatever is appropriate for your Source) new data when `bindings.getId(obj)` returns null and "PUT" existing data when it returns a non-null Id.

However, sometimes you may want to force a "POST" when your client has set the Id, and for this, set `RequestDetails.forceInsert` to true. It is then the job of your Source classes to honor this flag.

## Deciding where to write data to

There are 4 primary types of writes one can perform, as designated by the 4 values on the `RequestType` enum. They are:

* `RequestType.local`, which only calls the associated method on `SourceType.local` sources.
* `RequestType.allLocal`, which is invalid for writes
* `RequestType.global`, which cascades from local to remote sources, writing values everywhere.
* `RequestType.refresh`, which is invalid for writes.

```dart
// Skips writing to any server and instead only caches `myObject` locally.
final items = myRepository.setItem(
  myObject,
  details: RequestDetails(requestType: .local),
);
```