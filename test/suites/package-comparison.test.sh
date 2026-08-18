#!/usr/bin/env bash
set -uo pipefail
SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(cd "$SUITE_DIR/.." && pwd)"
ROOT="$(cd "$TEST_DIR/.." && pwd)"
source "$TEST_DIR/lib/assert.sh"

echo "== package-comparison.sh =="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/project" "$TMP/source/diff/minitest"
printf '{"kind":"appmap.sequence-comparison"}\n' > \
  "$TMP/source/diff/minitest/login.compare.diff.sequence.json"

output="$TMP/output"
: > "$output"
(
  cd "$TMP/project"
  GITHUB_OUTPUT="$output" \
  COMPARISON_SOURCE_DIR="$TMP/source" \
  COMPARISON_ARTIFACT_NAME="comparison-test" \
    bash "$ROOT/scripts/package-comparison.sh" >/dev/null
)

values="$(cat "$output")"
assert_contains "$values" "available=true" "comparison artifact is available"
assert_contains "$values" "artifact-name=comparison-test" "artifact name is exported"
assert_file \
  "$TMP/project/.appmap/review/comparison/diff/minitest/login.compare.diff.sequence.json" \
  "comparison bundle is copied with its relative path"
assert_file \
  "$TMP/project/.appmap/review/comparison/README.md" \
  "artifact includes opening instructions"
assert_contains \
  "$(cat "$TMP/project/.appmap/review/comparison-footer.md")" \
  "comparison-test" \
  "review footer names the workflow artifact"

empty_output="$TMP/empty-output"
: > "$empty_output"
mkdir -p "$TMP/empty-source"
(
  cd "$TMP/project"
  GITHUB_OUTPUT="$empty_output" \
  COMPARISON_SOURCE_DIR="$TMP/empty-source" \
    bash "$ROOT/scripts/package-comparison.sh" >/dev/null
)
assert_contains "$(cat "$empty_output")" "available=false" "empty comparison set is non-fatal"

finish
