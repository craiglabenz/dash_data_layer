---
name: understanding-source-list
description: The SourceList class manages the delegation of read/write attempts to various configured Sources, with a read-thru cache system prioritizing local Sources.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT
---

The `SourceList` class manages juggling data between an arbitrary list of `Source` objects. It serves as a request-based read-thru and write-thru cache.

The list of sources requires local sources to precede remote sources. When a `global` read is initiated, the `SourceList` queries the first local source. If data is matched and found, it is immediately returned and remote sources are not contacted. If the data is absent locally, it cascades to remote sources. Responses from remote sources are gracefully written back to preceding local sources for potential cache-hits in future identical requests.

When an item is written via `setItem`, it will send it to remote sources (such as an API to generate an ID) and then automatically persist the fully formed response in local caches.

You can configure a `RetryPolicy` and `ConnectivityService` directly on your `SourceList` to elegantly handle API failures and queue them until connection re-establishes.
