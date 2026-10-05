---
name: instantiating-firestore-source
description: FirestoreSource seamlessly connects Cloud Firestore streams to a SourceList.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT
---

`pkg:data_layer_firestore` provides a `FirestoreSource` class which implements the `WatchableSource` interface to seamlessly integrate Cloud Firestore into your `data_layer` ecosystem. This source handles all necessary translation between `data_layer`'s request details and Firestore's querying syntax, while also supporting real-time data streaming.

Instances of a `FirestoreSource` are meant to be used within the context of a `SourceList`.

```dart
SourceList(
  sources: [
    LocalMemorySource(...),
    FirestoreSource(
      FirebaseFirestore.instance,
      bindings: User.bindings,
      collectionName: 'users',
    ),
  ],
)
```
