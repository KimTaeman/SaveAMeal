import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/entities/driver_impact.dart';
import 'package:saveameal/features/driver/domain/entities/leaderboard_entry.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_impact_provider.dart';
import 'package:saveameal/features/driver/presentation/screens/driver_impact_screen.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

const _fakeUser = AppUser(
  uid: 'uid1',
  name: 'Test Driver',
  email: 'test@test.com',
  role: UserRole.driver,
);

const _fakeImpact = DriverImpact(
  rank: 4,
  totalDrivers: 128,
  mealsSaved: 342,
  sproutPoints: 1250,
  rankProgressCurrent: 342,
  rankProgressTarget: 500,
  currentRankName: 'Bronze',
  nextRankName: 'Silver',
);

const _fakeLeaderboard = [
  LeaderboardEntry(
    rank: 1,
    driverName: 'Sarah J.',
    zone: 'Central Hub',
    score: 512,
  ),
  LeaderboardEntry(
    rank: 2,
    driverName: 'Marcus T.',
    zone: 'North District',
    score: 489,
  ),
  LeaderboardEntry(
    rank: 3,
    driverName: 'Elena R.',
    zone: 'East Side',
    score: 420,
  ),
  LeaderboardEntry(
    rank: 4,
    driverName: 'Nattapong',
    zone: 'South Zone',
    score: 342,
    isCurrentUser: true,
  ),
];

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/driver/impact',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (ctx, s) => const Scaffold(body: Text('Notifications')),
    ),
    GoRoute(
      path: '/driver',
      builder: (ctx, s) => const Scaffold(body: Text('Home')),
      routes: [
        GoRoute(
          path: 'impact',
          builder: (ctx, s) => const DriverImpactScreen(),
        ),
        GoRoute(
          path: 'account',
          builder: (ctx, s) => const Scaffold(body: Text('Account')),
        ),
      ],
    ),
  ],
);

Widget _wrap() => ProviderScope(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(_fakeUser)),
    driverImpactProvider('uid1').overrideWith((_) async => _fakeImpact),
    leaderboardProvider(
      'uid1',
      'thisMonth',
    ).overrideWith((_) async => _fakeLeaderboard),
  ],
  child: MaterialApp.router(
    theme: AppTheme.light(),
    routerConfig: _buildRouter(),
  ),
);

void main() {
  testWidgets('shows CURRENT RANK heading', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('CURRENT RANK'), findsOneWidget);
  });

  testWidgets('shows rank and driver count', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('of 128 Drivers'), findsOneWidget);
  });

  testWidgets('shows rank progress text', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(
      find.textContaining('342 / 500 Meals to Silver Rank'),
      findsOneWidget,
    );
  });

  testWidgets('shows Meals Saved stat', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Meals Saved'), findsOneWidget);
    expect(find.text('342'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows Sprout Points stat formatted', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Sprout Points'), findsOneWidget);
    expect(find.text('1.3K'), findsOneWidget);
  });

  testWidgets('shows Top Drivers section header', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Top Drivers'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
  });

  testWidgets('shows leaderboard entries', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Sarah J.'), findsOneWidget);
    expect(find.text('Marcus T.'), findsOneWidget);
    expect(find.text('Elena R.'), findsOneWidget);
  });

  testWidgets('highlights current user row with (You) label', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.textContaining('(You)'), findsOneWidget);
  });

  testWidgets('shows View Full Leaderboard button', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('view_full_leaderboard')), findsOneWidget);
  });

  testWidgets('shows Impact tab selected in bottom nav', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Impact'), findsOneWidget);
  });
}
