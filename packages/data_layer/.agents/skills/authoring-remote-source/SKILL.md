---
name: authoring-remote-source
description: Remote sources are the API-specific bindings for pkg:data_layer.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT
---

Remote sources use the actual real-live Internet to make network requests and read or write data.

### Reads

Remote sources have two absolutely critical jobs when reading data:

1. Correctly applying any `filter` to the request, and
2. Correctly applying any `pagination` to the request.

A remote source which fails to do either of these jobs will result in undefined behavior when calling `getItems`. Consider the beginning of the `RestSource.getItems `implementation:

```dart
  @override
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation) async {
    final Params params = <String, String>{};

    // Add a specified filter as query parameters
    if (operation.details.filter != null) {
      params.addAll(operation.details.filter!.toParams());
    }

    // Add all specified pagination as query parameters
    if (operation.details.pagination != null) {
      params.addAll(operation.details.pagination!.toParams());
    }
    
    // Make the actual request
  }
```

For SDKs that behave sufficiently differently from REST-based APIs, consider requiring a new method, like the `FirestoreSource`'s required `FirestoreFilter.apply` method out of the `pkg:data_layer_firestore` package, which accepts a Firestore `Query` object, calls any filter functions as necessary, and returns the modified query.

### Writes

Writing data via a Remote source involves implementing `setItem` and, optionally, `setItems`; though the behavior of `setItems` is so unpredictable as to not be offered by any `Source`s baked in to `pkg:data_layer`.

The most important job of `setItem`, specifically, is to honor `RequestDetails.forceInsert` for situations where records already contain an Id despite not yet existing in the database, and thus requiring an INSERT statement instead of an UPDATE statement. Or, for a Firebase-centric example, if the Document Id is known by the client despite not yet existing, which requires calling different methods on the `CollectionReference` class.