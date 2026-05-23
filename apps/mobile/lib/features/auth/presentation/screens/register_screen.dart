import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/save_a_meal_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.donor;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = _phoneController.text.trim();
      await ref.read(signUpUsecaseProvider).call(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            phone: phone.isEmpty ? null : phone,
          );
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(child: SaveAMealLogo(size: 56)),
                const SizedBox(height: Spacing.lg),

                // Heading
                Text(
                  'Create an Account',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Join the movement to end food waste.',
                  style:
                      tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xl),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(context, 'Full Name'),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                ),
                const SizedBox(height: Spacing.md),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(context, 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                ),
                const SizedBox(height: Spacing.md),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration(context, 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: Spacing.md),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration:
                      _inputDecoration(context, 'Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters'
                          : null,
                ),
                const SizedBox(height: Spacing.xl),

                // Role selection
                Text(
                  'Choose Your Role',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                _RoleCard(
                  role: UserRole.donor,
                  label: 'Donor',
                  description: 'I have surplus food to give',
                  icon: Icons.lunch_dining_outlined,
                  selected: _selectedRole == UserRole.donor,
                  onTap: () => setState(() => _selectedRole = UserRole.donor),
                ),
                const SizedBox(height: Spacing.sm),
                _RoleCard(
                  role: UserRole.driver,
                  label: 'Driver',
                  description: 'I want to volunteer to deliver',
                  icon: Icons.two_wheeler_outlined,
                  selected: _selectedRole == UserRole.driver,
                  onTap: () =>
                      setState(() => _selectedRole = UserRole.driver),
                ),
                const SizedBox(height: Spacing.sm),
                _RoleCard(
                  role: UserRole.beneficiary,
                  label: 'Beneficiary',
                  description: 'I lead a community that needs food',
                  icon: Icons.home_outlined,
                  selected: _selectedRole == UserRole.beneficiary,
                  onTap: () =>
                      setState(() => _selectedRole = UserRole.beneficiary),
                ),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: Spacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.xl),

                // Create Account button
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                    backgroundColor: cs.primary,
                  ),
                  child: _loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: tt.titleMedium
                              ?.copyWith(color: cs.onPrimary),
                        ),
                ),
                const SizedBox(height: Spacing.md),

                // Login link
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Already have an account? Log In',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String label) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.06)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.31),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: cs.primary, size: 22),
            ),
            const SizedBox(width: Spacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  description,
                  style:
                      tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
