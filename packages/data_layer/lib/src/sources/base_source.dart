import 'package:data_layer/data_layer.dart';

/// {@template Source}
/// Parent type of all entries in a [SourceList]. Each [Source] subtype should
/// know how to load data from a particular place. The field [sourceType]
/// indicates whether that place is immediately accessible (and thus is a cache)
/// or is remotely accessible and thus is the source of truth.
/// {@endtemplate }
abstract class Source<T> extends DataContract<T> {
  /// {@macro Source}
  Source({Bindings<T>? bindings}) : _bindings = bindings;

  /// Indicator for whether this [Source] loads data from a store on-device, or
  /// off-device.
  SourceType get sourceType;

  @override
  String toString() => '$runtimeType()';

  /// All meta information about [T] necessary to plug arbitrary data types
  /// into a [Repository].
  Bindings<T> get bindings {
    assert(
      _bindings != null,
      'You must either pass a Bindings object to the constructor or set it '
      'later, which the SourceList does automatically.',
    );
    return _bindings!;
  }

  // Registers bindings for this [Source]. Probably invoked by the [SourceList].
  set bindings(Bindings<T> val) => _bindings = val;

  Bindings<T>? _bindings;

  /// Proxy getter for whether [bindings] has been initialized, either by being
  /// passed in via this constructor or by being set by the [SourceList].
  bool get hasBindings => _bindings != null;
}

/// Classifier for a given [Source] instance's primary data location.
enum SourceType {
  /// Indicates a given [Source] retrieves its data from an on-device store.
  local,

  /// Indicates a given [Source] retrieves its data from an off-device store.
  remote
  ;

  /// Accepts a handler for each [SourceType] variant and runs the appropriate
  /// handler for which flavor this instance is.
  T map<T>({
    required T Function(SourceType) local,
    required T Function(SourceType) remote,
  }) {
    return switch (this) {
      SourceType.local => local(this),
      SourceType.remote => remote(this),
    };
  }
}
