import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/core/utils/distance_utils.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/batch_session_provider.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/beneficiary_destination_card.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/donor_brand_title.dart';

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
    // ignore: unused_local_variable
    final ac = Theme.of(context).extension<AppColors>()!;
    final beneficiariesAsync = ref.watch(beneficiariesProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        titleSpacing: 0,
        title: const DonorBrandTitle(),
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
            _fieldLabel(context, 'Quantity (kg/portions)'),
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
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    'No destinations currently accepting food.',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  );
                }
                final donorProfile = currentUserAsync.asData?.value;
                final donorLat = donorProfile?.latitude;
                final donorLng = donorProfile?.longitude;
                return FormField<Beneficiary>(
                  validator: (_) => _beneficiary == null
                      ? 'Please select a destination'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...items.map((b) {
                        final double? dist =
                            (donorLat != null &&
                                donorLng != null &&
                                b.latitude != null &&
                                b.longitude != null)
                            ? haversineKm(
                                donorLat,
                                donorLng,
                                b.latitude!,
                                b.longitude!,
                              )
                            : null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: BeneficiaryDestinationCard(
                            beneficiary: b,
                            distanceKm: dist,
                            isSelected: _beneficiary?.id == b.id,
                            onTap: () => setState(() => _beneficiary = b),
                          ),
                        );
                      }),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: Text(
                            field.errorText!,
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
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
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Add to Batch'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: const StadiumBorder(),
              ),
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
                child: _PhotoPreview(photo: photo!),
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

/// Renders a picked [XFile] as an image preview.
///
/// On Flutter Web [Image.file] is not supported (the `dart:io` [File] API is
/// unavailable). Instead the raw bytes are read via [XFile.readAsBytes] and
/// displayed with [Image.memory]. On native platforms [Image.file] is used
/// directly so no extra copy is made.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});
  final XFile photo;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: photo.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
          );
        },
      );
    }

    return Image.file(
      File(photo.path),
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}
