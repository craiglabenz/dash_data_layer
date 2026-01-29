// ignore_for_file: avoid_positional_boolean_parameters
import 'dart:async';

import 'package:meta/meta.dart';

/// {@template ConnectivityService}
/// Emits connectivity changes as a stream and future of the current status.
/// {@endtemplate}
abstract class ConnectivityService {
  /// Live updates of device connectivity.
  StreamSubscription<bool> listen(void Function(bool) fn);

  /// Current device connectivity status.
  Future<bool> get isConnected;

  /// Closes all resources.
  void dispose();
}

/// Signal that the device is offline.
class NoConnectivityException implements Exception {}

/// {@template FakeConnectivityService}
/// Testing-friendly fake of [ConnectivityService].
/// {@endtemplate}
final class FakeConnectivityService extends ConnectivityService {
  /// {@macro FakeConnectivityService}
  FakeConnectivityService([bool? initialValue])
    : _lastConnectivityUpdate = initialValue;

  @override
  Future<bool> get isConnected => Future.value(_lastConnectivityUpdate);

  final StreamController<bool> _connectivityUpdatesController =
      StreamController<bool>.broadcast();

  bool? _lastConnectivityUpdate;

  /// Publishes a synthetic connectivity value to any listeners. Testing-only.
  @visibleForTesting
  void setConnectivity(bool val) {
    _lastConnectivityUpdate = val;
    _connectivityUpdatesController.add(val);
  }

  @override
  StreamSubscription<bool> listen(void Function(bool) fn) {
    if (_lastConnectivityUpdate != null) {
      fn(_lastConnectivityUpdate!);
    }
    return _connectivityUpdatesController.stream.listen(fn);
  }

  @override
  void dispose() => _connectivityUpdatesController.close();
}
