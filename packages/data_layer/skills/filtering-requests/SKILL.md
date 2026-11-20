---
name: filtering-requests
description: Filters communicate intent to limit to read a specific subset of data. They are never executed locally and rely on "remote" sources correctly applying the filter to their network request.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

Data Layer Filters declare an intent to receive a specific subset of all possible data, but do nothing on their own without a Remote source to correctly apply them to a network request.

```dart
final details = RequestDetails(
  filter: UserFilter(isActive: true), 
);
final users = await userRepository.getItems(details);
```

This works by implementing the `UserFilter`'s `toJson()` method and then having a Remote source call that method and attach the resulting map as query string parameters. Without connecting these dots, the `UserFilter` class would have no impact.

### Defining a Filter

Filters must also produce a deterministic hash value (`Object.hash` or an unmodified `filter.hashCode` are not suitable!) to contribute to Data Layer's request-based caching system. 

```dart
class UserFilter extends Filter {
  @override
  CacheKey get cacheKey => 'userfilter';

  @override
  Json toJson() => {'isActive': true};
}
```

When a filter's parameters are dynamic, that must be deterministically reflected in its `cacheKey`.

```dart
class AuthoredByFilter extends Filter {

  AuthoredByFilter(this.user);

  final User user;

  @override
  CacheKey get cacheKey => 'authored-by-${user.id}';

  @override
  Json toJson() => {'authoredBy': user.id};
}
```

### Combining filters with `ComboFilter`

Multiple filters can be combined—and nested—using `ComboFilter` with `BooleanLogic.and` or `BooleanLogic.or`:

```dart
final details = RequestDetails(
  filter: ComboFilter(
    [
      ActiveUsersFilter(),
      AdminUsersFilter(),
    ],
    BooleanLogic.and,
  ),
);
```

When using `FirestoreSource` or `FirestoreAdminSource`:
- **`BooleanLogic.and`**: Works with any `FirestoreFilter` / `FirestoreAdminFilter` (whether it overrides `apply()` or `toFirestoreFilter()`).
- **`BooleanLogic.or`** (and nested `AND` inside `OR`): Requires child filters to override `toFirestoreFilter()` returning a `cloud_firestore.Filter` (or `google_cloud_firestore.Filter`). Filters that only implement `toFirestoreFilter()` automatically inherit `apply()` as well, so they work in standalone, `AND`, and `OR` queries.

```dart
import 'package:cloud_firestore/cloud_firestore.dart' as cf show Filter;
import 'package:data_layer/data_layer.dart';
import 'package:data_layer_firestore/data_layer_firestore.dart';

class RoleFilter extends FirestoreFilter {
  const RoleFilter(this.role);

  final String role;

  @override
  cf.Filter toFirestoreFilter() => cf.Filter('role', isEqualTo: role);

  @override
  CacheKey get cacheKey => 'role-$role';

  @override
  Json toJson() => {'role': role};

  @override
  Params toParams() => {'role': role};
}

final orDetails = RequestDetails(
  filter: ComboFilter(
    [
      const RoleFilter('admin'),
      const RoleFilter('moderator'),
    ],
    BooleanLogic.or,
  ),
);
```

### When to use filters

Filters, like pagination and the `RequestType.allLocal` value, are only valid and allowed when calling `getItems`. You should also avoid using filters and `getItems` to load a specific set of known Ids. Instead, call `getById` or `getByIds`, which populate a `missingIds` field to clearly indicate when certain requested data could not be found.


### How filters work locally

Critically, **filters are strictly never evaluated locally.** Instead, values returned from the server are cached as belonging to the request that made them. Thus, when the exact same request is seen again (as per the cacheKey calculated by examining its optional `filter` and optional `pagination` values), the values originally returned from the server are immediately returned from a local Source.
