import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/beneficiary/data/models/recent_delivery_cache_entry.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/fetch_delivery_history_page_usecase.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';

part 'delivery_history_notifier.g.dart';

/// Immutable state for [DeliveryHistoryNotifier].
class DeliveryHistoryState {
  const DeliveryHistoryState({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    this.loadMoreError,
    this.cursor,
  });

  final List<RecentDelivery> items;
  final bool hasMore;

  /// True only while a subsequent page load is in flight (not the initial load).
  final bool isLoadingMore;

  /// Non-null when a [loadNextPage] call failed; the previous items are retained.
  final Object? loadMoreError;

  /// Opaque Firestore DocumentSnapshot cursor; null on first page.
  final Object? cursor;

  DeliveryHistoryState copyWith({
    List<RecentDelivery>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
    Object? cursor,
  }) => DeliveryHistoryState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: loadMoreError,
    cursor: cursor ?? this.cursor,
  );

  static const empty = DeliveryHistoryState(
    items: [],
    hasMore: true,
    isLoadingMore: false,
  );
}

/// Family notifier keyed by [beneficiaryId].
/// On first build: loads the Hive page cache, then fires the first network page.
/// Call [loadNextPage] to append the next page; [refresh] to clear cache and reload.
@riverpod
class DeliveryHistoryNotifier extends _$DeliveryHistoryNotifier {
  int _nextPageIndex = 0;

  @override
  Future<DeliveryHistoryState> build(String beneficiaryId) async {
    _nextPageIndex = 0;

    // 1. Read Hive cache — all keys matching '${beneficiaryId}_page_*'
    final box = Hive.box<String>('delivery_history_cache');
    final cached = <RecentDelivery>[];
    var idx = 0;
    while (true) {
      final raw = box.get('${beneficiaryId}_page_$idx');
      if (raw == null) break;
      final list = (jsonDecode(raw) as List)
          .map(
            (e) => RecentDeliveryCacheEntry.fromJson(
              e as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
      cached.addAll(list);
      idx++;
    }

    // 2. Fire first network page regardless (to get fresh data / cursor)
    final useCase = ref.read(fetchDeliveryHistoryPageUseCaseProvider);
    try {
      final page = await useCase(beneficiaryId: beneficiaryId);
      _writePageToCache(beneficiaryId, 0, page.items, box);
      _nextPageIndex = 1;
      return DeliveryHistoryState(
        items: page.items,
        hasMore: page.hasMore,
        isLoadingMore: false,
        cursor: page.nextCursor,
      );
    } catch (e) {
      if (cached.isNotEmpty) {
        // Serve cache on network error — hasMore: true signals offline mode
        return DeliveryHistoryState(
          items: cached,
          hasMore: true,
          isLoadingMore: false,
        );
      }
      rethrow;
    }
  }

  /// Loads the next page. No-op if [hasMore] is false or a load is in progress.
  Future<void> loadNextPage() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreError: null),
    );

    try {
      final useCase = ref.read(fetchDeliveryHistoryPageUseCaseProvider);
      final page = await useCase(
        beneficiaryId: beneficiaryId,
        cursor: current.cursor,
      );
      final box = Hive.box<String>('delivery_history_cache');
      _writePageToCache(beneficiaryId, _nextPageIndex, page.items, box);
      _nextPageIndex++;
      state = AsyncData(
        DeliveryHistoryState(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          isLoadingMore: false,
          cursor: page.nextCursor,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: e),
      );
    }
  }

  /// Clears the Hive cache for this beneficiary and reloads from page 0.
  Future<void> refresh() async {
    // Capture all ref-dependent values before any state mutation or awaits,
    // because setting state or awaiting may cause this provider to be disposed
    // in autoDispose mode (Riverpod 3.x).
    final useCase = ref.read(fetchDeliveryHistoryPageUseCaseProvider);
    final capturedBeneficiaryId = beneficiaryId;
    _nextPageIndex = 0;

    // Clear cache synchronously first (box.delete is async but box is not ref-dependent).
    final box = Hive.box<String>('delivery_history_cache');
    final keysToDelete = box.keys
        .whereType<String>()
        .where((k) => k.startsWith('${capturedBeneficiaryId}_page_'))
        .toList();
    for (final key in keysToDelete) {
      await box.delete(key);
    }

    // Set loading state after cache is cleared.
    state = const AsyncLoading();

    // Re-fetch from page 0.
    try {
      final page = await useCase(beneficiaryId: capturedBeneficiaryId);
      _writePageToCache(capturedBeneficiaryId, 0, page.items, box);
      _nextPageIndex = 1;
      state = AsyncData(
        DeliveryHistoryState(
          items: page.items,
          hasMore: page.hasMore,
          isLoadingMore: false,
          cursor: page.nextCursor,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _writePageToCache(
    String beneficiaryId,
    int pageIdx,
    List<RecentDelivery> items,
    Box<String> box,
  ) {
    final entries = items
        .map(
          (d) => RecentDeliveryCacheEntry(
            batchId: d.batchId,
            deliveredAtMs: d.deliveredAt.millisecondsSinceEpoch,
            portions: d.portions,
            donorName: d.donorName,
            category: d.category,
          ).toJson(),
        )
        .toList();
    box.put('${beneficiaryId}_page_$pageIdx', jsonEncode(entries));
  }
}

/// Convenience provider — wires [FetchDeliveryHistoryPageUseCase] to the repository.
@riverpod
FetchDeliveryHistoryPageUseCase fetchDeliveryHistoryPageUseCase(Ref ref) =>
    FetchDeliveryHistoryPageUseCase(ref.watch(intakeRepositoryProvider));
