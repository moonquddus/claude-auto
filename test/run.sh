#!/usr/bin/env bash
# Runs claude-auto.sh against a stub claude. No network, no credentials.
set -u

cd "$(dirname "$0")/.." || exit 1
root=$(pwd)
fixtures="$root/test/fixtures"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
ln -s "$root/test/stub-claude" "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"
export STUB_RECORD="$tmp/record"

pass=0
fail=0

run() {
    : > "$STUB_RECORD"
    expect -f test/driver.exp ./claude-auto.sh "$@" > "$tmp/output" 2>&1
    code=$?
}

field() { sed -n "s/^$1://p" "$STUB_RECORD" | head -1; }

check() {
    local name=$1 want=$2 got=$3
    if [ "$want" = "$got" ]; then
        printf 'ok   %s\n' "$name"
        pass=$((pass + 1))
    else
        printf 'FAIL %s\n       want: %s\n       got:  %s\n' "$name" "$want" "$got"
        fail=$((fail + 1))
    fi
}

approves() {
    local name=$1 fixture=$2
    STUB_FRAME="$fixtures/$fixture" run
    check "$name" "1<LF>" "$(field input)"
}

ignores() {
    local name=$1 fixture=$2
    STUB_FRAME="$fixtures/$fixture" run
    check "$name" "" "$(field input)"
}

approves "approves a bash prompt"          proceed.txt
approves "approves a file edit prompt"     edit.txt
approves "approves through ANSI attributes" ansi.txt
approves "approves a full-screen frame"     fullscreen.txt
approves "approves a sandbox network prompt" sandbox.txt
approves "approves a full-screen sandbox frame" sandbox-fullscreen.txt
approves "approves a sandbox frame with a wrapped question" sandbox-wrapped.txt

ignores "ignores the question in prose"    prose.txt
ignores "ignores an option list alone"     option-only.txt

# Claude Code ignores input sent less than 150 ms after a dialog appears.
STUB_FRAME="$fixtures/sandbox.txt" STUB_WAIT=4 run
waited=$(field delay)
check "waits out the input refusal window" "yes" \
    "$(python3 -c "print('yes' if $waited >= 0.3 else 'no ($waited s)')")"

STUB_FRAME="$fixtures/proceed.txt" STUB_REPEAT=5 STUB_WAIT=4 run
check "approves a redrawn frame once" "1<LF>" "$(field input)"

CLAUDE_AUTO_TRACE="$tmp/trace" STUB_FRAME="$fixtures/sandbox.txt" run
check "records a trace" "yes" "$(grep -qc 'outside of sandbox' "$tmp/trace" 2>/dev/null && echo yes)"

STUB_FRAME= run --resume "fix the failing tests"
check "forwards arguments" "--resume fix the failing tests" "$(field args)"

STUB_FRAME= STUB_EXIT=42 run
check "propagates the exit code" "42" "$code"

STUB_FRAME= STUB_WAIT=3 DRIVER_TYPE="hello" run
check "forwards keystrokes" "hello" "$(field input)"

STUB_FRAME= STUB_WAIT=4 DRIVER_SIZE="40 100" run
check "follows a terminal resize" "40 100" "$(field size)"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
