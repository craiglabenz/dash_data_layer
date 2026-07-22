# data_layer_firestore_admin

Provides Firestore Admin bindings for `pkg:data_layer` using `pkg:google_cloud_firestore`.

## Features

- Server-side Firestore operations via `pkg:google_cloud_firestore`
- Compatible with `pkg:data_layer` source interfaces (`FirestoreAdminSource`, `FirestoreAdminFilter`)
- Support for server timestamp fields (`onCreateServerTimestampFields`, `onUpdateServerTimestampFields`)
- Automatic conversion between Firestore Timestamps and DateTime ISO 8601 strings
- Untyped document merges via `.raw(id, map)`

## Usage

```dart
import 'package:data_layer_firestore_admin/data_layer_firestore_admin.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

final firestore = Firestore(settings: const Settings(projectId: 'my-project'));
final source = FirestoreAdminSource<MyModel>(
  firestore,
  bindings: myModelBindings,
  collectionName: 'my_collection',
  onCreateServerTimestampFields: ['createdAt'],
  onUpdateServerTimestampFields: ['updatedAt'],
);

// Perform an untyped merge directly into a document
await source.raw('doc_123', {
  'status': 'processed',
  'processedAt': DateTime.now(),
});
```
