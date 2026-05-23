import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';

part 'batch_session_provider.g.dart';

@Riverpod(keepAlive: true)
class BatchSession extends _$BatchSession {
  @override
  List<BatchItem> build() => [];

  void add(BatchItem item) => state = [...state, item];

  void remove(int index) {
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  void clear() => state = [];
}
