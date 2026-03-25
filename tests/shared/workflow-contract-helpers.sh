#!/usr/bin/env bash

print_machine_readable_tail_block() {
    local file="$1"

    # 只解析文件末尾连续的 KEY: value 区块，忽略前文同名字段。
    awk '
        { lines[NR] = $0 }
        END {
            line_index = NR

            while (line_index > 0 && lines[line_index] ~ /^[[:space:]]*$/) {
                line_index--
            }

            if (line_index == 0) {
                exit
            }

            if (lines[line_index] !~ /^[A-Z0-9_]+: .*$/) {
                exit
            }

            block_start = line_index
            while (block_start > 0 && lines[block_start] ~ /^[A-Z0-9_]+: .*$/) {
                block_start--
            }

            for (current = block_start + 1; current <= line_index; current++) {
                print lines[current]
            }
        }
    ' "$file"
}

assert_named_field() {
    local file="$1"
    local key="$2"
    local pattern="$3"
    local test_name="$4"

    local value
    value="$(extract_unique_named_tail_field "$file" "$key")"

    if [ -n "$value" ] && printf '%s\n' "$value" | rg -q "^(${pattern})$"; then
        echo "  [PASS] $test_name"
        return 0
    fi

    echo "  [FAIL] $test_name"
    echo "  Missing: ^${key}: (${pattern})$"
    return 1
}

extract_named_field() {
    local file="$1"
    local key="$2"

    extract_unique_named_tail_field "$file" "$key"
}

extract_unique_named_tail_field() {
    local file="$1"
    local key="$2"

    # 同一个 key 在最终 tail block 中必须且只能出现一次。
    print_machine_readable_tail_block "$file" | awk -v key="$key" '
        index($0, key ": ") == 1 {
            count++
            value = substr($0, length(key) + 3)
        }
        END {
            if (count == 1) {
                print value
            }
        }
    '
}

print_endgate_packet_block_from_text() {
    awk '
        { lines[NR] = $0 }
        END {
            line_index = NR

            while (line_index > 0 && lines[line_index] !~ /^ENDGATE_[A-Z_]+: .*$/) {
                line_index--
            }

            if (line_index == 0) {
                exit
            }

            block_start = line_index
            while (block_start > 0 && lines[block_start] ~ /^ENDGATE_[A-Z_]+: .*$/) {
                block_start--
            }

            for (current = block_start + 1; current <= line_index; current++) {
                print lines[current]
            }
        }
    '
}

extract_endgate_packet_field_from_text() {
    local key="$1"

    print_endgate_packet_block_from_text | awk -v key="$key" '
        index($0, key ": ") == 1 {
            count++
            value = substr($0, length(key) + 3)
        }
        END {
            if (count == 1) {
                print value
            }
        }
    '
}

print_endgate_packet_block() {
    local file="$1"
    print_endgate_packet_block_from_text < "$file"
}

extract_endgate_packet_field() {
    local file="$1"
    local key="$2"
    extract_endgate_packet_field_from_text "$key" < "$file"
}
