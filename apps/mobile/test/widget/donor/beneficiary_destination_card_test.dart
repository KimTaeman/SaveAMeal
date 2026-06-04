import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';
import 'package:saveameal/features/donor/presentation/widgets/beneficiary_destination_card.dart';
import 'package:saveameal/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

const _beneficiary = Beneficiary(
  id: 'b1',
  name: 'Hope Shelter',
  address: '42 Charity Lane, Bangkok',
  orgType: 'Shelter',
  missionStatement: 'Serving those in need since 2010.',
  latitude: 13.7563,
  longitude: 100.5018,
);

void main() {
  group('BeneficiaryDestinationCard', () {
    testWidgets('renders org name', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Hope Shelter'), findsOneWidget);
    });

    testWidgets('renders address with location icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('42 Charity Lane, Bangkok'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('renders org-type badge when orgType is non-null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Shelter'), findsOneWidget);
    });

    testWidgets('does not render org-type badge when orgType is null', (
      tester,
    ) async {
      const b = Beneficiary(id: 'b2', name: 'No Type Org');
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: b,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      // No badge text rendered for null orgType
      expect(find.text('Shelter'), findsNothing);
    });

    testWidgets('renders mission statement', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Serving those in need since 2010.'), findsOneWidget);
    });

    testWidgets('shows formatted distance when distanceKm is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            distanceKm: 3.7,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('3.7 km'), findsOneWidget);
      expect(find.byIcon(Icons.near_me_outlined), findsOneWidget);
    });

    testWidgets('shows "Distance unavailable" when distanceKm is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Distance unavailable'), findsOneWidget);
    });

    testWidgets('uses primaryContainer color when selected', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            isSelected: true,
            onTap: () {},
          ),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      final cs = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A7A3A))
            .copyWith(
              primary: const Color(0xFF1A7A3A),
              primaryContainer: const Color(0xFFD6F5E5),
            ),
      ).colorScheme;
      expect(card.color, equals(cs.primaryContainer));
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: _beneficiary,
            isSelected: false,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(BeneficiaryDestinationCard));
      expect(tapped, isTrue);
    });

    testWidgets('does not render address row when address is null', (
      tester,
    ) async {
      const b = Beneficiary(id: 'b3', name: 'No Address Org');
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: b,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('does not render mission statement when null', (tester) async {
      const b = Beneficiary(id: 'b4', name: 'Minimal Org');
      await tester.pumpWidget(
        _wrap(
          BeneficiaryDestinationCard(
            beneficiary: b,
            isSelected: false,
            onTap: () {},
          ),
        ),
      );
      // Only name text present
      expect(find.text('Minimal Org'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2)); // name + distance label
    });
  });
}
