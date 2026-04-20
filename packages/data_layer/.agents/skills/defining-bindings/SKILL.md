---
name: defining-bindings
description: Bindings define the serialization and request networking footprint for your specific data model.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

```dart
final userBindings = Bindings<User>(
  fromJson: User.fromJson,
  toJson: (user) => user.toJson(),
  getId: (user) => user.id,
);
```
