---
name: clearing-source-caches
description: Ejecting all data from local sources is as simple as calling .clear()
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

To clear all data from local sources, simply call `.clear()` on the `Repository`, which recursively calls `clear` all the way down.

```dart
await userRepository.clear();
```

To clear targeted data for a specific request, call `clearForRequest` with the `RequestDetails` object.

```dart
await userRepository.clearForRequest(details);
```