import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:url_launcher/url_launcher.dart';

class OrganizationProfileScreen extends ConsumerStatefulWidget {
  const OrganizationProfileScreen({super.key});

  @override
  ConsumerState<OrganizationProfileScreen> createState() =>
      _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState
    extends ConsumerState<OrganizationProfileScreen> {
  static const _kGreen = Color(0xFF006E2F);

  static const _defaultHours = [
    {'day': 'Monday–Friday', 'open': '6:00 AM', 'close': '10:00 PM'},
    {'day': 'Saturday', 'open': '7:00 AM', 'close': '10:00 PM'},
    {'day': 'Sunday', 'open': '7:00 AM', 'close': '9:00 PM'},
  ];

  final _formKey = GlobalKey<FormState>();

  // Store Details
  final _nameController = TextEditingController();
  final _managerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Banner/photo upload
  bool _uploadingBanner = false;
  String? _bannerUrl;

  // Operating hours
  List<Map<String, String>> _operatingHours = [];
  bool _editingHours = false;
  List<Map<String, TextEditingController>> _hourControllers = [];

  // Surplus types
  final _allSurplusTypes = ['Bakery', 'Produce', 'Dairy', 'Non-Perishable'];
  Set<String> _selectedSurplusTypes = {};

  // Save state
  bool _saving = false;
  bool _initialized = false;
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
    _managerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    for (final row in _hourControllers) {
      row['day']!.dispose();
      row['open']!.dispose();
      row['close']!.dispose();
    }
    super.dispose();
  }

  void _toggleHoursEdit() {
    setState(() => _editingHours = !_editingHours);
  }

  void _addHourRow() {
    setState(() {
      _operatingHours.add({'day': '', 'open': '', 'close': ''});
      _hourControllers.add({
        'day': TextEditingController(),
        'open': TextEditingController(),
        'close': TextEditingController(),
      });
    });
  }

  void _removeHourRow(int i) {
    setState(() {
      _hourControllers[i]['day']!.dispose();
      _hourControllers[i]['open']!.dispose();
      _hourControllers[i]['close']!.dispose();
      _hourControllers.removeAt(i);
      _operatingHours.removeAt(i);
    });
  }

  void _doneEditingHours() {
    setState(() {
      _operatingHours = _hourControllers
          .map(
            (row) => {
              'day': row['day']!.text,
              'open': row['open']!.text,
              'close': row['close']!.text,
            },
          )
          .toList();
      _editingHours = false;
    });
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

  String _errorMessage(String prefix, Object e) {
    if (e is FirebaseException) return '$prefix — ${e.code}';
    return '$prefix. Please try again.';
  }

  Future<void> _pickBanner(String uid) async {
    // Banner is wide; cap at 1200 × 400 and compress to stay under 10 MB limit.
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (photo == null) return;
    setState(() => _uploadingBanner = true);
    try {
      final url = await ref
          .read(storageServiceProvider)
          .uploadBannerPhoto(uid, photo);
      await ref
          .read(updateUserUsecaseProvider)
          .call(uid, UserProfileUpdate(bannerUrl: url));
      setState(() => _bannerUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage('Banner upload failed', e))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
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
              orgName: _nameController.text.trim(),
              managerName: _managerController.text.trim(),
              phone: _phoneController.text.trim(),
              streetAddress: _addressController.text.trim(),
              operatingHours: _operatingHours,
              surplusTypes: _selectedSurplusTypes.toList(),
              bannerUrl: _bannerUrl,
              latitude: _latitude,
              longitude: _longitude,
            ),
          );
      // Invalidate the cached user so the provider re-fetches fresh data from
      // Firestore. Reset _initialized so controllers are re-seeded if the
      // screen stays mounted, and so the next visit starts from fresh data.
      ref.invalidate(currentUserProvider);
      setState(() => _initialized = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Changes saved')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage('Save failed', e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authAsync = ref.watch(authStateProvider);
    final authUser = authAsync.asData?.value;
    final userModelAsync = ref.watch(currentUserProvider);
    final userModel = userModelAsync.asData?.value;

    // Pre-fill once
    if (!_initialized && userModel != null) {
      _nameController.text = userModel.orgName ?? userModel.name;
      _managerController.text = userModel.managerName ?? '';
      _phoneController.text = userModel.phone ?? '';
      _addressController.text = userModel.streetAddress ?? '';
      _bannerUrl = userModel.bannerUrl;
      _latitude = userModel.latitude;
      _longitude = userModel.longitude;
      _selectedSurplusTypes = Set.from(userModel.surplusTypes);
      final hours = userModel.operatingHours.isNotEmpty
          ? userModel.operatingHours
          : _defaultHours;
      _operatingHours = List.from(hours);
      _hourControllers = _operatingHours
          .map(
            (h) => {
              'day': TextEditingController(text: h['day'] ?? ''),
              'open': TextEditingController(text: h['open'] ?? ''),
              'close': TextEditingController(text: h['close'] ?? ''),
            },
          )
          .toList();
      _initialized = true;
    }

    final uid = authUser?.uid ?? '';
    final emailText = userModel?.email ?? authUser?.email ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Organization Profile',
          style: textTheme.titleMedium?.copyWith(
            color: _kGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      bottomNavigationBar: DonorBottomNav(
        currentIndex: 3,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/donor');
            case 1:
              context.go('/donor/impact');
            case 2:
              context.go('/donor/batches');
            case 3:
              context.go('/donor/account');
          }
        },
      ),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: 1,
          itemBuilder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner + Avatar section
              Card(
                clipBehavior: Clip.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Banner image — full width, height 200, rounded corners
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _bannerUrl != null && _bannerUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _bannerUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                  errorWidget: (ctx, url, err) => Container(
                                    height: 200,
                                    color: cs.surfaceContainerHigh,
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: cs.surfaceContainerHigh,
                                ),
                        ),

                        // 2. Pencil edit button — top right
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black87),
                            onPressed: _uploadingBanner
                                ? null
                                : () => _pickBanner(uid),
                          ),
                        ),

                        // Upload progress overlay
                        if (_uploadingBanner)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: const ColoredBox(
                                color: Colors.black26,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 3. Store avatar — centered horizontally, overlapping bottom
                        Positioned(
                          bottom: -36,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: cs.surfaceContainerLow,
                                child: const Icon(
                                  Icons.store,
                                  color: Color(0xFF006E2F),
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Org name and Store ID below banner
                    Container(
                      padding: const EdgeInsets.only(
                        top: 44,
                        bottom: 12,
                        left: Spacing.md,
                        right: Spacing.md,
                      ),
                      child: Column(
                        children: [
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _nameController,
                            builder: (context, value, _) => Text(
                              value.text.isNotEmpty
                                  ? value.text
                                  : (userModel?.name ?? ''),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Store ID: #${uid.length >= 8 ? uid.substring(0, 8) : uid}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
              // Store Details card
              _StoreDetailsCard(
                nameController: _nameController,
                managerController: _managerController,
                phoneController: _phoneController,
                addressController: _addressController,
                emailText: emailText,
                textTheme: textTheme,
                onNameChanged: () => setState(() {}),
                addressSuffixIcon: _buildAddressSuffixIcon(cs),
              ),
              const SizedBox(height: Spacing.md),
              // Operating Hours card
              _OperatingHoursCard(
                operatingHours: _operatingHours,
                editingHours: _editingHours,
                hourControllers: _hourControllers,
                onToggleEdit: _toggleHoursEdit,
                onAddRow: _addHourRow,
                onRemoveRow: _removeHourRow,
                onDone: _doneEditingHours,
                textTheme: textTheme,
                cs: cs,
              ),
              const SizedBox(height: Spacing.md),
              // Surplus Types card
              _SurplusTypesCard(
                allSurplusTypes: _allSurplusTypes,
                selectedSurplusTypes: _selectedSurplusTypes,
                onToggle: (type, v) => setState(() {
                  if (v) {
                    _selectedSurplusTypes.add(type);
                  } else {
                    _selectedSurplusTypes.remove(type);
                  }
                }),
                textTheme: textTheme,
                cs: cs,
              ),
              const SizedBox(height: Spacing.lg),
              // Save Changes button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                  onPressed: _saving || uid.isEmpty ? null : () => _save(uid),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: _kGreen,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Store Details card
// ---------------------------------------------------------------------------

class _StoreDetailsCard extends StatelessWidget {
  const _StoreDetailsCard({
    required this.nameController,
    required this.managerController,
    required this.phoneController,
    required this.addressController,
    required this.emailText,
    required this.textTheme,
    required this.onNameChanged,
    this.addressSuffixIcon,
  });

  final TextEditingController nameController;
  final TextEditingController managerController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final String emailText;
  final TextTheme textTheme;
  final VoidCallback onNameChanged;
  final Widget? addressSuffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store Details',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Supermarket Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (_) => onNameChanged(),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: managerController,
            decoration: const InputDecoration(
              labelText: 'Manager Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            initialValue: emailText,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Primary Contact Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: Spacing.md),
          TextFormField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: 'Street Address',
              border: const OutlineInputBorder(),
              suffixIcon: addressSuffixIcon,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Operating Hours card
// ---------------------------------------------------------------------------

class _OperatingHoursCard extends StatelessWidget {
  const _OperatingHoursCard({
    required this.operatingHours,
    required this.editingHours,
    required this.hourControllers,
    required this.onToggleEdit,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onDone,
    required this.textTheme,
    required this.cs,
  });

  final List<Map<String, String>> operatingHours;
  final bool editingHours;
  final List<Map<String, TextEditingController>> hourControllers;
  final VoidCallback onToggleEdit;
  final VoidCallback onAddRow;
  final void Function(int) onRemoveRow;
  final VoidCallback onDone;
  final TextTheme textTheme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.access_time, color: cs.onSurfaceVariant, size: 20),
              const SizedBox(width: Spacing.xs),
              Text(
                'Operating Hours',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.edit), onPressed: onToggleEdit),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          if (!editingHours)
            // View mode
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: operatingHours.length,
              itemBuilder: (context, i) {
                final h = operatingHours[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(h['day'] ?? '', style: textTheme.bodyMedium),
                      Text(
                        '${h['open'] ?? ''} – ${h['close'] ?? ''}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            // Edit mode
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hourControllers.length,
                  itemBuilder: (context, i) {
                    final row = hourControllers[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: row['day'],
                              decoration: const InputDecoration(
                                labelText: 'Day',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.xs),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row['open'],
                              decoration: const InputDecoration(
                                labelText: 'Open',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.xs),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row['close'],
                              decoration: const InputDecoration(
                                labelText: 'Close',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: cs.error),
                            onPressed: () => onRemoveRow(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Hours'),
                  onPressed: onAddRow,
                ),
                const SizedBox(height: Spacing.xs),
                FilledButton(onPressed: onDone, child: const Text('Done')),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surplus Types card
// ---------------------------------------------------------------------------

class _SurplusTypesCard extends StatelessWidget {
  const _SurplusTypesCard({
    required this.allSurplusTypes,
    required this.selectedSurplusTypes,
    required this.onToggle,
    required this.textTheme,
    required this.cs,
  });

  final List<String> allSurplusTypes;
  final Set<String> selectedSurplusTypes;
  final void Function(String type, bool selected) onToggle;
  final TextTheme textTheme;
  final ColorScheme cs;

  static const _kGreen = Color(0xFF006E2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                'Surplus Types',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: allSurplusTypes.map((type) {
              return FilterChip(
                label: Text(type),
                selected: selectedSurplusTypes.contains(type),
                onSelected: (v) => onToggle(type, v),
                // ignore: deprecated_member_use
                selectedColor: _kGreen.withOpacity(0.15),
                checkmarkColor: _kGreen,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
