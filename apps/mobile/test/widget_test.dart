import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    testWidgets('light theme provides AppColors extension', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(Theme.of(ctx).extension<AppColors>(), isNotNull);
    });

    testWidgets('dark theme provides AppColors extension', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(Theme.of(ctx).extension<AppColors>(), isNotNull);
    });
  });

  group('Router', () {
    testWidgets('initial route renders without error', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });
}
