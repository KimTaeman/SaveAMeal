import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/features/donor/presentation/widgets/donor_bottom_nav.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  // Photo upload state
  bool _uploadingPhoto = false;
  String? _photoUrl;

  // GPS autofill state
  bool _gettingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authAsync = ref.watch(authStateProvider);
    final authUser = authAsync.asData?.value;
    final userModelAsync = ref.watch(currentUserProvider);
    final userModel = userModelAsync.asData?.value;

    // Pre-fill once data is available
    if (!_initialized && (userModel != null || authUser != null)) {
      _nameController.text = userModel?.name ?? authUser?.name ?? '';
      _phoneController.text = userModel?.phone ?? '';
      _locationController.text = userModel?.location ?? '';
      _photoUrl = userModel?.photoUrl;
      _initialized = true;
    }

    final emailText = userModel?.email ?? authUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Donor Profile',
          style: textTheme.titleMedium?.copyWith(
            color: const Color(0xFF006E2F),
            fontWeight: FontWeight.bold,
          ),
        ),
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
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: 1,
          itemBuilder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us a bit about yourself to get started.',
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              // Form card: upload photo + all 4 form fields
              Container(
                margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Upload photo
                    Center(
                      child: Semantics(
                        label: 'Upload profile photo',
                        button: true,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 96,
                                height: 96,
                                child: Stack(
                                  children: [
                                    // Solid circle border
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF006E2F),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: _buildAvatarContent(
                                          cs,
                                          textTheme,
                                        ),
                                      ),
                                    ),
                                    // Badge bottom-right
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF006E2F),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Spacing.xs),
                              const Text(
                                'Upload Photo',
                                style: TextStyle(
                                  color: Color(0xFF006E2F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: Spacing.md),
                    // Email (read-only)
                    TextFormField(
                      initialValue: emailText,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
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
                    // Location with GPS autofill
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'City, Neighborhood, or Zip',
                        border: const OutlineInputBorder(),
                        suffixIcon: _gettingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(Spacing.sm),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: _getLocation,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              // Save button
              FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF006E2F),
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(ColorScheme cs, TextTheme textTheme) {
    if (_uploadingPhoto) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _photoUrl!,
          fit: BoxFit.cover,
          width: 96,
          height: 96,
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator(color: cs.primary)),
          errorWidget: (context, url, error) =>
              _cameraPlaceholder(cs, textTheme),
        ),
      );
    }
    return _cameraPlaceholder(cs, textTheme);
  }

  Widget _cameraPlaceholder(ColorScheme cs, TextTheme textTheme) {
    return Icon(Icons.camera_alt, color: const Color(0xFF006E2F), size: 32);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      // Resize and compress before upload — phone gallery photos are often
      // 8–20 MB which would exceed Firebase Storage size limits.
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (photo == null) return;

      final authUser = ref.read(authStateProvider).asData?.value;
      if (authUser == null) return;

      setState(() => _uploadingPhoto = true);

      final downloadUrl = await ref
          .read(storageServiceProvider)
          .uploadProfilePhoto(authUser.uid, photo);

      await ref
          .read(updateUserUsecaseProvider)
          .call(authUser.uid, UserProfileUpdate(photoUrl: downloadUrl));
      // Refresh so the account screen shows the new avatar immediately.
      ref.invalidate(currentUserProvider);

      if (!mounted) return;
      setState(() {
        _photoUrl = downloadUrl;
        _uploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage('Photo upload failed', e))),
      );
    }
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      _locationController.text =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage('Could not get location', e))),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  String _errorMessage(String prefix, Object e) {
    if (e is FirebaseException) return '$prefix — ${e.code}';
    return '$prefix. Please try again.';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authUser = ref.read(authStateProvider).asData?.value;
    if (authUser == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(updateUserUsecaseProvider)
          .call(
            authUser.uid,
            UserProfileUpdate(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              location: _locationController.text.trim(),
            ),
          );
      ref.invalidate(currentUserProvider);
      setState(() => _initialized = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage('Save failed', e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
