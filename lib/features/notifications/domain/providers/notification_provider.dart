import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_provider.dart';
import '../../data/notification_repository.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

class NotificationsState {
  final List<NotificationModel> items;
  final int unreadCount;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  NotificationsState copyWith({
    List<NotificationModel>? items,
    int? unreadCount,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationsState> build() async {
    final page = await _repo.fetch();

    return NotificationsState(
      items: page.items,
      unreadCount: page.unreadCount,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final page = await _repo.fetch();

      return NotificationsState(
        items: page.items,
        unreadCount: page.unreadCount,
        currentPage: page.currentPage,
        lastPage: page.lastPage,
      );
    });
  }

  /// Keyingi sahifani yuklaydi va mavjud ro'yxat ustiga qo'shadi.
  Future<void> loadMore() async {
    final current = state.asData?.value;

    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await _repo.fetch(page: current.currentPage + 1);

      state = AsyncData(current.copyWith(
        items: [...current.items, ...page.items],
        unreadCount: page.unreadCount,
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Ro'yxatni darhol yangilaydi (optimistik), so'ng serverga yozadi.
  Future<void> markRead(String id) async {
    final current = state.asData?.value;

    if (current == null) return;

    final target = current.items.where((n) => n.id == id).firstOrNull;

    if (target == null || target.isRead) return;

    state = AsyncData(current.copyWith(
      items: current.items
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
      unreadCount: (current.unreadCount - 1).clamp(0, 1 << 30),
    ));

    try {
      final unread = await _repo.markRead(id);
      final latest = state.asData?.value;

      if (latest != null) {
        state = AsyncData(latest.copyWith(unreadCount: unread));
      }
    } catch (_) {
      // Server rad etsa haqiqiy holatga qaytamiz.
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    final current = state.asData?.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(
      items: current.items.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    ));

    try {
      await _repo.markAllRead();
    } catch (_) {
      await refresh();
    }
  }

  Future<void> delete(String id) async {
    final current = state.asData?.value;

    if (current == null) return;

    final removed = current.items.where((n) => n.id == id).firstOrNull;

    state = AsyncData(current.copyWith(
      items: current.items.where((n) => n.id != id).toList(),
      unreadCount: removed != null && !removed.isRead
          ? (current.unreadCount - 1).clamp(0, 1 << 30)
          : current.unreadCount,
    ));

    try {
      await _repo.delete(id);
    } catch (_) {
      await refresh();
    }
  }
}

/// Profil menyusidagi belgi uchun — ro'yxatni yuklamasdan faqat son.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  // Ro'yxat ochilgan bo'lsa undagi son ishlatiladi — ortiqcha so'rov bo'lmaydi.
  final listed = ref.watch(notificationsProvider).asData?.value;

  if (listed != null) return listed.unreadCount;

  return ref.read(notificationRepositoryProvider).unreadCount();
});

final notificationPreferencesProvider = AsyncNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() {
    return ref.read(notificationRepositoryProvider).getPreferences();
  }

  /// Tugmani darhol o'zgartiradi, so'ng serverga yozadi.
  Future<void> setEnabled(bool value) async {
    final current = state.asData?.value;

    if (current == null) return;

    state = AsyncData(current.copyWith(enabled: value));

    try {
      final updated = await ref
          .read(notificationRepositoryProvider)
          .updatePreferences({'enabled': value});
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}
