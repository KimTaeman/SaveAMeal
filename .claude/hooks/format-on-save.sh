#!/bin/bash
# PostToolUse hook: runs dart format on .dart files after each Write or Edit.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
[[ "$FILE_PATH" != *.dart ]] && exit 0
[[ "$FILE_PATH" == *.g.dart ]] && exit 0
[[ "$FILE_PATH" == *.freezed.dart ]] && exit 0

dart format "$FILE_PATH" 2>/dev/null || true
exit 0
