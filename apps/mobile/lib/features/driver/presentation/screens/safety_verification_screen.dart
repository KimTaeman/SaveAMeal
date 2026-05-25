import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

const _checklistItems = [
  'Food is stored in clean, food-grade containers',
  'Temperature-sensitive items are in thermal bags',
  'Vehicle storage area is clean and clear of contaminants',
];

class SafetyVerificationScreen extends ConsumerStatefulWidget {
  const SafetyVerificationScreen({super.key});

  @override
  ConsumerState<SafetyVerificationScreen> createState() =>
      _SafetyVerificationScreenState();
}

class _SafetyVerificationScreenState
    extends ConsumerState<SafetyVerificationScreen> {
  final List<bool> _checked = List.filled(3, false);
  String? _photoPath;
  bool _loading = false;

  bool get _canConfirm =>
      _checked.every((v) => v) && _photoPath != null && !_loading;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
      final batch = await ref.read(activeBatchForDriverProvider(uid).future);
      if (batch == null) return;
      await ref
          .read(driverProvider.notifier)
          .confirmPickup(batch.id, _photoPath!);
      if (mounted) context.go('/driver/rescue');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety Verification')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Pickup Checklist', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Please verify the following safety standards before confirming pickup.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          ...List.generate(
            _checklistItems.length,
            (i) => CheckboxListTile(
              title: Text(_checklistItems[i]),
              value: _checked[i],
              onChanged: (v) => setState(() => _checked[i] = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Icon(Icons.photo_camera, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Photo Confirmation', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Upload a clear photo of the loaded food items to document the pickup.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: cs.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(_photoPath!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: cs.primary, size: 32),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'Upload Pickup Photo',
                          style: textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                        Text(
                          'Tap to select or take photo',
                          style: textTheme.bodySmall,
                        ),
                      ],
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
                : const Text('Confirm & Complete Pickup'),
          ),
        ),
      ),
    );
  }
}
