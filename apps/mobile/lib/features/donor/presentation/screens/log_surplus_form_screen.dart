import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/batch_session_provider.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class LogSurplusFormScreen extends ConsumerStatefulWidget {
  const LogSurplusFormScreen({
    super.key,
    this.prefillBarcode,
    this.prefillName,
  });

  final String? prefillBarcode;
  final String? prefillName;

  @override
  ConsumerState<LogSurplusFormScreen> createState() =>
      _LogSurplusFormScreenState();
}

class _LogSurplusFormScreenState extends ConsumerState<LogSurplusFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  FoodCategory? _category;
  Beneficiary? _beneficiary;
  DateTime? _expiryTime;
  XFile? _photo;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    final now = DateTime.now();
    var expiry = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (expiry.isBefore(now)) expiry = expiry.add(const Duration(days: 1));
    setState(() {
      _expiryTime = expiry;
      _expiryController.text = picked.format(context);
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _photo = file);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final item = BatchItem(
      name: _nameController.text.trim(),
      category: _category!,
      weightKg: double.parse(_quantityController.text.trim()),
      expiryTime: _expiryTime!,
      localPhotoPath: _photo?.path,
    );
    ref.read(batchSessionProvider.notifier).add(item);
    ref.read(batchBeneficiaryProvider.notifier).set(_beneficiary);
    context.push('/donor/log/summary');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final beneficiariesAsync = ref.watch(beneficiariesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: Spacing.xs),
            Text(
              'SaveAMeal',
              style: textTheme.titleLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Text(
              'Log Surplus',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Add details for a new batch of surplus food.',
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.lg),
            _fieldLabel(context, 'Product Name'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Mixed Bakery Goods',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Spacing.md),
            _fieldLabel(context, 'Category'),
            DropdownButtonFormField<FoodCategory>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: const InputDecoration(hintText: 'Select category'),
              items: FoodCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(_categoryLabel(c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: Spacing.md),
            _fieldLabel(context, 'Quantity (kg)'),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: '0.0'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: Spacing.md),
            _fieldLabel(context, 'Expiry Time'),
            TextFormField(
              controller: _expiryController,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: '--:-- --',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: _pickExpiry,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (_expiryTime == null ||
                    _expiryTime!.isBefore(DateTime.now())) {
                  return 'Expiry time must be in the future';
                }
                return null;
              },
            ),
            const SizedBox(height: Spacing.md),
            _fieldLabel(
              context,
              'Assign Destination / Beneficiary',
              color: cs.onSurfaceVariant,
            ),
            beneficiariesAsync.when(
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Beneficiary>(
                    // ignore: deprecated_member_use
                    value: _beneficiary,
                    decoration: const InputDecoration(
                      hintText: 'Select destination',
                    ),
                    items: items
                        .map(
                          (b) =>
                              DropdownMenuItem(value: b, child: Text(b.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _beneficiary = v),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    _beneficiary?.address ?? 'Details of destination...',
                    style: textTheme.bodySmall?.copyWith(color: ac.warning),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Could not load beneficiaries',
                style: textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ),
            const SizedBox(height: Spacing.md),
            _fieldLabel(context, 'Photo (optional)'),
            _PhotoPicker(photo: _photo, onTap: _pickPhoto),
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: const StadiumBorder(),
              ),
              child: const Text('Add to Batch'),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xs),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );

  String _categoryLabel(FoodCategory c) => switch (c) {
    FoodCategory.bakery => 'Bakery',
    FoodCategory.produce => 'Produce',
    FoodCategory.dairy => 'Dairy',
    FoodCategory.meat => 'Meat',
    FoodCategory.beverages => 'Beverages',
    FoodCategory.other => 'Other',
  };
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photo, required this.onTap});
  final XFile? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: cs.surfaceContainerLowest,
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photo!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: cs.outline),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add photo',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
      ),
    );
  }
}
