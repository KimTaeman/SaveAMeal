import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';

class BeneficiaryBottomNav extends ConsumerWidget {
  const BeneficiaryBottomNav({
    required this.currentIndex,
    this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final void Function(int)? onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final deliveries =
        ref.watch(activeDeliveriesProvider(uid)).asData?.value ?? const [];

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (onDestinationSelected != null) {
          onDestinationSelected!.call(index);
        } else {
          switch (index) {
            case 0:
              context.go('/beneficiary');
            case 1:
              if (deliveries.isNotEmpty) {
                context.go('/beneficiary/delivery/${deliveries.first.batchId}');
              } else {
                context.go('/beneficiary/history');
              }
            case 2:
              context.go('/beneficiary/impact');
            case 3:
              context.go('/beneficiary/account');
          }
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: 'Track',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'Impact',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
