import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/save_a_meal_logo.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _fetchingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _orgNameController.dispose();
    _managerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    final text = _addressController.text.trim();
    // Auto reverse-geocode if user pasted a coordinate pair
    if (_latitude == null && _longitude == null) {
      final coords = _tryParseCoordinates(text);
      if (coords != null) {
        _reverseGeocode(coords.$1, coords.$2);
        return;
      }
    }
    // existing clear logic below...
    if (text.isEmpty) {
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (kIsWeb) {
      // geocoding package has no web implementation — store coordinates, keep raw text
      if (!mounted) return;
      setState(() {
        _latitude = lat;
        _longitude = lng;
      });
      return;
    }
    try {
      await setLocaleIdentifier('en_US');
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;
      final p = placemarks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((s) => s != null && s.isNotEmpty).join(', ');
      if (parts.isEmpty) return;
      // Remove the listener temporarily to avoid _onAddressChanged clearing lat/lng
      _addressController.removeListener(_onAddressChanged);
      if (!mounted) return;
      setState(() {
        _addressController.text = parts;
        _latitude = lat;
        _longitude = lng;
      });
      _addressController.addListener(_onAddressChanged);
    } catch (_) {
      // Silently ignore — keep the raw coordinate text and coordinates
    }
  }

  (double, double)? _tryParseCoordinates(String text) {
    final parts = text.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return (lat, lng);
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() => _fetchingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _addressController.text =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } on PermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied. Please enter your address manually.',
            ),
          ),
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them in device settings.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _openInMaps() async {
    final Uri uri;
    if (_latitude != null && _longitude != null) {
      uri = Uri.parse('https://maps.google.com/?q=$_latitude,$_longitude');
    } else {
      final encoded = Uri.encodeComponent(_addressController.text.trim());
      uri = Uri.parse('https://maps.google.com/?q=$encoded');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open Maps.')));
    }
  }

  Widget _buildAddressSuffixIcon(ColorScheme cs) {
    final canOpenMaps = _addressController.text.isNotEmpty || _latitude != null;
    return SizedBox(
      width: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fetchingLocation)
            Padding(
              padding: const EdgeInsets.all(Spacing.sm + 2),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            )
          else
            IconButton(
              iconSize: 20,
              icon: Icon(Icons.my_location, color: cs.primary),
              tooltip: 'Use current location',
              onPressed: () => _fetchLocation(),
            ),
          IconButton(
            iconSize: 20,
            icon: Icon(
              Icons.map_outlined,
              color: canOpenMaps
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.38),
            ),
            tooltip: 'Open in Maps',
            onPressed: canOpenMaps ? () => _openInMaps() : null,
          ),
        ],
      ),
    );
  }

  Future<void> _save(String uid) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
              latitude: _latitude,
              longitude: _longitude,
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
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to registration',
          onPressed: () => _confirmBack(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: SaveAMealLogo(size: 48)),
                const SizedBox(height: Spacing.md),

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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final digits = v.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 9 || digits.length > 15) {
                      return 'Enter a valid phone number (9–15 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Spacing.md),

                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration(
                    context,
                    'Street Address',
                    suffixIcon: _buildAddressSuffixIcon(cs),
                  ),
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
              ],
            ),
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

InputDecoration _inputDecoration(
  BuildContext context,
  String label, {
  Widget? suffixIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    suffixIcon: suffixIcon,
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
