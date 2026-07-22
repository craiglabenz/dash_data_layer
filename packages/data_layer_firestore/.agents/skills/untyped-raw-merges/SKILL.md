---
name: untyped-raw-merges
description: Perform untyped Firestore document merges using the raw method on Firestore sources.
metadata:
  last_modified: Wed, 22 Jul 2026 15:00:00 GMT
---

`FirestoreSource` (in `pkg:data_layer_firestore`) and `FirestoreAdminSource` (in `pkg:data_layer_firestore_admin`) support untyped document merges via `.raw(id, map)`.

Use `.raw` when you need to merge an arbitrary `Map<String, Object?>` into a document without serializing or deserializing a full model object (for example, updating a timestamp or partial field flag).

```dart
// Merge arbitrary json into a document with ID 'user_123'
await firestoreSource.raw('user_123', {
  'lastActive': DateTime.now(),
  'metadata': {
    'version': '1.2.0',
  },
});
```

Key features:
- Automatically converts `DateTime` objects (and ISO 8601 strings) into Firestore `Timestamp` objects via `cleanDataForWrite`.
- Merges the fields into the existing document (or creates the document if it does not yet exist).
