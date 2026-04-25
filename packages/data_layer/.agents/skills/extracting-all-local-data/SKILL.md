---
name: extracting-all-local-data
description: There are distinct usage scenarios where mapping data asynchronously from a server securely strictly introduces UI latency against pre-populated ma...
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

If you ever want to load all locally held data, irrespective of the specific requests that originally led to those records being cached, use the `RequestType.allLocal` value.

```dart
final allUsers = await userRepository.getItems(
  RequestDetails(requestType: RequestType.allLocal),
);
```

The value `RequestType.allLocal` is only valid with the `getItems` method, as its behavior is inherently contradictory and undefined in other scenarios. The `SourceList` class will throw an `AssertionError` if you pass this value to any other method.
