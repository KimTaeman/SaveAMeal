import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Full integration tests require a configured Firebase project.
// Steps before implementing:
//   1. Run `flutterfire configure` to generate lib/firebase_options.dart
//   2. Provide a test Firebase project with emulator or real credentials via CI secrets
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('binding initialises without error', (tester) async {
    expect(IntegrationTestWidgetsFlutterBinding.instance, isNotNull);
  });
}
