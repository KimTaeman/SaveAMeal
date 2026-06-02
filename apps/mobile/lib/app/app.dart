import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saveameal/app/router.dart';
import 'package:saveameal/services/notification_handler.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  List<StreamSubscription<dynamic>> _notificationSubs = [];

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback ensures the router widget tree is mounted before
    // getInitialMessage() can attempt navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationSubs = NotificationHandler(ref.read(routerProvider)).init();
    });
  }

  @override
  void dispose() {
    for (final sub in _notificationSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SaveAMeal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
