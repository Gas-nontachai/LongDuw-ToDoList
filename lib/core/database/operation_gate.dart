import 'dart:async';

/// A serial queue shared by writes, snapshots and notification reconciliation.
/// Nested calls in the owning async zone are safe (e.g. scheduling saves).
class OperationGate {
  final Object _zoneKey = Object();
  Future<void>? _tail;

  Future<T> run<T>(Future<T> Function() action) async {
    if (Zone.current[_zoneKey] == this) return action();
    final previous = _tail;
    final completion = Completer<void>();
    _tail = completion.future;
    try {
      if (previous != null) await previous;
      return await runZoned(action, zoneValues: {_zoneKey: this});
    } finally {
      if (identical(_tail, completion.future)) _tail = null;
      completion.complete();
    }
  }
}
