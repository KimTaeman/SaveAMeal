import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/core/logging/app_logger.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_account_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/services/service_providers.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class BeneficiaryPersonalInformationScreen extends ConsumerStatefulWidget {
  const BeneficiaryPersonalInformationScreen({super.key});

  @override
  ConsumerState<BeneficiaryPersonalInformationScreen> createState() =>
      _BeneficiaryPersonalInformationScreenState();
}

class _BeneficiaryPersonalInformationScreenState
    extends ConsumerState<BeneficiaryPersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  InputDecoration _baseDecoration(ColorScheme cs, AppColors ac) =>
      InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.sm),
          borderSide: BorderSide(color: ac.danger),
        ),
        filled: true,
        fillColor: cs.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm + Spacing.xs,
        ),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      );

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(updatePersonalInfoUseCaseProvider)
          .call(
            uid,
            UserProfileUpdate(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              location: _locationController.text.trim(),
            ),
          );
      if (mounted) {
        setState(() {
          _saving = false;
          _initialized = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Information saved')));
      }
    } catch (e, st) {
      AppLogger.error('updatePersonalInfo failed', error: e, stack: st);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (photo == null) return;

      final uid = ref.read(authStateProvider).asData?.value?.uid ?? '';
      if (uid.isEmpty) return;

      setState(() => _uploadingPhoto = true);

      final downloadUrl = await ref
          .read(storageServiceProvider)
          .uploadProfilePhoto(uid, photo);

      await ref
          .read(updatePersonalInfoUseCaseProvider)
          .call(uid, UserProfileUpdate(photoUrl: downloadUrl));

      if (!mounted) return;
      setState(() {
        _photoUrl = downloadUrl;
        _uploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is FirebaseException
                ? 'Upload failed. Please try again.'
                : 'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    final authUser = ref.watch(authStateProvider).asData?.value;
    final profile = ref.watch(currentBeneficiaryProfileProvider).asData?.value;

    // Populate once when both auth user and full profile are available.
    // Requires profile so phone (not in AppUser) is always included.
    if (!_initialized && authUser != null && profile != null) {
      _nameController.text = profile.name;
      _emailController.text = authUser.email;
      _phoneController.text = profile.phone ?? '';
      _locationController.text = profile.location ?? '';
      _photoUrl = profile.photoUrl;
      _initialized = true;
    }

    // Fallback: profile arrives after authUser (e.g. cold open of this screen).
    ref.listen<AsyncValue<BeneficiaryProfile?>>(
      currentBeneficiaryProfileProvider,
      (_, next) {
        final p = next.asData?.value;
        final currentUser = ref.read(authStateProvider).asData?.value;
        if (!_initialized && currentUser != null && p != null) {
          setState(() {
            _nameController.text = p.name;
            _emailController.text = currentUser.email;
            _phoneController.text = p.phone ?? '';
            _locationController.text = p.location ?? '';
            _photoUrl = p.photoUrl;
            _initialized = true;
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: Spacing.md),
            Text(
              'Personal Information',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Spacing.sm),
            Text(
              'Tell us a bit about yourself to get started.',
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Spacing.lg),
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
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _uploadingPhoto ? null : _pickImage,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cs.primaryContainer,
                                      border: Border.all(
                                        color: cs.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _uploadingPhoto
                                        ? Padding(
                                            padding: const EdgeInsets.all(
                                              Spacing.sm,
                                            ),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: cs.primary,
                                            ),
                                          )
                                        : (_photoUrl != null
                                              ? ClipOval(
                                                  child: CachedNetworkImage(
                                                    imageUrl: _photoUrl!,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.add_a_photo_outlined,
                                                  color: cs.primary,
                                                  size: 28,
                                                )),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cs.primary,
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        color: cs.onPrimary,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: Spacing.sm),
                            Text(
                              'Upload Photo',
                              style: textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Spacing.lg),
                      Text(
                        'Full Name',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _nameController,
                        decoration: _baseDecoration(
                          cs,
                          ac,
                        ).copyWith(hintText: 'Jane Doe'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      SizedBox(height: Spacing.md),
                      Text(
                        'Email Address',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: _baseDecoration(cs, ac).copyWith(
                          hintText: 'jane@example.com',
                          fillColor: cs.surfaceContainerHighest,
                          suffixIcon: Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(height: Spacing.md),
                      Text(
                        'Phone Number',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _baseDecoration(
                          cs,
                          ac,
                        ).copyWith(hintText: 'e.g. 081-234-5678'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Phone number is required'
                            : null,
                      ),
                      SizedBox(height: Spacing.md),
                      Text(
                        'Primary Location',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Spacing.xs),
                      TextFormField(
                        controller: _locationController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Location is required'
                            : null,
                        decoration: _baseDecoration(cs, ac).copyWith(
                          hintText: 'City, Neighborhood, or Zip',
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.my_location,
                              color: cs.primary,
                              size: 20,
                            ),
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Getting location...'),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Spacing.xl),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_outlined, size: 18),
                        SizedBox(width: Spacing.sm),
                        Text(
                          'Save',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
