# Changelog

## 0.0.4

- Improves handling of schema changes by wrapping all reads in a try-catch and evicting keys that fail to deserialize.

## 0.0.3

- Updates `sendMessage` return type from `T` to `T?`.

## 0.0.2-rc.1

- Adds HiveOperationPersistence to support long-lived storage of retries.

## 0.0.1-beta.7

- Bumps to latest data_layer version and calls `markReady`.

## 0.0.1-beta.6

- Adds web support.

## 0.0.1-beta.5

- Initial version.
