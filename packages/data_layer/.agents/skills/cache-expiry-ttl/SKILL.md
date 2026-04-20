---
name: cache-expiry-ttl
description: Automatically invalidate local caches after a specified time to live (ttl).
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

To automatically expire locally cached data, pass a `ttl` to the `RequestDetails` object when calling any read method. This will fetch data from the server and cache it locally under the context of the `ttl`. 

```dart
final details = RequestDetails(
  ttl: const Duration(minutes: 5),
);
await userRepository.getById('123', details: details);

// Wait 5 minutes...

// This will return null because the cache has expired.
final userWillBeNull = await userRepository.getById(
  '123',
  details: RequestDetails(
    requestType: RequestType.local,
  ),
);

// However, a default request with the default [RequestDetails]
// will then fall back to the server and re-fetch User 123.
final refreshedUser123 = await userRepository.getById('123');
```
