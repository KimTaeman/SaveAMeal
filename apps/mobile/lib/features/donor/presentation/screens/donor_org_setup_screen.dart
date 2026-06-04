import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/save_a_meal_logo.dart';

class DonorOrgSetupScreen extends ConsumerStatefulWidget {
  const DonorOrgSetupScreen({super.key});

  @override
  ConsumerState<DonorOrgSetupScreen> createState() =>
      _DonorOrgSetupScreenState();
}

class _DonorOrgSetupScreenState extends ConsumerState<DonorOrgSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _managerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  static const _surplusOptions = [
    'Bakery',
    'Produce',
    'Dairy',
    'Non-Perishable',
  ];
  final Set<String> _selectedSurplusTypes = {};

  bool _saving = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _managerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(updateUserUsecaseProvider)
          .call(
            uid,
            UserProfileUpdate(
              orgName: _orgNameController.text.trim(),
              managerName: _managerController.text.trim().isEmpty
                  ? null
                  : _managerController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              streetAddress: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
              surplusTypes: _selectedSurplusTypes.toList(),
            ),
          );
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/donor');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ac = Theme.of(context).extension<AppColors>()!;

    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: SaveAMealLogo(size: 48)),
                const SizedBox(height: Spacing.md),

                // Step indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(done: true, active: false, cs: cs),
                    _StepConnector(cs: cs),
                    _StepDot(done: false, active: true, cs: cs),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Step 2 of 2',
                  textAlign: TextAlign.center,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: Spacing.md),

                Text(
                  'Set Up Your Organization',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Tell us about your store so beneficiaries\nand drivers can find you.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xl),

                TextFormField(
                  controller: _orgNameController,
                  decoration: _inputDecoration(
                    context,
                    'Organization / Store Name',
                  ),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: Spacing.md),

                TextFormField(
                  controller: _managerController,
                  decoration: _inputDecoration(context, 'Manager Name'),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: Spacing.md),

                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration(context, 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: Spacing.md),

                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration(context, 'Street Address'),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: Spacing.xl),

                Text(
                  'What type of food do you donate?',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Select all that apply.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: _surplusOptions.map((type) {
                    final selected = _selectedSurplusTypes.contains(type);
                    return FilterChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedSurplusTypes.add(type);
                        } else {
                          _selectedSurplusTypes.remove(type);
                        }
                      }),
                      selectedColor: ac.brand.withValues(alpha: 0.15),
                      checkmarkColor: ac.brand,
                    );
                  }).toList(),
                ),
                const SizedBox(height: Spacing.xl),

                FilledButton(
                  onPressed: (_saving || uid.isEmpty) ? null : () => _save(uid),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                    backgroundColor: cs.primary,
                  ),
                  child: _saving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(
                          'Complete Setup',
                          style: tt.titleMedium?.copyWith(color: cs.onPrimary),
                        ),
                ),
                const SizedBox(height: Spacing.sm),

                TextButton(
                  onPressed: _saving ? null : () => context.go('/donor'),
                  child: Text(
                    'Skip for now',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.active, required this.cs});

  final bool done;
  final bool active;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final filled = done || active;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? cs.primary : cs.surfaceContainerHigh,
      ),
      child: done
          ? Icon(Icons.check, size: 14, color: cs.onPrimary)
          : active
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.onPrimary,
                ),
              ),
            )
          : null,
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) =>
      Container(width: 40, height: 2, color: cs.primary);
}

InputDecoration _inputDecoration(BuildContext context, String label) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: cs.onSurfaceVariant),
    filled: true,
    fillColor: cs.surfaceContainerLowest,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Spacing.md,
      vertical: Spacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.31)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.31)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
  );
}
