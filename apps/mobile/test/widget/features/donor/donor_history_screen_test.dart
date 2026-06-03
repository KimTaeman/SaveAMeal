import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/batch.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_provider.dart';
import 'package:saveameal/features/donor/presentation/screens/donor_history_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

const _testUser = AppUser(
  uid: 'donor-uid',
  name: 'Test Donor',
  email: 'test@donor.com',
  role: UserRole.donor,
);

Batch _makeBatch({required String id, BatchStatus status = BatchStatus.open}) =>
    Batch(
      id: id,
      donorId: 'donor-uid',
      items: const [],
      pickupAddress: '1 Test Road',
      status: status,
      createdAt: DateTime(2026, 5, 23, 14, 30),
    );

Widget _wrap(List<Batch> batches) {
  final router = GoRouter(
    initialLocation: '/donor/batches',
    routes: [
      GoRoute(
        path: '/donor',
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        routes: [
          GoRoute(
            path: 'batches',
            builder: (_, __) => const DonorHistoryScreen(),
          ),
          GoRoute(
            path: 'batch/:batchId',
            builder: (context, state) => Scaffold(
              body: Text('Detail ${state.pathParameters['batchId']}'),
            ),
          ),
          GoRoute(
            path: 'log',
            builder: (_, __) => const Scaffold(body: Text('Log')),
          ),
          GoRoute(
            path: 'impact',
            builder: (_, __) => const Scaffold(body: Text('Impact')),
          ),
          GoRoute(
            path: 'account',
            builder: (_, __) => const Scaffold(body: Text('Account')),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
      allBatchesProvider(
        'donor-uid',
      ).overrideWith((ref) => Stream.value(batches)),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  group('DonorHistoryScreen', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/donor/batches',
        routes: [
          GoRoute(
            path: '/donor/batches',
            builder: (_, __) => const DonorHistoryScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            allBatchesProvider(
              'donor-uid',
            ).overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('All chip shows all batches', (tester) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.closed),
        _makeBatch(id: 'cccccccc', status: BatchStatus.delivered),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsNWidgets(3));
    });

    testWidgets('In Progress chip shows only active-status batches', (
      tester,
    ) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.closed),
        _makeBatch(id: 'cccccccc', status: BatchStatus.claimed),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.tap(find.text('In Progress'));
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsNWidgets(2));
    });

    testWidgets('Completed chip shows only delivered/closed batches', (
      tester,
    ) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.closed),
        _makeBatch(id: 'cccccccc', status: BatchStatus.delivered),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsNWidgets(2));
    });

    testWidgets('shows empty state when no batches', (tester) async {
      await tester.pumpWidget(_wrap([]));
      await tester.pumpAndSettle();

      expect(find.text('No donations yet'), findsOneWidget);
    });

    testWidgets('tapping a batch card navigates to /donor/batch/:id', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap([_makeBatch(id: 'abc12345', status: BatchStatus.open)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('#').first);
      await tester.pumpAndSettle();

      expect(find.text('Detail abc12345'), findsOneWidget);
    });

    testWidgets('search filters by batch short ID', (tester) async {
      final batches = [
        _makeBatch(id: 'aaaaaaaa', status: BatchStatus.open),
        _makeBatch(id: 'bbbbbbbb', status: BatchStatus.open),
      ];
      await tester.pumpWidget(_wrap(batches));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'aaaa');
      await tester.pumpAndSettle();

      expect(find.textContaining('#'), findsOneWidget);
    });
  });
}
