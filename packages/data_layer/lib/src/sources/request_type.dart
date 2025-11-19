import 'package:data_layer/data_layer.dart';

/// Classifier for a data request which tells a subtype of [DataContract] where
/// to look for the desired data.
enum RequestType {
  /// Indicator for requests which should not leave the application - aka, cache
  /// reads.
  local,

  /// Indicator for requests which must leave the application - aka, cache
  /// refreshes.
  refresh,

  /// Indicator for requests which can look anywhere and should accept the first
  /// data they find. This is typically the default [RequestType].
  global
  ;

  /// Checks whether a given [SourceType] matches this [RequestType].
  bool includes(SourceType sourceType) {
    return sourceType.map<bool>(
      local: (SourceType sourceType) =>
          this == RequestType.local || this == RequestType.global,
      remote: (SourceType sourceType) =>
          this == RequestType.refresh || this == RequestType.global,
    );
  }
}
