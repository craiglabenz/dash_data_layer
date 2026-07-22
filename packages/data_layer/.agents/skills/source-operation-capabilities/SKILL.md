---
name: source-operation-capabilities
description: Understand how sources declare operation capabilities via supportedOperations and how SourceList respects them.
metadata:
  last_modified: Wed, 22 Jul 2026 15:00:00 GMT
---

In `pkg:data_layer`, `DataContract` and `Source` declare supported operation types via the `supportedOperations` getter, which returns a `Set<SourceOperationType>`.

By default, `DataContract` supports standard CRUD operations (`getById`, `getByIds`, `getItems`, `setItem`, `setItems`, `delete`).

Specific mixins add additional supported operations:
- `WatchableSource`: Adds `watch`, `watchList`, and `watchByIds`.
- `MessageWriteMixin`: Adds `sendMessage`.

`ProxySource` populates `supportedOperations` dynamically based on which handler callbacks were passed to its constructor.

```dart
// Check if a source supports a given operation type
if (source.supports(operation.type)) {
  await source.setItem(operation);
}
```

The `SourceList` automatically checks `source.supports(operation.type)` before invoking operations on each source, skipping sources that do not support the operation without throwing `UnimplementedError`.
