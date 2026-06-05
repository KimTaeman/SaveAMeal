import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/onboarding_step_indicator.dart';
import 'package:saveameal/shared/widgets/save_a_meal_logo.dart';
import 'package:url_launcher/url_launcher.dart';

const List<String> _orgTypes = [
  'Shelter',
  'Food Bank',
  'Community Kitchen',
  'School',
  'Hospital',
  'Other',
];

/// Onboarding screen shown to new beneficiaries to set up their organization.
///
/// Shown at `/onboarding/beneficiary` — requires auth, no AppBar, no bottom nav.
class BeneficiaryOnboardingScreen extends ConsumerStatefulWidget {
  const BeneficiaryOnboardingScreen({super.key});

  @override
  ConsumerState<BeneficiaryOnboardingScreen> createState() =>
      _BeneficiaryOnboardingScreenState();
}

class _BeneficiaryOnboardingScreenState
    extends ConsumerState<BeneficiaryOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _missionController = TextEditingController();

  String? _selectedType;
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
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _missionController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    if (_addressController.text.isEmpty) {
      _latitude = null;
      _longitude = null;
    }
    setState(() {});
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

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(updateOrgProfileUseCaseProvider)
          .call(
            uid,
            BeneficiaryOrgProfileUpdate(
              orgName: _nameController.text.trim(),
              address: _addressController.text.trim(),
              orgType: _selectedType,
              contactEmail: _emailController.text.trim(),
              missionStatement: _missionController.text.trim(),
            ),
          );
      ref.invalidate(currentBeneficiaryProfileProvider);
      if (mounted) {
        context.go('/beneficiary');
      }
    } catch (e, st) {
      AppLogger.error(
        'BeneficiaryOnboarding: updateOrgProfile failed',
        error: e,
        stack: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final tt = Theme.of(context).textTheme;

    InputDecoration fieldDecoration({
      String? labelText,
      Widget? prefixIcon,
      Widget? suffixIcon,
    }) =>
        InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ac.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ac.danger, width: 1.5),
          ),
          filled: true,
          fillColor: cs.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + Spacing.xs,
            vertical: Spacing.sm + Spacing.xs,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
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
                'Set Up Your Organization',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Tell us about your organization so donors can find you.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Organization Name
                    TextFormField(
                      controller: _nameController,
                      decoration: fieldDecoration(
                        labelText: 'Organization Name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Organization name is required'
                          : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: Spacing.md),
                    // Organization Type
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: fieldDecoration(
                        labelText: 'Organization Type',
                      ),
                      hint: const Text('Select type'),
                      items: _orgTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v),
                      validator: (v) =>
                          v == null ? 'Organization type is required' : null,
                    ),
                    const SizedBox(height: Spacing.md),
                    // Headquarters Address
                    TextFormField(
                      controller: _addressController,
                      decoration: fieldDecoration(
                        labelText: 'Headquarters Address',
                        suffixIcon: _buildAddressSuffixIcon(cs),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Address is required'
                          : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: Spacing.md),
                    // Primary Contact Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: fieldDecoration(
                        labelText: 'Primary Contact Email',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: Spacing.md),
                    // Mission Statement
                    TextFormField(
                      controller: _missionController,
                      maxLines: 5,
                      minLines: 4,
                      decoration: fieldDecoration(
                        labelText: 'Mission Statement / Bio (optional)',
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
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
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
