## 0.0.2

* Adds `raw` method to Firestore source for untyped merges.
* Implements document writes (`setItem`), deletion (`delete`), and automatic `DateTime` to `Timestamp` serialization (`cleanDataForWrite`).
* Adds realtime watching support (`watch`, `watchList`, `watchByIds`).

## 0.0.1

* Adds initial FirestoreSource implementation.
