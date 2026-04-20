---
name: authoring-proxy-source
description: Proxy Sources offer a build-a-bear type solution for irregular or JSON RPC APIs.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

Proxy Sources offer a build-a-bear type solution for irregular or JSON RPC APIs.

```dart
final apiSource = ProxySource<User>(
  sourceType: SourceType.remote,
  bindings: userBindings,
  setItemHandler: (WriteOperation<User> op) async {
    // save [op.item], which is the User
  },
);
```

### Why / when to use a ProxySource

Dart's type system giveth and Dart's type system taketh away.

Sufficiently consistent REST APIs can be highly automated, with every single data type in your application potentially served by the same `RestSource` which uses its `getDetailUrl` and `getListUrl` callbacks to determine where each and every record goes. This is nice for pkg:data_layer, but only because you have already lost type-safety across that boundary.

Conversely, APIs which preserve end-to-end type safety, like Serverpod, cannot be implemented as a single remote "ServerpodSource" for all data types, because each data type has its own concrete methods which must be called to read and write data.

For APIs like Serverpod, reach or a ProxySource like so:

```dart
class MyModelServerpodSource extends ProxySource {
  MyModelServerpodSource(this.client) : super(
    setItemHandler: (op) =>
        client.specificSaveMethod(op.item);
  );

  /// This is the specific client Serverpod generated for your
  /// app which contains your endpoints.
  final Client client;
}
```

Rinse and repeat for each model and each operation you need to perform on those models. Sadly, the strength of Dart's type system prevents anything more streamlined without code generation.