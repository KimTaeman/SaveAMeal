import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';

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

  @override
  void dispose() {
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

  Future<void> _pickBanner(String uid) async {
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (photo == null) return;
    setState(() => _uploadingBanner = true);
    try {
      final url = await ref
          .read(storageServiceProvider)
          .uploadBannerPhoto(uid, photo);
      await ref.read(updateUserUsecaseProvider).call(uid, {'bannerUrl': url});
      setState(() => _bannerUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is FirebaseException
              ? 'Upload failed. Please try again.'
              : 'Something went wrong. Please try again.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'orgName': _nameController.text.trim(),
        'managerName': _managerController.text.trim(),
        'phone': _phoneController.text.trim(),
        'streetAddress': _addressController.text.trim(),
        'operatingHours': _operatingHours,
        'surplusTypes': _selectedSurplusTypes.toList(),
        if (_bannerUrl != null) 'bannerUrl': _bannerUrl,
      };
      await ref.read(updateUserUsecaseProvider).call(uid, fields);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is FirebaseException
              ? 'Upload failed. Please try again.'
              : 'Something went wrong. Please try again.'),
        ));
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
            onPressed: null,
          ),
        ],
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Store ID: #${uid.length >= 8 ? uid.substring(0, 8) : uid}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
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
  });

  final TextEditingController nameController;
  final TextEditingController managerController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final String emailText;
  final TextTheme textTheme;
  final VoidCallback onNameChanged;

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
            decoration: const InputDecoration(
              labelText: 'Street Address',
              border: OutlineInputBorder(),
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
