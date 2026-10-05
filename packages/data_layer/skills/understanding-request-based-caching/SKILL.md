---
name: understanding-request-based-caching
description: Cached data is mapped uniquely per request hash (RequestDetails with specific filter and pagination), supporting a powerful request-based caching behavior.
metadata:
  last_modified: Sat, 18 Apr 2026 1:52:50 GMT
---

`pkg:data_layer`'s caching strategy consists of two layers to keep requests separate without duplicating the full volume of cached records. 
The first layer is a map of request hashes to the IDs of the records returned by that request. 
The second layer is a map of IDs to the actual records. 

The request hashing strategy is based on the `RequestDetails` object passed to `getItems` and uses `md5` based on `filters` and `pagination` to produce reliable hashes across application runs.

This means that a request with one set of parameters (like a filter) can never lead to a cache hit for a request with different parameters. Each unique query fetches from remote sources initially and caches the items to those distinct request hashes.

Forcing cache misses, when data is presumed stale, can be done by using `.refresh` as the `RequestType`. If you only want to know what items are available locally regardless of what requests made them, you can perform an `.allLocal` request.
