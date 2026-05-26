import 'package:flutter/material.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';

class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onScanQr,
    required this.onTap,
  });

  final IntakeRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onScanQr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // TODO: implement
    // Show batch details: mealDescription, portions, weightKg.
    // If status == pending:  show 'Accept Job' button (calls onAccept).
    // If status == dispatched and volunteerId == currentUser: show 'Scan QR' button (calls onScanQr).
    // Tap card → onTap (navigates to DeliveryDetailScreen read-only view).
    // No hardcoded colors or text styles.
    return const Placeholder(fallbackHeight: 80);
  }
}
