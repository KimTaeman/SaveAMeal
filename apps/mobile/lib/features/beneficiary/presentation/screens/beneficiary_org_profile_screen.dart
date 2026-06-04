import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:url_launcher/url_launcher.dart';

class BeneficiaryOrgProfileScreen extends ConsumerStatefulWidget {
  const BeneficiaryOrgProfileScreen({super.key});

  @override
  ConsumerState<BeneficiaryOrgProfileScreen> createState() =>
      _BeneficiaryOrgProfileScreenState();
}

class _BeneficiaryOrgProfileScreenState
    extends ConsumerState<BeneficiaryOrgProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _missionController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _fetchingLocation = false;
  String? _selectedType;
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

  Future<void> _getCurrentLocation() async {
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

  InputDecoration _fieldDecoration(
    ColorScheme cs,
    AppColors ac, {
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? hintText,
  }) => InputDecoration(
    hintText: hintText,
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
    filled: true,
    fillColor: cs.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Spacing.sm + Spacing.xs,
      vertical: Spacing.sm + Spacing.xs,
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
  );

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
              onPressed: () => _getCurrentLocation(),
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
    if (!_formKey.currentState!.validate()) return;
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
              latitude: _latitude,
              longitude: _longitude,
            ),
          );
      if (mounted) {
        setState(() {
          _saving = false;
          _initialized = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e, st) {
      AppLogger.error('updateOrgProfile failed', error: e, stack: st);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final profileAsync = ref.watch(currentBeneficiaryProfileProvider);
    final profile = profileAsync.asData?.value;
    if (!_initialized && profile != null) {
      _nameController.text = profile.orgName ?? '';
      _addressController.text = profile.address ?? '';
      _emailController.text = profile.contactEmail ?? '';
      _missionController.text = profile.missionStatement ?? '';
      _selectedType = profile.orgType;
      _latitude = profile.latitude;
      _longitude = profile.longitude;
      _initialized = true;
    }
    final String orgName;
    if (profile == null) {
      orgName = 'Your Organization';
    } else if (profile.orgName != null && profile.orgName!.isNotEmpty) {
      orgName = profile.orgName!;
    } else if (profile.name.isNotEmpty) {
      orgName = profile.name;
    } else {
      orgName = 'Your Organization';
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Organization Profile',
          style: textTheme.titleLarge?.copyWith(color: cs.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: Spacing.lg),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.domain, size: 48, color: cs.primary),
                    ),
                  ),
                  SizedBox(height: Spacing.sm),
                  Text(
                    orgName,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Spacing.xs),
                  Text(
                    _selectedType ?? 'Organization',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: Spacing.sm),
                  Container(height: 2, width: 120, color: cs.primary),
                ],
              ),
            ),
            SizedBox(height: Spacing.md),
            if (profileAsync.hasValue &&
                profile != null &&
                (profile.orgName == null || profile.orgName!.isEmpty) &&
                (profile.address == null || profile.address!.isEmpty) &&
                (profile.missionStatement == null ||
                    profile.missionStatement!.isEmpty)) ...[
              Card(
                color: cs.surfaceContainerLow,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 48,
                        color: cs.primary,
                      ),
                      SizedBox(height: Spacing.sm),
                      Text(
                        'Set up your organization profile',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Spacing.xs),
                      Text(
                        'Add your organization\'s details so donors know who you are.',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Spacing.sm),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Spacing.md),
            ],
            Card(
              color: cs.surfaceContainerLow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(Spacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Organization Name',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _nameController,
                        decoration: _fieldDecoration(
                          cs,
                          ac,
                          prefixIcon: Icon(
                            Icons.grid_view_outlined,
                            color: cs.primary,
                          ),
                          hintText: 'e.g. Bangkok Food Bank',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Organization name is required'
                            : null,
                      ),
                      SizedBox(height: Spacing.md),
                      Text(
                        'Organization Type',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        items:
                            const [
                                  'Shelter',
                                  'Food Bank',
                                  'Community Kitchen',
                                  'School',
                                  'Hospital',
                                  'Other',
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selectedType = v),
                        hint: const Text('Select type'),
                        decoration: _fieldDecoration(
                          cs,
                          ac,
                          prefixIcon: Icon(
                            Icons.account_tree_outlined,
                            color: cs.primary,
                          ),
                        ),
                        validator: (v) =>
                            v == null ? 'Organization type is required' : null,
                      ),
                      SizedBox(height: Spacing.md),
                      Text(
                        'Headquarters Address',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _addressController,
                        decoration: _fieldDecoration(
                          cs,
                          ac,
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: cs.primary,
                          ),
                          suffixIcon: _buildAddressSuffixIcon(cs),
                          hintText: 'e.g. 123 Sukhumvit Rd, Bangkok 10110',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Address is required'
                            : null,
                      ),
                      SizedBox(height: Spacing.md),
                      Text(
                        'Primary Contact Email',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _fieldDecoration(
                          cs,
                          ac,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: cs.primary,
                          ),
                          hintText: 'e.g. contact@org.org',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: Spacing.md),
                      Text(
                        'Mission Statement / Bio',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _missionController,
                        maxLines: 5,
                        minLines: 4,
                        decoration: _fieldDecoration(
                          cs,
                          ac,
                          hintText:
                              'Describe your organization\'s mission and the people you serve…',
                        ),
                      ),
                      SizedBox(height: Spacing.lg),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _saving ? null : _handleSave,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.save_outlined, size: 18),
                                  SizedBox(width: Spacing.sm),
                                  Text(
                                    'Save Profile Changes',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Spacing.lg),
          ],
        ),
      ),
      bottomNavigationBar: BeneficiaryBottomNav(
        currentIndex: 3,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/beneficiary');
          if (i == 3) context.go('/beneficiary/account');
        },
      ),
    );
  }
}
