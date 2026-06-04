import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BeneficiaryBottomNav extends StatelessWidget {
  const BeneficiaryBottomNav({
    required this.currentIndex,
    this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final void Function(int)? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (onDestinationSelected != null) {
          onDestinationSelected!.call(index);
        } else {
          switch (index) {
            case 0:
              context.go('/beneficiary');
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
