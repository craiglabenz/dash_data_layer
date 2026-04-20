---
name: structuring-source-list
description: SourceLists should be defined with Sources sorted by immediacy; with on-device Sources appearing first and remote, API-based Sources appearing last. Often, 1 local Source and 1 remote Source is all that will appear in a SourceList.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

SourceLists should be defined with Sources sorted by immediacy; with on-device Sources appearing first and remote, API-based Sources appearing last. Often, 1 local Source and 1 remote Source is all that will appear in a SourceList.

As a rule of thumb: **Local Sources must precede remote Sources.**

```dart
SourceList<User>(
    bindings: userBindings,
    sources: [
      InMemoryLocalSource(), // First chance retrieval (Synchronous cache memory)
      HiveSource(), // Secondary storage fallback (Disk persistence)
      RestSource(), // Utmost fallback (Network bound query)
    ],
)
```

Inverting this source order is invalid and will result in an AssertionError being thrown.
