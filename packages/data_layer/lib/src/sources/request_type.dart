import 'package:data_layer/data_layer.dart';

/// Classifier for a data request which tells a subtype of [DataContract] where
/// to look for the desired data.
enum RequestType {
  /// Requests which should read all locally available records and not consider
  /// request caches. Only valid when passed to the [DataContract.getItems]
  /// method.
  allLocal,

  /// Requests which should not leave the application - aka, cache reads. These
  /// requests will only be given to [SourceType.local] sources.
  local,

  /// Requests which must leave the application - aka, cache refreshes. These
  /// requests skip [SourceType.local] sources when reading, but then do still
  /// cache that value to any skipped local sources.
  refresh,

  /// Requests which can look anywhere and should accept the first data they
  /// find. This is typically the default [RequestType]. Local cache hits are
  /// immediately returned and any server-loaded data is cached to any local
  /// sources.
  global;

  /// Checks whether a given [SourceType] matches this [RequestType].
  bool includes(SourceType sourceType) {
    return sourceType.map<bool>(
      local: (sourceType) =>
          this == RequestType.local ||
          this == RequestType.allLocal ||
          this == RequestType.global,
      remote: (sourceType) =>
          this == RequestType.refresh || this == RequestType.global,
    );
  }
}
