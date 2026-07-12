import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/orders/data/repositories/api_order_repository.dart';
import 'package:restaurantos/features/orders/domain/entities/dining_session.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/order_history_entry.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';

// ── Active Sessions Feed (owner dashboard) ────────────────────────────────────

final activeSessionsProvider = StateNotifierProvider<
    ActiveSessionsNotifier, AsyncValue<List<DiningSession>>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return ActiveSessionsNotifier(repo);
});

class ActiveSessionsNotifier
    extends StateNotifier<AsyncValue<List<DiningSession>>> {
  final dynamic _repo;

  ActiveSessionsNotifier(this._repo) : super(const AsyncLoading()) {
    fetchSessions();
    ApiOrderRepository.addListener(fetchSessions);
  }

  @override
  void dispose() {
    ApiOrderRepository.removeListener(fetchSessions);
    super.dispose();
  }

  Future<void> fetchSessions() async {
    final result = await _repo.getSessionsForOwner('rest_456');
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (sessions) => state = AsyncValue.data(sessions as List<DiningSession>),
    );
  }
}

// ── Master Order for a specific Session ──────────────────────────────────────

final masterOrderProvider = FutureProvider.family<OrderEntity?, String>(
  (ref, sessionId) async {
    final repo = ref.watch(orderRepositoryProvider);
    final result = await repo.getMasterOrderForSession(sessionId);
    return result.fold((_) => null, (order) => order);
  },
);

// ── Order History for a Session ───────────────────────────────────────────────

final sessionHistoryProvider =
    FutureProvider.family<List<OrderHistoryEntry>, String>(
  (ref, sessionId) async {
    final repo = ref.watch(orderRepositoryProvider);
    final result = await repo.getOrderHistoryForSession(sessionId);
    return result.fold((_) => [], (history) => history);
  },
);

// ── Active Customer Session ───────────────────────────────────────────────────

final customerActiveSessionProvider =
    StateNotifierProvider<CustomerSessionNotifier, DiningSession?>(
        (ref) => CustomerSessionNotifier(ref));

class CustomerSessionNotifier extends StateNotifier<DiningSession?> {
  final Ref _ref;

  CustomerSessionNotifier(this._ref) : super(null) {
    ApiOrderRepository.addListener(_refresh);
  }

  @override
  void dispose() {
    ApiOrderRepository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    // Re-read from repository if we have a session
    if (state != null) {
      loadSession(state!.sessionId);
    }
  }

  Future<void> loadSession(String sessionId) async {
    final repo = _ref.read(orderRepositoryProvider);
    final result = await repo.getSessionsForOwner('rest_456');
    result.fold(
      (_) {},
      (sessions) {
        final found = (sessions as List<DiningSession>).cast<DiningSession?>().firstWhere(
              (s) => s?.sessionId == sessionId,
              orElse: () => null,
            );
        if (found != null) state = found;
      },
    );
  }

  void setSession(DiningSession session) => state = session;
  void clearSession() => state = null;
}
