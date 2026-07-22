[![pub package](https://img.shields.io/pub/v/data_layer_firestore.svg)](https://pub.dartlang.org/packages/data_layer_firestore)

# Data Layer Firestore

An add-on to `pkg:data_layer` which provides a Firestore implementation of the `Source` interface.

# Motivation

Seamlessly plug Cloud Firestore into your Flutter apps' `data_layer` repositories with the `FirestoreSource` class from this package.

# Index

- [Motivation](#motivation)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Creating a FirestoreSource](#creating-a-firestoresource)
- [Server Timestamp Fields](#server-timestamp-fields)
- [Untyped Merges (`raw`)](#untyped-merges-raw)

## Architecture

`pkg:data_layer_firestore` provides a `FirestoreSource` class which implements the `WatchableSource` interface to seamlessly integrate Cloud Firestore into your `data_layer` ecosystem. This source handles all necessary translation between `data_layer`'s request details and Firestore's querying syntax, while also supporting real-time data streaming.

## Getting started

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  data_layer: ^0.0.7
  data_layer_firestore: ^0.0.2
```

## Creating a FirestoreSource

Instances of a `FirestoreSource` are meant to be used within the context of a `SourceList`.

```dart
SourceList(
  ...
  sources: [
    LocalMemorySource(bindings: User.bindings),
    FirestoreSource(
      FirebaseFirestore.instance,
      bindings: User.bindings,
      collectionName: 'users',
    ),
  ],
)
```

## Server Timestamp Fields

`FirestoreSource` can automatically populate server timestamps on document creation and update operations:

```dart
FirestoreSource(
  FirebaseFirestore.instance,
  bindings: User.bindings,
  collectionName: 'users',
  onCreateServerTimestampFields: ['createdAt'],
  onUpdateServerTimestampFields: ['updatedAt'],
)
```

## Untyped Merges (`raw`)

To merge an arbitrary `Map<String, dynamic>` into a document without deserializing into a full object model:

```dart
await firestoreSource.raw('user_123', {
  'lastActive': DateTime.now(),
  'status': 'online',
});
```
