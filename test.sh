#!/usr/bin/env bash
#
# test.sh — smoke-test all functionality of eval-env.
#
# Builds the release binary, then exercises every behaviour:
#   - lookup from a real environment variable
#   - lookup from an .env file (-e)
#   - env files take precedence over environment variables
#   - multiple env files
#   - stdin key is trimmed of surrounding whitespace
#   - empty stdin exits with code 1
#   - a missing key exits non-zero
#   - silent mode (-s) suppresses the "key=" prefix on stderr
#
# Usage: ./test.sh

set -u

cd "$(dirname "$0")"

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
echo "==> Building (cargo build --release)"
cargo build --release || { echo "build failed"; exit 1; }
BIN="./target/release/eval-env"
echo

# ---------------------------------------------------------------------------
# Test harness
# ---------------------------------------------------------------------------
pass=0
fail=0

# check <description> <expected> <actual>
check() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        printf '  PASS  %s\n' "$desc"
        pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        expected: %q\n        actual:   %q\n' "$desc" "$expected" "$actual"
        fail=$((fail + 1))
    fi
}

# check_code <description> <expected_exit> <actual_exit>
check_code() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        printf '  PASS  %s (exit %s)\n' "$desc" "$actual"
        pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        expected exit: %s\n        actual exit:   %s\n' "$desc" "$expected" "$actual"
        fail=$((fail + 1))
    fi
}

# A throwaway second env file for precedence / multi-file tests.
TMP_ENV="$(mktemp)"
trap 'rm -f "$TMP_ENV"' EXIT
printf 'HELLO=OVERRIDDEN\nFOO=BAR\n' > "$TMP_ENV"

echo "==> Running tests"

# 1. Lookup from a real environment variable.
out="$(echo "GREETING" | GREETING=hi "$BIN")"
check "env var lookup" "hi" "$out"

# 2. Lookup from an .env file.
out="$(echo "HELLO" | "$BIN" -e sample-env)"
check "env file lookup (sample-env: HELLO=WORLD)" "WORLD" "$out"

# 3. Env file takes precedence over the real environment variable.
out="$(echo "HELLO" | HELLO=from_environment "$BIN" -e "$TMP_ENV")"
check "env file overrides environment variable" "OVERRIDDEN" "$out"

# 4. Fall back to the environment when the key is absent from the env file.
out="$(echo "ONLY_IN_ENV" | ONLY_IN_ENV=yes "$BIN" -e sample-env)"
check "falls back to environment when key not in file" "yes" "$out"

# 5. Multiple env files; later files are consulted too.
out="$(echo "FOO" | "$BIN" -e sample-env -e "$TMP_ENV")"
check "multiple env files" "BAR" "$out"

# 6. The key read from stdin is trimmed.
out="$(printf '  HELLO \n' | "$BIN" -e sample-env)"
check "stdin key is trimmed" "WORLD" "$out"

# 7. Silent mode: no "key=" prefix on stderr (and none on stdout either).
err="$(echo "HELLO" | "$BIN" -s -e sample-env 2>&1 1>/dev/null)"
check "silent mode: empty stderr" "" "$err"

# 8. Empty stdin exits with code 1.
echo "" | "$BIN" >/dev/null 2>&1
check_code "empty stdin fails" 1 "$?"

# 9. A missing key (not in file, not in environment) exits non-zero.
echo "DEFINITELY_NOT_SET_12345" | "$BIN" >/dev/null 2>&1
code=$?
if [ "$code" -ne 0 ]; then
    printf '  PASS  missing key fails (exit %s)\n' "$code"
    pass=$((pass + 1))
else
    printf '  FAIL  missing key should fail but exited 0\n'
    fail=$((fail + 1))
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "==> $pass passed, $fail failed"
[ "$fail" -eq 0 ]
