[![pub package](https://img.shields.io/pub/v/data_layer_firestore.svg)](https://pub.dartlang.org/packages/data_layer_firestore)

# Data Layer Hive

An add-on to `pkg:data_layer` which provides a Firestore implementation of the `Source` interface.

# Motivation

Seamlessly plug Cloud Firestore into your Flutter apps' `data_layer` repositories with the `FirestoreSource` class from this package.

# Index

- [Motivation](#motivation)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Creating a HiveSource](#creating-a-hivesource)

## Getting started

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  data_layer: ^0.0.6
  data_layer_firestore: ^0.0.1
```

## Creating a FirestoreSource

Instances of a `FirestoreSource` meant to be used within the context of a `SourceList`.

```dart
SourceList(
  ...
  sources: [
    LocalMemorySource(...),
    FirestoreSource(
      FirebaseFirestore.instance,
      bindings: User.bindings,
      collectionPath: 'users',
  ],
)


