import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class PickupVerificationScreen extends ConsumerStatefulWidget {
  const PickupVerificationScreen({super.key});

  @override
  ConsumerState<PickupVerificationScreen> createState() =>
      _PickupVerificationScreenState();
}

class _PickupVerificationScreenState
    extends ConsumerState<PickupVerificationScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _validateAndNavigate(raw);
  }

  Future<void> _validateAndNavigate(String scannedBatchId) async {
    final activeBatch = ref.read(driverProvider).activeBatch;
    if (activeBatch == null || activeBatch.id != scannedBatchId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong QR code — try again.')),
        );
      }
      return;
    }
    _scanned = true;
    if (mounted) context.push('/driver/safety');
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enter Batch ID'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. batch_001'),
            onChanged: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () {
                      Navigator.of(ctx).pop();
                      _validateAndNavigate(controller.text.trim());
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = ref.watch(driverProvider).activeBatch;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Pickup')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(
                "Scan the QR code on the donor's device",
                style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: CustomPaint(
              size: const Size(220, 220),
              painter: _ReticlePainter(color: cs.primary),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (batch != null) ...[
                      _DonorInfoCard(batch: batch),
                      const SizedBox(height: Spacing.sm),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton.icon(
                        onPressed: _showManualEntry,
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: const Text(
                          'Problems scanning? Enter code manually',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorInfoCard extends StatelessWidget {
  const _DonorInfoCard({required this.batch});
  final BatchSummary batch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final desc = batch.items.isNotEmpty
        ? batch.items.first.name
        : batch.foodCategory;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.store_outlined, size: 18, color: cs.primary),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.donorName, style: textTheme.titleSmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  'EXPECTED PICKUP',
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${batch.totalPortions} portions',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        desc,
                        style: textTheme.bodySmall?.copyWith(color: cs.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 40.0;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(0, len), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.color != color;
}
