import 'package:flutter/material.dart';

/// Reads the signed-in user's role and redirects to the appropriate dashboard.
class RoleRouterScreen extends StatelessWidget {
  const RoleRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: read auth provider, switch on UserRole, push the correct dashboard route
    return const Scaffold(
      body: Center(child: Text('TODO: RoleRouterScreen')),
    );
  }
}
