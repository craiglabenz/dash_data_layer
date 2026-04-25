---
name: paginating-reads
description: Paginating reads relies on passing a Pagination object to a RequestDetails and having a remote Source which correctly applies its values to the network request.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

Paginating reads relies on configuring a RequestDetails object with a Pagination object and having a remote Source which correctly applies its values to the network request.

```dart
final details = RequestDetails(
  pagination: Pagination.page(1, pageSize: 10),
);

// Load the first 10 users
final list = await userRepository.getItems(details);
```

### Page vs Cursor-based pagination

Page-based pagination, or pure limit-offset pagination, can be activated by using the `Pagination.page()` convenience constructor.

Cursor-based pagination, or "start from here" pagination, can be activated by using the `Pagination.cursor()` convenience constructor.

In both scenarios, it is up to the remote Source to correctly apply this to the network request, and for the actual API at the end of the line to honor the pagination request.