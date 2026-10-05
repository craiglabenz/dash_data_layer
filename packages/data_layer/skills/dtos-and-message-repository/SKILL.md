---
name: dtos-and-message-repository
description: Use a MessageRepository to define a special DTO class for your writes.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

Use a MessageRepository to define a special DTO class for your writes.

```dart
final repository = MessageRepository<MyClass, MessageClass>(
  sourceList,
  messageBindings: MessageClass.bindings,
);
```

Non-DTO methods in `pkg:data_layer` all accept the same object as they return. For example, `setItem` accepts a `T` and later returns a `T`. MessageRepositories behave the same way for all of the typical methods, but introduce an additional method, `sendMessage`, which accepts an `M` and later returns a `T`.

### Defining a DTO / message class

DTOs allow you to increase type safety everywhere across your application.

For example, the typical scenario of a server-set `id` can often require a nullable `id` field everywhere, despite almost all instances of that data type having a non-null `id`. This effect carries for all server-set fields, like `createdAt`, or similar.

Similarly, the client can easily write code to modify fields which the server considers immutable, leading to undefined behavior where a client may think it has performed a write but the server ignored it by only considering mutable fields.

In `pkg:data_layer`, a simple but effective pattern is to use a single `pkg:freezed` class for the fully-formed model and a separate freezed union class for all message types.

```dart
/// Class to represent fully-formed instances of the `BlogPost` data type which
/// have already been saved to the database and thus have all of their server-assigned
/// values in place.
@freezed
abstract class BlogPost with _$BlogPost {
  const factory BlogPost({
    required String id,
    required String title,
    required String body,
    required String authorId,
    required DateTime createdAt,
  }) = _BlogPost;

  factory BlogPost.fromJson(Map<String, dynamic> json) =>
      _$BlogPostFromJson(json);
}


/// Class to represent partial instances of the `BlogPost` data type which
/// have either not yet been saved or are indicators of targeted updates.
@freezed
sealed class BlogPostDTO with _$BlogPostDTO {
  // Only accepts fields the client controls
  const factory BlogPostDTO.create({
    required String title,
    required String body,
    required String authorId,
  }) = CreateBlogPost;

  // Only accepts fields the client can modify.
  const factory BlogPostDTO.update({
    String? title,
    String? body,
  }) = UpdateBlogPost;

  factory BlogPostDTO.fromJson(Map<String, dynamic> json) =>
      _$BlogPostDTOFromJson(json);
}
```

Then, define a `MessageRepository` and call its `sendMessage` method.

```dart
final blogPostRepository = MessageRepository<BlogPost, BlogPostDTO>();
final BlogPost savedBlogPost = blogPostRepository.setItem(
  CreateBlogPost(
    title: 'How to use the Data Layer package',
    body: 'TODO: write blog post',
  ),
);

final BlogPost updatedBlogPost = await blogPostRepository.sendMessage(
  UpdateBlogPost(body: '<lots of riveting documentation>'),
  targetId: savedBlogPost.id,
);
```

### What about DTOs for reads?

DTOs can also be a great idea for reads; but are not typically appropriate to expose to Data Layer repositories. The reason for this is that read-based DTOs are a server-side abstraction to separate specific database table definitions from what data is actually returned to clients; and in that scenario, Data Layer repositories are only ever aware of the DTO that is returned to them from all reads.