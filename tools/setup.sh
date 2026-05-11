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
echo "Setup complete. Run 'flutter run' from apps/mobile/ to start the app."
