#!/bin/bash
# PreToolUse hook: scan file content for secrets before Write or Edit is applied.
# Exits 2 to block the tool call if a secret pattern is found.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# Only scan source files — skip binary, lock, and generated files
case "$FILE_PATH" in
  *.dart|*.yaml|*.json|*.env) ;;
  *) exit 0 ;;
esac
[[ "$FILE_PATH" == *.g.dart ]] && exit 0
[[ "$FILE_PATH" == *.freezed.dart ]] && exit 0
[[ "$FILE_PATH" == *pubspec.lock ]] && exit 0

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')
[ -z "$CONTENT" ] && exit 0

PATTERNS=(
  'AIza[0-9A-Za-z_-]{35}'
  'ya29\.[0-9A-Za-z_-]+'
  'sk_live_[0-9a-zA-Z]{24}'
  'BEGIN (RSA |EC )?PRIVATE KEY'
  'aws_access_key_id\s*[=:]\s*[A-Z0-9]{20}'
  'aws_secret_access_key\s*[=:]\s*[A-Za-z0-9/+]{40}'
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qE "$pattern"; then
    echo "BLOCKED: Possible secret matching '$pattern' in $FILE_PATH — use --dart-define or flutter_secure_storage instead." >&2
    exit 2
  fi
done

exit 0
