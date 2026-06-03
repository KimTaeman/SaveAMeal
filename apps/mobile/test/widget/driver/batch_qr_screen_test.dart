import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/food_category.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/batch_qr_screen.dart';
import 'package:saveameal/shared/theme/app_colors.dart';

final _fakeBatch = Batch(
  id: 'batch-abc',
  donorId: 'donor-1',
  items: [
    BatchItem(
      name: 'Bread',
      category: FoodCategory.bakery,
      weightKg: 5.0,
      expiryTime: DateTime.now().add(const Duration(hours: 8)),
    ),
  ],
  pickupAddress: '1 Test St',
  status: BatchStatus.open,
);

Widget _wrap(String batchId) => ProviderScope(
  overrides: [
    batchByIdProvider(batchId).overrideWith((_) => Stream.value(_fakeBatch)),
  ],
  child: MaterialApp(
    theme: ThemeData(extensions: const [AppColors.light]),
    home: BatchQrScreen(batchId: batchId),
  ),
);

void main() {
  testWidgets('renders a QrImageView widget with the batchId', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('shows Pickup Code title', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    await tester.pump();
    expect(find.text('Pickup Code'), findsOneWidget);
  });

  testWidgets('shows the batch ID as text', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    await tester.pump();
    expect(find.textContaining('batch-abc'), findsWidgets);
  });

  testWidgets('shows BATCH SUMMARY card when batch loads', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    await tester.pump();
    expect(find.text('BATCH SUMMARY'), findsOneWidget);
  });

  testWidgets('Back to Dashboard button is present', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    await tester.pump();
    expect(find.text('Back to Dashboard'), findsOneWidget);
  });
}
