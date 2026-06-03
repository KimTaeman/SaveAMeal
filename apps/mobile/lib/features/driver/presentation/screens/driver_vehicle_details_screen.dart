import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

/// Vehicle Details screen — `/driver/account/vehicle-details`.
class DriverVehicleDetailsScreen extends ConsumerStatefulWidget {
  const DriverVehicleDetailsScreen({super.key});

  @override
  ConsumerState<DriverVehicleDetailsScreen> createState() =>
      _DriverVehicleDetailsScreenState();
}

const List<String> _cargoOptions = ['Small', 'Medium', 'Large', 'Extra Large'];

class _DriverVehicleDetailsScreenState
    extends ConsumerState<DriverVehicleDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _makeModelController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _vehicleColorController;
  late final TextEditingController _insuranceController;

  String? _selectedCargoCapacity;
  bool _refrigeratedStorage = false;

  bool _initialised = false;

  void _initialiseControllers(DriverProfile profile) {
    if (_initialised) return;
    _makeModelController = TextEditingController(
      text: profile.vehicleType ?? '',
    );
    _licensePlateController = TextEditingController(
      text: profile.licensePlate ?? '',
    );
    _vehicleColorController = TextEditingController(
      text: profile.vehicleColor ?? '',
    );
    _insuranceController = TextEditingController(
      text: profile.insurancePolicyNumber ?? '',
    );
    _selectedCargoCapacity = profile.cargoCapacity;
    _refrigeratedStorage = profile.refrigeratedStorage ?? false;
    _initialised = true;
  }

  @override
  void dispose() {
    if (_initialised) {
      _makeModelController.dispose();
      _licensePlateController.dispose();
      _vehicleColorController.dispose();
      _insuranceController.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(DriverProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = current.copyWith(
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
    await ref.read(driverProfileProvider.notifier).updateProfile(updated);
    if (!mounted) return;
    final profileState = ref.read(driverProfileProvider);
    if (profileState is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${profileState.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profileAsync = ref.watch(driverProfileProvider);
    final isLoading = profileAsync is AsyncLoading;

    final profile = profileAsync.value;
    if (profile != null) {
      _initialiseControllers(profile);
    }

    // Shared pill-shaped input decoration for all text fields.
    InputDecoration pillDecoration({required String hintText}) =>
        InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: cs.surfaceContainerLowest,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: cs.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        leading: BackButton(onPressed: () => context.pop()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      bottomNavigationBar: const _DriverBottomNav(currentIndex: 2),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: textTheme.bodyMedium)),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Profile unavailable offline',
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            );
          }

          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.md,
                  ),
                  itemCount: 1,
                  itemBuilder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Title block ───────────────────────────────────
                      Text(
                        'Vehicle Details',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Provide your vehicle information to help us '
                        'coordinate efficient food pickups.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // ── Group 1: white box ────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Make & Model
                            Text(
                              'Make & Model',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              controller: _makeModelController,
                              decoration: pillDecoration(
                                hintText: 'e.g. Toyota Prius',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: Spacing.md),

                            // License Plate
                            Text(
                              'License Plate',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              controller: _licensePlateController,
                              decoration: pillDecoration(hintText: 'ABC-1234'),
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: Spacing.md),

                            // Vehicle Color
                            Text(
                              'Vehicle Color',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              controller: _vehicleColorController,
                              decoration: pillDecoration(
                                hintText: 'e.g. Silver',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: Spacing.md),

                            // Cargo Capacity
                            Text(
                              'Cargo Capacity',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            DropdownButtonFormField<String>(
                              // ignore: deprecated_member_use
                              value: _selectedCargoCapacity,
                              decoration: pillDecoration(
                                hintText: 'Select capacity',
                              ),
                              items: _cargoOptions
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(o),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCargoCapacity = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Spacing.md),

                      // ── Group 2: green box ────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Refrigerated Storage toggle row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Refrigerated Storage',
                                        style: textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: Spacing.xs),
                                      Text(
                                        'Required for cold chain rescues',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _refrigeratedStorage,
                                  onChanged: (val) => setState(
                                    () => _refrigeratedStorage = val,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.md),

                            // Insurance Policy Number
                            Text(
                              'Insurance Policy Number',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              controller: _insuranceController,
                              decoration: pillDecoration(
                                hintText: 'Enter policy number',
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(profile),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Spacing.lg),

                      // ── Save button ───────────────────────────────────
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                        onPressed: isLoading ? null : () => _submit(profile),
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared bottom nav ─────────────────────────────────────────────────────────

class _DriverBottomNav extends StatelessWidget {
  const _DriverBottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        if (i == 0) context.go('/driver');
        if (i == 2) context.go('/driver/account');
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.eco_outlined),
          selectedIcon: Icon(Icons.eco),
          label: 'Impact',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
