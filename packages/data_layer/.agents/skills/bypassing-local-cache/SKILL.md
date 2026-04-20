---
name: bypassing-local-cache
description: Forces reads to go to the server when locally cached data is suspected of being stale
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

By default, previously read data is immediately available from local sources and is returned without checking the remote source. This is usually the desired behavior, but sometimes you may want to force data to be fetched from the remote source. This can be done by setting the `requestType` to `RequestType.refresh`.

```dart
final users = await userRepository.getItems(
  RequestDetails(
    requestType: RequestType.refresh,
  ),
);
```

This request will not ask any local sources for data, but will still cache any remote data that is returned.