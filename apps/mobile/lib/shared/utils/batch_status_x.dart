import 'package:saveameal/shared/domain/entities/batch_status.dart';

extension BatchStatusX on BatchStatus {
  /// Short pill label — used everywhere a status chip/badge is shown.
  String get label => switch (this) {
    BatchStatus.open => 'Pending',
    BatchStatus.claimed => 'Claimed',
    BatchStatus.pickedUp => 'Collected',
    BatchStatus.delivered => 'Delivered',
    BatchStatus.closed => 'Completed',
    BatchStatus.cancelled => 'Cancelled',
  };

  /// Whether the batch is still active (not finished or cancelled).
  bool get isActive => switch (this) {
    BatchStatus.open || BatchStatus.claimed || BatchStatus.pickedUp => true,
    _ => false,
  };

  /// Whether the batch has finished successfully.
  bool get isDone =>
      this == BatchStatus.delivered || this == BatchStatus.closed;
}
