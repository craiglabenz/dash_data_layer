---
name: streaming-data
description: Watching realtime data amounts to calling `watch`, `watchByIds`, or `watchList` on a Repository whose SourceList contains a `WatchableSource`.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

Watching realtime data amounts to calling `watch`, `watchByIds`, or `watchList` on a Repository whose SourceList contains a `WatchableSource.

```dart
final stream = userRepository.watchList(
   RequestDetails(filter: ActiveUsersFilter()),
);
```

It is the job of a your `WatchableSource` to negotiate how to fulfill this watch with your server. For a ready-to-go Firestore solution, see `pkg:data_layer_firestore`.
