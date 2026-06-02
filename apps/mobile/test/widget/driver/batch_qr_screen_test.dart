import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saveameal/features/donor/presentation/screens/batch_qr_screen.dart';

Widget _wrap(String batchId) => ProviderScope(
  child: MaterialApp(home: BatchQrScreen(batchId: batchId)),
);

void main() {
  testWidgets('renders a QrImageView widget with the batchId', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('shows Batch QR Code title', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    expect(find.text('Batch QR Code'), findsOneWidget);
  });

  testWidgets('shows the batch ID as subtitle', (tester) async {
    await tester.pumpWidget(_wrap('batch-abc'));
    expect(find.textContaining('batch-abc'), findsOneWidget);
  });
}
