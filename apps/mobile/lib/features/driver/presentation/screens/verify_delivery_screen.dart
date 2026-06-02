import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

const _handoverItems = [
  'Food batch handed over securely to shelter staff',
  'Shelter staff confirmed item quantities match',
];

class VerifyDeliveryScreen extends ConsumerStatefulWidget {
  const VerifyDeliveryScreen({super.key});

  @override
  ConsumerState<VerifyDeliveryScreen> createState() =>
      _VerifyDeliveryScreenState();
}

class _VerifyDeliveryScreenState extends ConsumerState<VerifyDeliveryScreen> {
  final List<bool> _checked = List.filled(2, false);
  final TextEditingController _notesController = TextEditingController();
  bool _loading = false;

  bool get _canConfirm => _checked.every((v) => v) && !_loading;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
      final batch = await ref.read(activeBatchForDriverProvider(uid).future);
      if (batch == null) return;
      final notes = _notesController.text.trim();
      await ref
          .read(driverProvider.notifier)
          .confirmDelivery(batch.id, notes.isEmpty ? null : notes);
      if (mounted) context.push('/driver/completed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Handover Verification', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ...List.generate(
            _handoverItems.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: CheckboxListTile(
                title: Text(_handoverItems[i]),
                value: _checked[i],
                onChanged: (v) => setState(() => _checked[i] = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('NOTES OR FEEDBACK (OPTIONAL)', style: textTheme.labelSmall),
          const SizedBox(height: Spacing.xs),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'E.g., Storage location, specific staff member name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton(
            onPressed: _canConfirm ? _confirm : null,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Delivery Completion'),
          ),
        ),
      ),
    );
  }
}
