#!/usr/bin/env bash
# Helper functions for Claude Code skill tests

TEST_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_HELPERS_DIR/../shared/workflow-contract-helpers.sh"

# Run Claude Code with a prompt and capture output
# Usage: run_claude "prompt text" [timeout_seconds] [allowed_tools]
run_claude() {
    local prompt="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-}"
    local output_file=$(mktemp)

    # Build command
    local cmd="claude -p \"$prompt\""
    if [ -n "$allowed_tools" ]; then
        cmd="$cmd --allowed-tools=$allowed_tools"
    fi

    # Run Claude in headless mode with timeout
    if timeout "$timeout" bash -c "$cmd" > "$output_file" 2>&1; then
        cat "$output_file"
        rm -f "$output_file"
        return 0
    else
        local exit_code=$?
        cat "$output_file" >&2
        rm -f "$output_file"
        return $exit_code
    fi
}

# Check if output contains a pattern
# Usage: assert_contains "output" "pattern" "test name"
assert_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -q "$pattern"; then
        echo "  [PASS] $test_name"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if output does NOT contain a pattern
# Usage: assert_not_contains "output" "pattern" "test name"
assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -q "$pattern"; then
        echo "  [FAIL] $test_name"
        echo "  Did not expect to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    else
        echo "  [PASS] $test_name"
        return 0
    fi
}

# Check if output matches a count
# Usage: assert_count "output" "pattern" expected_count "test name"
assert_count() {
    local output="$1"
    local pattern="$2"
    local expected="$3"
    local test_name="${4:-test}"

    local actual=$(echo "$output" | grep -c "$pattern" || echo "0")

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $test_name (found $actual instances)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected $expected instances of: $pattern"
        echo "  Found $actual instances"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if pattern A appears before pattern B
# Usage: assert_order "output" "pattern_a" "pattern_b" "test name"
assert_order() {
    local output="$1"
    local pattern_a="$2"
    local pattern_b="$3"
    local test_name="${4:-test}"

    # Get line numbers where patterns appear
    local line_a=$(echo "$output" | grep -n "$pattern_a" | head -1 | cut -d: -f1)
    local line_b=$(echo "$output" | grep -n "$pattern_b" | head -1 | cut -d: -f1)

    if [ -z "$line_a" ]; then
        echo "  [FAIL] $test_name: pattern A not found: $pattern_a"
        return 1
    fi

    if [ -z "$line_b" ]; then
        echo "  [FAIL] $test_name: pattern B not found: $pattern_b"
        return 1
    fi

    if [ "$line_a" -lt "$line_b" ]; then
        echo "  [PASS] $test_name (A at line $line_a, B at line $line_b)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected '$pattern_a' before '$pattern_b'"
        echo "  But found A at line $line_a, B at line $line_b"
        return 1
    fi
}

# Create a temporary test project directory
# Usage: test_project=$(create_test_project)
create_test_project() {
    local test_dir=$(mktemp -d)
    echo "$test_dir"
}

# Cleanup test project
# Usage: cleanup_test_project "$test_dir"
cleanup_test_project() {
    local test_dir="$1"
    if [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

# Create a simple plan file for testing
# Usage: create_test_plan "$project_dir" "$plan_name"
create_test_plan() {
    local project_dir="$1"
    local plan_name="${2:-test-plan}"
    local plan_file="$project_dir/docs/superpowers/plans/$plan_name.md"

    mkdir -p "$(dirname "$plan_file")"

    cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Task 1: Create Hello Function

Create a simple hello function that returns "Hello, World!".

**File:** `src/hello.js`

**Implementation:**
```javascript
export function hello() {
  return "Hello, World!";
}
```

**Tests:** Write a test that verifies the function returns the expected string.

**Verification:** `npm test`

## Task 2: Create Goodbye Function

Create a goodbye function that takes a name and returns a goodbye message.

**File:** `src/goodbye.js`

**Implementation:**
```javascript
export function goodbye(name) {
  return `Goodbye, ${name}!`;
}
```

**Tests:** Write tests for:
- Default name
- Custom name
- Edge cases (empty string, null)

**Verification:** `npm test`
EOF

    echo "$plan_file"
}

find_latest_session_file() {
    local working_dir="$1"
    local since_epoch="${2:-}"
    local escaped_working_dir
    local session_dir
    local latest_file=""
    local latest_mtime=""

    escaped_working_dir=$(printf '%s' "$working_dir" | sed 's#/#-#g; s#^-##')
    session_dir="$HOME/.claude/projects/$escaped_working_dir"

    if [ ! -d "$session_dir" ]; then
        return 1
    fi

    while IFS= read -r session_file; do
        local session_mtime=""

        if [ -z "$session_file" ] || [ ! -f "$session_file" ]; then
            continue
        fi

        session_mtime=$(stat -f '%m' "$session_file" 2>/dev/null || stat -c '%Y' "$session_file" 2>/dev/null || true)

        if [ -z "$session_mtime" ]; then
            continue
        fi

        if [ -n "$since_epoch" ] && [ "$session_mtime" -lt "$since_epoch" ]; then
            continue
        fi

        if [ -z "$latest_mtime" ] || [ "$session_mtime" -gt "$latest_mtime" ]; then
            latest_mtime="$session_mtime"
            latest_file="$session_file"
        fi
    done < <(find "$session_dir" -name "*.jsonl" -type f 2>/dev/null)

    if [ -n "$latest_file" ]; then
        echo "$latest_file"
        return 0
    fi

    return 1
}

print_session_text() {
    local session_file="$1"

    sed 's#\\\\/#/#g; s/\\\\r//g; s/\\\\n/\
/g; s#\\/#/#g; s/\\r//g; s/\\n/\
/g' "$session_file"
}

assert_session_contains() {
    local session_file="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if rg -q -- "$pattern" "$session_file"; then
        echo "  [PASS] $test_name"
        return 0
    fi

    echo "  [FAIL] $test_name"
    echo "  Pattern: $pattern"
    echo "  Session file: $session_file"
    return 1
}

assert_session_not_contains() {
    local session_file="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if rg -q -- "$pattern" "$session_file"; then
        echo "  [FAIL] $test_name"
        echo "  Unexpected pattern: $pattern"
        echo "  Session file: $session_file"
        return 1
    fi

    echo "  [PASS] $test_name"
    return 0
}

assert_session_contains_literal() {
    local session_file="$1"
    local text="$2"
    local test_name="${3:-test}"

    if print_session_text "$session_file" | rg -F -q -- "$text"; then
        echo "  [PASS] $test_name"
        return 0
    fi

    echo "  [FAIL] $test_name"
    echo "  Expected literal: $text"
    echo "  Session file: $session_file"
    return 1
}

assert_session_contains_exact_line() {
    local session_file="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if print_session_text "$session_file" | rg -q -- "^${pattern}([[:space:]]*\"[}\\],:]*)?\$"; then
        echo "  [PASS] $test_name"
        return 0
    fi

    echo "  [FAIL] $test_name"
    echo "  Missing exact line: ^${pattern}([[:space:]]*\"[}\\],:]*)?\$"
    echo "  Session file: $session_file"
    return 1
}

bootstrap_sdd_smoke_project() {
    local project_dir="$1"

    mkdir -p "$project_dir/src" "$project_dir/test" "$project_dir/docs/superpowers/plans"

    cat > "$project_dir/package.json" <<'EOF'
{
  "name": "sdd-smoke-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
EOF

    cat > "$project_dir/docs/superpowers/plans/implementation-plan.md" <<'EOF'
# SDD Smoke Plan

## Task 1: Add the math helper

Create `src/math.js` with one exported `add(a, b)` function and `test/math.test.js` with one passing `node --test` case for `add(2, 3) === 5`.

Verification: `npm test`
EOF

    git -C "$project_dir" init --quiet
    git -C "$project_dir" config user.email "test@test.com"
    git -C "$project_dir" config user.name "Test User"
    git -C "$project_dir" add .
    git -C "$project_dir" commit -m "Initial smoke fixture" --quiet
}

# Export functions for use in tests
export -f run_claude
export -f assert_contains
export -f assert_not_contains
export -f assert_count
export -f assert_order
export -f create_test_project
export -f cleanup_test_project
export -f create_test_plan
export -f find_latest_session_file
export -f print_session_text
export -f assert_session_contains
export -f assert_session_not_contains
export -f assert_session_contains_literal
export -f assert_session_contains_exact_line
export -f bootstrap_sdd_smoke_project
