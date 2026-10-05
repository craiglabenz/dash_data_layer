# Changelog

## 0.0.4

- Matches pkg:data_layer version 0.0.9 by renaming `delete` to `deleteItem` and by adding `deleteItems`

## 0.0.3

- Updates `sendMessage` return type from `T` to `T?`.

## 0.0.2

* Adds `raw` method to Firestore source for untyped merges.
* Implements document writes (`setItem`), deletion (`delete`), and automatic `DateTime` to `Timestamp` serialization (`cleanDataForWrite`).
* Adds realtime watching support (`watch`, `watchList`, `watchByIds`).

## 0.0.1

* Adds initial FirestoreSource implementation.
