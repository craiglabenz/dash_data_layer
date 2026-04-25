---
name: retries-offline-queuing
description: SourceLists can be configured to store failed Operations for later retry if a `RetryPolicy` is supplied.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT

---

SourceLists can be configured to store failed Operations for later retry if a `RetryPolicy` is supplied. 

```dart
final retryPolicy = DefaultRetryPolicy(
  readsPersistence: InMemoryOperationPersistence(),
  writesPersistence: HiveOperationPersistence(),
  maxRetries: 3,
);

final sourceList = SourceList<MyObject>(
  sources: <Source<MyObject>>[...],
  retryPolicy: retryPolicy,
);

```

### What operations are retried

You can define a `RetryPolicy` to make any retry decisions you wish; but the following rules are captured in `DefaultRetryPolicy`:

1. Errors believed to be the client's fault (e.g., a `400 Bad Request`), are not retried as there is no reason to believe a subsequent attempt will fare any better.
2. Errors believed to be the server's fault (e.g., a `503 Service Unavailable`) are scheduled to be retried via exponential backoff, up to `maxRetries` attempts.
3. Errors believed to be the fault of network connectivity are saved for immediate retry upon network restoration. This depends on a configured `SourceList.connectivityService`, of which one is available in the `pkg:data_layer_flutter` package.

### When retries are abandoned

Retries are made up until `maxRetries` is reached for a given Operation. For operations that are critical, simply set `maxRetries` to null and `pkg:data_layer` will hold on to those Operations indefinitely, continuously trying to write them to the server until success is achieved. If retrying a critical Operation indefinitely, consider setting a `maxWait` time on the `RetryPolicy` to avoid unbounded delays. Something like 5 minutes should be suitable for most scenarios to continuously retry without hammering your server.

### Retrying reads

The default `RetryPolicy` object, as captured in `DefaultRetryPolicy`, will hold on to read requests *in memory*, retrying the requests as appropriate. This decision is based on the assumption that, once a user closes and re-opens your app, any desired reads will naturally be attempted again without requiring memory of failed reads during previous application launches. If this assumption is not suitable for your application, you should use a durable persistence provider for reads, instead.

### Retrying writes

The default `RetryPolicy` object, as captured in `DefaultRetryPolicy`, persists failed write operations in a durable storage provider (out of `pkg:data_layer_hive`) for long-lived retry attempts.

### Retrying best practices

Retrying writes can turn destructive when updating existing records. For example, imagine a full-record UPDATE which only intends to modify 1 column but, while sitting in retry purgatory, contains stale values which could overwrite other updates which happen in the meanwhile.

To avoid this problem, consider using a `MessageRepository` and DTOs to keep writes as targeted as possible.