import 'dart:async';

/// {@template ConnectivityService}
/// Emits connectivity changes as a stream and future of the current status.
/// {@endtemplate}
abstract class ConnectivityService {
  /// Live updates of device connectivity.
  // ignore: avoid_positional_boolean_parameters
  StreamSubscription<bool> listen(void Function(bool) fn);

  /// Current device connectivity status.
  Future<bool> get isConnected;
}

/// Signal that the device is offline.
class NoConnectivityException implements Exception {}
