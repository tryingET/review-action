#!/usr/bin/env bash
set -uo pipefail
SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$(cd "$SUITE_DIR/.." && pwd)"
ROOT="$(cd "$TEST_DIR/.." && pwd)"
source "$TEST_DIR/lib/assert.sh"

echo "== package-comparison.sh =="

if ! command -v jq >/dev/null 2>&1; then
  echo "  (skipped: jq not installed)"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/project" "$TMP/source/diff/minitest"

cat > "$TMP/source/diff/minitest/login.compare.diff.sequence.json" <<'JSON'
{
  "kind": "appmap.comparison",
  "schemaVersion": 1,
  "producer": { "name": "test", "version": "1" },
  "scenario": { "id": "login" },
  "recordings": { "base": "base.appmap.json", "head": "head.appmap.json" },
  "capabilities": { "views": { "sequence": 1 } },
  "changes": [
    {
      "id": "chg_11111111111111111111",
      "kind": "call-added",
      "summary": "Added authorize",
      "head": { "eventIds": [3] },
      "views": {
        "sequence": {
          "head": { "eventIds": [3] },
          "diff": { "eventIds": [3] }
        }
      }
    }
  ],
  "views": {
    "sequence": {
      "schemaVersion": 1,
      "base": { "actors": [], "rootActions": [] },
      "head": { "actors": [], "rootActions": [] },
      "diff": { "actors": [], "rootActions": [] },
      "alignment": { "actorOrder": [] }
    }
  }
}
JSON
printf '{"kind":"not-a-comparison"}\n' > \
  "$TMP/source/diff/minitest/invalid.compare.diff.sequence.json"

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
  "schema-v1 comparison bundle is copied with its relative path"
assert_no_file \
  "$TMP/project/.appmap/review/comparison/diff/minitest/invalid.compare.diff.sequence.json" \
  "invalid bundle is not published"
assert_file \
  "$TMP/project/.appmap/review/comparison/README.md" \
  "artifact includes opening instructions"
assert_contains \
  "$(cat "$TMP/project/.appmap/review/comparison/README.md")" \
  "appmap.comparison" \
  "artifact documents the frozen contract"
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