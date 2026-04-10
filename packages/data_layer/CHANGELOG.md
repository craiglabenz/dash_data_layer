# Changelog

## 0.0.5

- Adds `forceInsert` to `RequestDetails` and `Operation`.

## 0.0.4

- Fixes bug where subsequent calls to `setItems` did not clear out any items which were no longer present in the incoming list.

## 0.0.3-rc.1

- Adds watch functions for sources capable of live updates

## 0.0.2-rc.1

- Adds retries for connectivity or server issues
- Updates DataContract methods to use `Operation` instances for improved
  serialization, toward the end of saving retries

## 0.0.1-beta.9

- Restores `ReadinessMixin` to original API which involves calling `markReady`
explicitly.

## 0.0.1-beta.8

- Renames `ReadinessMixin.status` to `ReadinessMixin.readiness` to reduce
  conflicts.

## 0.0.1-beta.7

- Adds web support.

## 0.0.1-beta.6

- Initial beta version.
