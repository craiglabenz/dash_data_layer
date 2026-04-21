[![pub package](https://img.shields.io/pub/v/data_layer_flutter.svg)](https://pub.dartlang.org/packages/data_layer_flutter)

# Data Layer Flutter

An add-on to `pkg:data_layer` which provides Flutter-specific implementations of various interfaces.

See [`pkg:data_layer`](https://pub.dev/packages/data_layer) for more information.

# Index

- [Getting Started](#getting-started)

## Getting started

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: latest
  data_layer: ^0.0.6
  data_layer_flutter: ^0.0.2
```

## Creating a SourceList with Connectivity awareness

To enable retry policy with extra-smart connectivity awareness, provide not only a value for `retryPolicy`, but also the `pkg:connectivity_plus`-powered `ConnectivityService`.

```dart
SourceList(
  connectivityService: ConnectivityPlusStream(),
  retryPolicy: DefaultRetryPolicy(),
  sources: [
    ...
  ],
)
```


