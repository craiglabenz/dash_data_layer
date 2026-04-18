import 'package:data_layer/data_layer.dart';

/// {@template MessagePayload}
/// A wrapper object used to safely pass a strongly-typed generic [message] 
/// alongside its [bindings] through the `dash_data_layer` operation engine, 
/// avoiding the limitations of Dart generic factory properties on Freezed
/// untyped objects.
/// {@endtemplate}
class MessagePayload<M> {
  /// {@macro MessagePayload}
  const MessagePayload(this.message, this.bindings);

  /// The underlying message object.
  final M message;

  /// The bindings used to serialize/deserialize this message type.
  final Bindings<M> bindings;

  /// Serializes the generic [message] into JSON suitable for APIs.
  Json toJson() => bindings.toJson(message);
}
