[![pub package](https://img.shields.io/pub/v/data_layer_hive.svg)](https://pub.dartlang.org/packages/data_layer_hive)

# Data Layer Hive

An add-on to `pkg:data_layer` which provides a Hive implementation of the `Source` interface.

# Motivation

On-device caching is complicated. While some reach for SQL in the form of sqlite3, the data that arrives on a device by way of API responses is already denormalized. Instead of re-normalizing it, or forbidding use of JOINs in server-side queries, `pkg:data_layer_hive` brings persistent, offline-friendly document-based caching to `pkg:data_layer`.

# Index

- [Motivation](#motivation)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Creating a HiveSource](#creating-a-hivesource)

## Getting started

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  data_layer: ^0.0.1-beta.4
  data_layer_hive: ^0.0.1-beta.1
```

It is recommended to use `pkg:hive_ce` for its companion package, `pkg:hive_ce_generator`, which allows you to register your models like so:

```dart
@GenerateAdapters([AdapterSpec<MyModel>()])
part 'hive_adapters.g.dart';
```

See the `example` directory for a complete working sample of a `Repository` using both a `LocalMemorySource` and a `HiveSource`.

## Creating a HiveSource

Instances of a `HiveSource` meant to be used within the context of a `SourceList`.

```dart
SourceList(
  ...
  sources: [
    HiveSource(
      // You probably want to call this code elsewhere and capture its Future
      // for reuse across multiple `HiveSource` instances.
      hiveInit: Hive.initFlutter().then((_) => Hive.registerAdapters()),
    ApiSource(...),
  ],
)


