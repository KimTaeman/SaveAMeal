import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/confirm_receipt_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/widgets/beneficiary_bottom_nav.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/utils/batch_id_formatter.dart';

class ConfirmReceiptScreen extends ConsumerStatefulWidget {
  const ConfirmReceiptScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<ConfirmReceiptScreen> createState() =>
      _ConfirmReceiptScreenState();
}

class _ConfirmReceiptScreenState extends ConsumerState<ConfirmReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final detail = ref
        .watch(intakeRequestDetailProvider(widget.batchId))
        .asData
        ?.value;
    final state = ref.watch(confirmReceiptProvider(widget.batchId));
    final notifier = ref.read(confirmReceiptProvider(widget.batchId).notifier);

    ref.listen<ConfirmReceiptState>(confirmReceiptProvider(widget.batchId), (
      prev,
      next,
    ) {
      if (next.submitted && !(prev?.submitted ?? false)) {
        context.pop();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      bottomNavigationBar: const BeneficiaryBottomNav(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            children: [
              // 1. Circular icon
              CircleAvatar(
                radius: 36,
                backgroundColor: ac.success.withValues(alpha: 0.15),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: ac.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: Spacing.md),

              // 2. Title
              Text(
                'Confirm Receipt',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Spacing.xs),

              // 3. Subtitle
              Text(
                'Please confirm that your delivery has arrived and let us know how it went.',
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.md),

              // 4. Info tile
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: ac.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #',
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          formatBatchId(widget.batchId),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date',
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          detail?.createdAt != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(detail!.createdAt!)
                              : '—',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // 5. Divider
              const Divider(),
              const SizedBox(height: Spacing.sm),

              // 6. Rating label
              Text(
                'How was the delivery experience?',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),

              // 7. Star row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  return IconButton(
                    icon: Icon(
                      state.rating >= starValue
                          ? Icons.star
                          : Icons.star_border,
                      color: ac.success,
                    ),
                    iconSize: 32,
                    padding: EdgeInsets.zero,
                    onPressed: () => notifier.setRating(starValue),
                  );
                }),
              ),
              const SizedBox(height: Spacing.md),

              // 8. Feedback label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Additional Feedback (Optional)',
                  style: textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: Spacing.xs),

              // 9. TextField
              TextField(
                maxLines: 5,
                minLines: 3,
                maxLength: 300,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Tell us more about your experience…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ac.success),
                  ),
                ),
                onChanged: notifier.setFeedback,
              ),
              const SizedBox(height: Spacing.md),

              // 10. Primary CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: state.isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ac.onSuccess,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirm Receipt'),
                  onPressed: state.isSubmitting
                      ? null
                      : () => notifier.submit(),
                  style: FilledButton.styleFrom(
                    backgroundColor: ac.success,
                    foregroundColor: ac.onSuccess,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),

              // 11. Secondary CTA
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon'))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ac.success,
                    side: BorderSide(color: ac.success),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Report an Issue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
