---
name: instantiating-firestore-admin-source
description: FirestoreAdminSource connects google_cloud_firestore for server-side Dart applications to a SourceList.
metadata:
  last_modified: Wed, 22 Jul 2026 15:00:00 GMT
---

`pkg:data_layer_firestore_admin` provides a `FirestoreAdminSource` class which implements the `Source` interface for server-side Dart applications using `pkg:google_cloud_firestore`.

Instantiate `FirestoreAdminSource` within a `SourceList`:

```dart
import 'package:data_layer_firestore_admin/data_layer_firestore_admin.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

final firestore = Firestore(settings: const Settings(projectId: 'my-project'));

final adminSource = FirestoreAdminSource<MyModel>(
  firestore,
  bindings: MyModel.bindings,
  collectionName: 'my_collection',
  onCreateServerTimestampFields: ['createdAt'],
  onUpdateServerTimestampFields: ['updatedAt'],
);
```

Note: `google_cloud_firestore` is designed for server-side Dart and does not support real-time stream watching (`watch`, `watchList`, `watchByIds`). Calling watch methods will throw an `UnimplementedError`.
