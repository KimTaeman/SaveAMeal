import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/confirm_receipt_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/screens/rate_delivery_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

const _kBatchId = 'batchABCDEFGH1234';

final _fakeDetail = IntakeRequestDetail(
  batchId: _kBatchId,
  beneficiaryId: 'ben_001',
  donorId: 'donor_001',
  status: IntakeStatus.delivered,
  portions: 2,
  weightKg: 5.0,
  items: const [],
  createdAt: DateTime(2024, 10, 24),
);

Widget _buildScreen(ConfirmReceiptState stateOverride) {
  return ProviderScope(
    overrides: [
      confirmReceiptProvider(
        _kBatchId,
      ).overrideWith(() => _FakeNotifier(stateOverride)),
      intakeRequestDetailProvider(
        _kBatchId,
      ).overrideWith((_) => Stream.value(_fakeDetail)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: ConfirmReceiptScreen(batchId: _kBatchId),
    ),
  );
}

class _FakeNotifier extends ConfirmReceiptNotifier {
  _FakeNotifier(this._initial);
  final ConfirmReceiptState _initial;

  @override
  ConfirmReceiptState build(String batchId) => _initial;

  @override
  void setRating(int value) {
    if (value == state.rating) {
      state = state.copyWith(rating: 0);
    } else {
      state = state.copyWith(rating: value);
    }
  }

  @override
  void setFeedback(String value) {
    state = state.copyWith(feedback: value);
  }

  @override
  Future<void> submit() async {
    // no-op in widget tests unless explicitly tested
  }
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ConfirmReceiptScreen', () {
    // (1) renders title and subtitle
    testWidgets('renders title "Confirm Receipt" and subtitle', (tester) async {
      await tester.pumpWidget(_buildScreen(const ConfirmReceiptState()));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Receipt'), findsWidgets);
      expect(
        find.text(
          'Please confirm that your delivery has arrived and let us know how it went.',
        ),
        findsOneWidget,
      );
    });

    // (2) renders 5 star IconButtons, all unfilled initially
    testWidgets('renders 5 star IconButtons, all star_border initially', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(const ConfirmReceiptState()));
      await tester.pumpAndSettle();

      // All 5 stars should be unfilled (star_border icon)
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
      expect(find.byIcon(Icons.star), findsNothing);
    });

    // (3) tapping star 3 fills stars 1–3, leaves 4–5 unfilled
    testWidgets('tapping star 3 fills stars 1-3', (tester) async {
      await tester.pumpWidget(_buildScreen(const ConfirmReceiptState()));
      await tester.pumpAndSettle();

      // Tap the 3rd star button (index 2, value 3).
      final starButtons = find.byType(IconButton);
      // There are 5 star buttons
      await tester.tap(starButtons.at(2));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    // (4) tapping star 3 again deselects → all unfilled
    testWidgets('tapping star 3 twice deselects all stars', (tester) async {
      await tester.pumpWidget(_buildScreen(const ConfirmReceiptState()));
      await tester.pumpAndSettle();

      final starButtons = find.byType(IconButton);
      await tester.tap(starButtons.at(2));
      await tester.pumpAndSettle();
      await tester.tap(starButtons.at(2));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    });

    // (5) primary CTA labelled "Confirm Receipt" is present
    testWidgets('primary CTA "Confirm Receipt" button is present', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(const ConfirmReceiptState()));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Receipt'), findsWidgets);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    // (6) primary CTA is disabled and shows CircularProgressIndicator when isSubmitting
    testWidgets(
      'primary CTA is disabled and shows CircularProgressIndicator when isSubmitting',
      (tester) async {
        await tester.pumpWidget(
          _buildScreen(const ConfirmReceiptState(isSubmitting: true)),
        );
        // Use pump() instead of pumpAndSettle() to avoid timeout from CircularProgressIndicator.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    // (7) on submitted==true the screen pops
    testWidgets('on submitted==true the screen pops', (tester) async {
      // Use a GoRouter to satisfy context.pop().
      bool popped = false;

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/home/confirm'),
                child: const Text('Open'),
              ),
            ),
            routes: [
              GoRoute(
                path: 'confirm',
                builder: (context, state) =>
                    ConfirmReceiptScreen(batchId: _kBatchId),
              ),
            ],
          ),
        ],
        observers: [_PopObserver(onPop: () => popped = true)],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            confirmReceiptProvider(
              _kBatchId,
            ).overrideWith(() => _SubmittingNotifier()),
            intakeRequestDetailProvider(
              _kBatchId,
            ).overrideWith((_) => Stream.value(_fakeDetail)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );

      // Navigate to confirm screen.
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The ConfirmReceiptScreen should be visible now.
      expect(find.byType(ConfirmReceiptScreen), findsOneWidget);

      // Trigger submitted state via the notifier (cast to subclass).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ConfirmReceiptScreen)),
      );
      final notifier = container.read(
        confirmReceiptProvider(_kBatchId).notifier,
      );
      (notifier as _SubmittingNotifier).triggerSubmitted();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    // (8) on error!=null a SnackBar is shown
    testWidgets('on error!=null a SnackBar is shown with the error text', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            confirmReceiptProvider(
              _kBatchId,
            ).overrideWith(() => _ErrorNotifier()),
            intakeRequestDetailProvider(
              _kBatchId,
            ).overrideWith((_) => Stream.value(_fakeDetail)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(body: ConfirmReceiptScreen(batchId: _kBatchId)),
          ),
        ),
      );
      await tester.pump();

      // Trigger an error state transition (cast to subclass).
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ConfirmReceiptScreen)),
      );
      final notifier = container.read(
        confirmReceiptProvider(_kBatchId).notifier,
      );
      (notifier as _ErrorNotifier).triggerError('Something went wrong');
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    // (9) "Report an Issue" button is present and tappable
    testWidgets('"Report an Issue" button is present and tappable', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(const ConfirmReceiptState()));
      await tester.pumpAndSettle();

      expect(find.text('Report an Issue'), findsOneWidget);

      // Ensure the button is visible by scrolling to it.
      await tester.ensureVisible(find.text('Report an Issue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Report an Issue'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should show a "Coming soon" snackbar
      expect(find.text('Coming soon'), findsOneWidget);
    });

    // (10) info tile shows first 8 chars of batchId uppercased
    testWidgets('info tile shows first 8 chars of batchId uppercased', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(const ConfirmReceiptState()));
      await tester.pumpAndSettle();

      // batchId is 'batchABCDEFGH1234' → first 8 chars = 'batchABC' → upper = 'BATCHABC'
      expect(find.text('#BATCHABC'), findsOneWidget);
    });
  });
}

// ── Test-specific notifier subclasses ─────────────────────────────────────────

class _SubmittingNotifier extends ConfirmReceiptNotifier {
  @override
  ConfirmReceiptState build(String batchId) => const ConfirmReceiptState();

  void triggerSubmitted() {
    state = state.copyWith(submitted: true);
  }
}

class _ErrorNotifier extends ConfirmReceiptNotifier {
  @override
  ConfirmReceiptState build(String batchId) => const ConfirmReceiptState();

  void triggerError(String message) {
    state = state.copyWith(error: message);
  }
}

class _PopObserver extends NavigatorObserver {
  _PopObserver({required this.onPop});
  final VoidCallback onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
  }
}
