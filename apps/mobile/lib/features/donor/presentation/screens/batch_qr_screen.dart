import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class BatchQrScreen extends StatelessWidget {
  const BatchQrScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Batch QR Code')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show this QR code to the driver at pickup',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: QrImageView(
                  data: batchId,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                batchId,
                style: textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
