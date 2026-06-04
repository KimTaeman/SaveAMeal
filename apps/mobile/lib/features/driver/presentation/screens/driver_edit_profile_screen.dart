import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/driver/domain/entities/driver_profile.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';
import 'package:saveameal/features/driver/presentation/widgets/driver_avatar_widget.dart';
import 'package:saveameal/shared/theme/spacing.dart';

/// Personal Information screen — `/driver/account/personal-info`.
class DriverEditProfileScreen extends ConsumerStatefulWidget {
  const DriverEditProfileScreen({super.key});

  @override
  ConsumerState<DriverEditProfileScreen> createState() =>
      _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState
    extends ConsumerState<DriverEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;

  bool _initialised = false;

  void _initialiseControllers(DriverProfile profile) {
    if (_initialised) return;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone ?? '');
    _locationController = TextEditingController(
      text: profile.primaryLocation ?? '',
    );
    _initialised = true;
  }

  @override
  void dispose() {
    if (_initialised) {
      _nameController.dispose();
      _phoneController.dispose();
      _locationController.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(DriverProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = current.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      primaryLocation: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
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
                      // ── Title block (centered) ────────────────────────
                      Text(
                        'Personal Information',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Tell us a bit about yourself to get started.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      // ── White box: avatar + fields ────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(Spacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Avatar upload
                            Center(
                              child: Column(
                                children: [
                                  DriverAvatarWidget(
                                    photoUrl: profile.photoUrl,
                                  ),
                                  const SizedBox(height: Spacing.xs),
                                  Text(
                                    'Upload Photo',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            // Full Name
                            Text(
                              'Full Name',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Jane Doe',
                                filled: true,
                                fillColor: cs.surfaceContainerLowest,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: cs.primary),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(
                                    color: cs.primary,
                                    width: 2,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: Spacing.md),
                            // Email Address
                            Text(
                              'Email Address',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              initialValue: profile.email,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'jane@example.com',
                                filled: true,
                                fillColor: cs.surfaceContainerHigh,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: cs.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: cs.outline),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            // Phone Number
                            Text(
                              'Phone Number',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '(555) 123-4567',
                                filled: true,
                                fillColor: cs.surfaceContainerLowest,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: cs.primary),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(
                                    color: cs.primary,
                                    width: 2,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: Spacing.md),
                            // Primary Location
                            Text(
                              'Primary Location',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                hintText: 'City, Neighborhood, or Zip',
                                filled: true,
                                fillColor: cs.surfaceContainerLowest,
                                suffixIcon: const Icon(
                                  Icons.location_on_outlined,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: cs.primary),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(
                                    color: cs.primary,
                                    width: 2,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
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
                            borderRadius: BorderRadius.circular(30),
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
