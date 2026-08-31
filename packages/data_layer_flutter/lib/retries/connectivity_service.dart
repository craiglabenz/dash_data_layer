import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_layer/data_layer.dart' show ConnectivityService;

/// {@macro ConnectivityService}
///
/// Relies on `pkg:connectivity_plus` for connectivity detection.
class ConnectivityPlusStream extends ConnectivityService {
  /// Creates an instance of [ConnectivityPlusStream].
  ConnectivityPlusStream({
    this.allowedConnectivityResults = const <ConnectivityResult>{
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
    },
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    _controller = StreamController<bool>.broadcast();

    unawaited(
      _connectivity.checkConnectivity().then(_handleConnectivityChanged),
    );
  }

  /// pkg:connectivity_plus resource.
  final Connectivity _connectivity;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  /// Not all connectivity modes are created equally. Which modes amount to
  /// connectivity for your purposes is configurable.
  final Set<ConnectivityResult> allowedConnectivityResults;

  late final StreamController<bool> _controller;

  Completer<bool>? _completer;

  bool? _isConnected;

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final bool? previousIsConnected = _isConnected;
    if (results.toSet().intersection(allowedConnectivityResults).isNotEmpty) {
      _isConnected = true;
    } else {
      _isConnected = false;
    }
    if (previousIsConnected != _isConnected) {
      _controller.add(_isConnected!);
    }
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(_isConnected!);
    }
  }

  @override
  StreamSubscription<bool> listen(void Function(bool) fn) {
    final sub = _controller.stream.listen(fn);
    if (_isConnected != null) {
      fn(_isConnected!);
    }
    return sub;
  }

  @override
  Future<bool> get isConnected {
    if (_isConnected == null) {
      _completer ??= Completer<bool>();
      return _completer!.future;
    }
    return Future.value(_isConnected!);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    unawaited(_connectivitySub.cancel());
  }
}
