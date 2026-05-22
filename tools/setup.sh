#!/bin/bash
# Run once after cloning to set up the local dev environment.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$REPO_ROOT/apps/mobile"
HOOKS="$REPO_ROOT/.git/hooks"

echo "==> Installing pre-commit hook..."
cat > "$HOOKS/pre-commit" <<'HOOK'
#!/bin/bash
set -e
cd "$(git rev-parse --show-toplevel)/apps/mobile"
echo "Running dart format..."
dart format --set-exit-if-changed .
echo "Running flutter analyze..."
flutter analyze --fatal-infos
HOOK
chmod +x "$HOOKS/pre-commit"
echo "    pre-commit hook installed."

echo "==> Running flutter pub get..."
cd "$MOBILE"
flutter pub get

echo "==> Running code generation..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "✓ Setup complete."
echo ""
echo "─────────────────────────────────────────────────────────────"
echo " NEXT: Download Firebase config files (required for native builds)"
echo ""
echo " 1. Go to: https://console.firebase.google.com"
echo "    → Project: saveameal-87187 → ⚙️ Project settings → Your apps"
echo ""
echo " 2. Android → Download google-services.json"
echo "    → place at: apps/mobile/android/app/google-services.json"
echo ""
echo " 3. iOS → Download GoogleService-Info.plist"
echo "    → place at: apps/mobile/ios/Runner/GoogleService-Info.plist"
echo ""
echo " Web works without these files: flutter run -d chrome"
echo "─────────────────────────────────────────────────────────────"
