---
name: connectivity-awareness
description: ConnectivityPlusStream provides a stream of network statuses based on connectivity_plus so DefaultRetryPolicy can intelligently manage failed Operations.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT
---

`pkg:data_layer_flutter` provides Flutter-specific implementations for interfaces defined in `pkg:data_layer`. Primarily, it provides `ConnectivityPlusStream`, an implementation of `ConnectivityService`, offering connectivity awareness for the `DefaultRetryPolicy` class using `pkg:connectivity_plus`.

To enable retry policy with extra-smart connectivity awareness, provide the `pkg:connectivity_plus`-powered `ConnectivityPlusStream` to the `connectivityService` param.

```dart
SourceList(
  connectivityService: ConnectivityPlusStream(),
  retryPolicy: DefaultRetryPolicy(),
  sources: [
    // ...
  ],
)
```
