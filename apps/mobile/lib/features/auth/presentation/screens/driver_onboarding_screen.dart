import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/onboarding_step_indicator.dart';
import 'package:saveameal/shared/widgets/save_a_meal_logo.dart';

const List<String> _cargoOptions = ['Small', 'Medium', 'Large', 'Extra Large'];

/// Onboarding screen shown to new drivers to set up their vehicle details.
///
/// Shown at `/onboarding/driver` — requires auth, no AppBar, no bottom nav.
class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() =>
      _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState
    extends ConsumerState<DriverOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _makeModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _insuranceController = TextEditingController();

  String? _selectedCargoCapacity;
  bool _refrigeratedStorage = false;
  bool _loading = false;

  @override
  void dispose() {
    _makeModelController.dispose();
    _licensePlateController.dispose();
    _vehicleColorController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final profileAsync = ref.read(driverProfileProvider);
      final current = profileAsync.value;

      final DriverProfile updated;
      if (current != null) {
        updated = current.copyWith(
          vehicleType: _makeModelController.text.trim().isEmpty
              ? null
              : _makeModelController.text.trim(),
          licensePlate: _licensePlateController.text.trim().isEmpty
              ? null
              : _licensePlateController.text.trim(),
          vehicleColor: _vehicleColorController.text.trim().isEmpty
              ? null
              : _vehicleColorController.text.trim(),
          cargoCapacity: _selectedCargoCapacity,
          refrigeratedStorage: _refrigeratedStorage,
          insurancePolicyNumber: _insuranceController.text.trim().isEmpty
              ? null
              : _insuranceController.text.trim(),
        );
      } else {
        final authUser = ref.read(authStateProvider).asData?.value;
        if (authUser == null || authUser.uid.isEmpty) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
            ),
          );
          return;
        }
        updated = DriverProfile(
          uid: authUser.uid,
          name: authUser.name,
          email: authUser.email,
          vehicleType: _makeModelController.text.trim().isEmpty
              ? null
              : _makeModelController.text.trim(),
          licensePlate: _licensePlateController.text.trim().isEmpty
              ? null
              : _licensePlateController.text.trim(),
          vehicleColor: _vehicleColorController.text.trim().isEmpty
              ? null
              : _vehicleColorController.text.trim(),
          cargoCapacity: _selectedCargoCapacity,
          refrigeratedStorage: _refrigeratedStorage,
          insurancePolicyNumber: _insuranceController.text.trim().isEmpty
              ? null
              : _insuranceController.text.trim(),
        );
      }

      await ref.read(driverProfileProvider.notifier).updateProfile(updated);
      if (mounted) {
        context.go('/driver');
      }
    } catch (e, st) {
      AppLogger.error(
        'DriverOnboarding: updateProfile failed',
        error: e,
        stack: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the auto-dispose provider alive while this screen is mounted so
    // that updateProfile() can assign state after the async Firestore call
    // completes without hitting UnmountedRefException.
    ref.watch(driverProfileProvider);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    InputDecoration fieldDecoration({required String labelText}) =>
        InputDecoration(
          labelText: labelText,
          filled: true,
          fillColor: cs.surfaceContainerLowest,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.error, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to registration',
                  onPressed: () => _confirmBack(context),
                ),
              ),
              const Center(child: SaveAMealLogo(size: 48)),
              const SizedBox(height: Spacing.md),
              const OnboardingStepIndicator(totalSteps: 2, currentStep: 2),
              const SizedBox(height: Spacing.lg),
              Text(
                'Set Up Your Vehicle',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Add your vehicle details so donors can identify you.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _makeModelController,
                      decoration: fieldDecoration(labelText: 'Make & Model'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Make & model is required'
                          : null,
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _licensePlateController,
                      decoration: fieldDecoration(labelText: 'License Plate'),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'License plate is required'
                          : null,
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _vehicleColorController,
                      decoration: fieldDecoration(labelText: 'Vehicle Color'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: Spacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCargoCapacity,
                      decoration: fieldDecoration(labelText: 'Cargo Capacity'),
                      hint: Text(
                        'Select capacity',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      items: _cargoOptions
                          .map(
                            (o) => DropdownMenuItem(value: o, child: Text(o)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCargoCapacity = val),
                      validator: (v) =>
                          v == null ? 'Cargo capacity is required' : null,
                    ),
                    const SizedBox(height: Spacing.md),
                    SwitchListTile(
                      title: Text(
                        'Refrigerated Storage',
                        style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                      ),
                      subtitle: Text(
                        'Required for cold chain rescues',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      value: _refrigeratedStorage,
                      onChanged: (val) =>
                          setState(() => _refrigeratedStorage = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _insuranceController,
                      decoration: fieldDecoration(
                        labelText: 'Insurance Policy Number',
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: Spacing.xl),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Text('Complete Setup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBack(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go back to registration?'),
        content: const Text(
          'You will be signed out and returned to the registration page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(signOutUsecaseProvider).call();
      if (!context.mounted) return;
      context.go('/register');
    }
  }
}
