---
name: defining-a-repository
description: Repositories are simple wrappers around SourceLists plus custom business logic.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

## Why do Repositories exist?

Defining a `Repository<T>` often amounts to defining a `SourceList<T>`. However, this begs the question: __Why does the Repository class exist?__

The answer to this question is two-fold.

First, Repositories are the public-facing utility in `pkg:data_layer`, exposing a simpler API with simpler parameters. Specifically, the inner `Operation` construct is hidden from developers by the `Repository`, which creates one for the `SourceList` for each data request.

Second, Repositories are where you should place any custom business logic which does not neatly fall into one of the core `DataContract` methods.

## Defining a repository

### Creating a dedicated subclass

One way to define a repository is to create a dedicated subclass for your specific data type. This is useful when you want to hide the constructor complexity from external consumers, or when you want custom business logic.

```dart
class UserRepository extends Repository<User> {
  UserRepository() : super(
    SourceList<User>(...),
  );

  Future<Result<User>> getByEmail(String email) async {
    return getItems(
      details: RequestDetails(filter: EmailFilter(email)),
    );
  }
}
```

### Directly instantiating a Repository

The second way to define a repository is to directly instantiate what you need. This works well for simple cases where you don't need custom business logic.

```dart
final userRepository = Repository<User>(
  SourceList<User>(...),
);
```

### Scope of a Repository

Repositories should all be singletons, completely owning the reading and writing of that data type across your entire application. `pkg:data_layer`'s request-based caching will prevent the same Repository from cross-contaminating data when used in different corners of your application.

