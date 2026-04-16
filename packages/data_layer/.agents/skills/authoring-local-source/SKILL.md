Authoring a new type of `LocalSource` is appropriate when you require a different storage mechanism from any existing `LocalSource` subclass or implementation. In such a scenario, the true task will ultimately amount to writing new `SourceCache` classes which bind to this required storage mechanism.

`LocalSource` itself is fully flexible and ready for varied use in any case, so custom implementations can either use fresh `SourceCache` implementations which must then be correctly passed to the generic `LocalSource.new` constructor, or can hide these details in a subclass.

The two existing `LocalSource` implementations offered by the library `LocalMemorySource` and `HiveSource` (the latter of which comes from `pkg:data_layer_hive`.)

The `LocalMemorySource` class and its workhorse, `InMemoryPersistence`, highlight the dedicated-class way to implement a source.

However, if a dedicated class is not necessary, you can also implement a custom `SourceCache<T>` and get instantiate what you need directly from the `LocalSource.builders()` convenience constructor.

```dart
class MySourceCache<T> extends SourceCache<T> {
  // ... implementations which make no assumptions about what T is
}

final myLocalSource = LocalSource.builders<T>(
  itemCache: (String name) => MySourceCache<T>(),
  setStringCache: (String name) => MySourceCache<Set<String>>(),
  dateTimeCache: (String name) => MySourceCache<DateTime>(),
);
```

If necessary, you can use the provided `name` parameter to differentiate between the returned instances of `MySourceCache`. This can be important, depending on your actual persistence mechanism and whether it requires unique namespaces (like Hive, which requires unique box names). The above example does not use this `name` parameter, but if the implementation of `MySourceCache` required a unique namespace then this sample would be adapted to pass `name` to each constructor invocation.