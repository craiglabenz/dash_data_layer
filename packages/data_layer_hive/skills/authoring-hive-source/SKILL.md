---
name: authoring-hive-source
description: HiveSource is a LocalSource implementation that writes to Hive boxes.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT
---

`pkg:data_layer_hive` provides a `HiveSource` class which implements the `Source` interface specifically for caching data using `pkg:hive_ce`. This allows your `Repository` objects to persist data durably across application launches.

Instances of a `HiveSource` are meant to be used within the context of a `SourceList`, generally preceding a `RestSource` or other remote bounds to act as an offline cache.

```dart
SourceList(
  sources: [
    HiveSource(
      bindings: userBindings,
      boxName: 'users',
      hiveInit: Hive.initFlutter().then((_) => Hive.registerAdapters()),
    ),
    RestSource(...),
  ],
)
```
