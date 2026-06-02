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
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback ensures the router widget tree is mounted before
    // getInitialMessage() can attempt navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler(ref.read(routerProvider)).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SaveAMeal',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
