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

extract_structured_endgate_carrier_object() {
    local file="$1"

    if ! command -v jq >/dev/null 2>&1; then
        return 0
    fi

    jq -c -nR '
        def normalized_endgate:
            if (.type // "") == "response_item" and ((.payload.metadata.endgate // null) | type) == "object" then
                .payload.metadata.endgate
            elif ((.item.metadata.endgate // null) | type) == "object" then
                .item.metadata.endgate
            else
                empty
            end;

        [inputs | (fromjson? // empty) | normalized_endgate] | last // empty
    ' < "$file"
}

structured_endgate_carrier_is_complete() {
    local carrier="$1"

    if [ -z "$carrier" ] || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    printf '%s\n' "$carrier" | jq -e '
        . as $carrier
        | type == "object"
        and (
            [
                "ENDGATE_PROTOCOL_VERSION",
                "ENDGATE_STATE",
                "ENDGATE_CHOICE_KIND",
                "ENDGATE_NEXT_ACTION"
            ]
            | all(.[]; ($carrier[.]? | type) == "string" and (($carrier[.] // "") | length > 0))
        )
    ' >/dev/null 2>&1
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

print_valid_visible_endgate_packet_block() {
    local file="$1"
    local block

    block="$(print_endgate_packet_block "$file")"

    if [ -z "$block" ]; then
        return 0
    fi

    if printf '%s\n' "$block" | awk '
        BEGIN {
            required["ENDGATE_PROTOCOL_VERSION"] = 1
            required["ENDGATE_STATE"] = 1
            required["ENDGATE_CHOICE_KIND"] = 1
            required["ENDGATE_NEXT_ACTION"] = 1
        }
        /^ENDGATE_[A-Z_]+: / {
            key = substr($0, 1, index($0, ": ") - 1)
            value = substr($0, index($0, ": ") + 2)
            count[key]++
            if (count[key] == 1) {
                first_value[key] = value
            }
        }
        END {
            valid = 1
            for (key in required) {
                if (count[key] != 1 || first_value[key] == "") {
                    valid = 0
                }
            }
            exit(valid ? 0 : 1)
        }
    '; then
        printf '%s\n' "$block"
    fi
}

normalize_visible_endgate_packet_to_carrier_object() {
    local file="$1"
    local block

    block="$(print_valid_visible_endgate_packet_block "$file")"

    if [ -z "$block" ] || ! command -v jq >/dev/null 2>&1; then
        return 0
    fi

    printf '%s\n' "$block" | jq -Rn '
        [
            inputs
            | select(test("^ENDGATE_[A-Z_]+: "))
            | capture("^(?<key>ENDGATE_[A-Z_]+): (?<value>.*)$")
        ]
        | from_entries
    '
}

print_endgate_carrier_object() {
    local file="$1"
    local structured_carrier
    local fallback_carrier

    structured_carrier="$(extract_structured_endgate_carrier_object "$file")"
    if structured_endgate_carrier_is_complete "$structured_carrier"; then
        printf '%s\n' "$structured_carrier"
        return 0
    fi

    fallback_carrier="$(normalize_visible_endgate_packet_to_carrier_object "$file")"
    if [ -n "$fallback_carrier" ]; then
        printf '%s\n' "$fallback_carrier"
    fi
}

extract_endgate_carrier_kind() {
    local file="$1"
    local structured_carrier
    local valid_visible_block

    structured_carrier="$(extract_structured_endgate_carrier_object "$file")"
    if structured_endgate_carrier_is_complete "$structured_carrier"; then
        printf 'structured\n'
        return 0
    fi

    valid_visible_block="$(print_valid_visible_endgate_packet_block "$file")"
    if [ -n "$valid_visible_block" ]; then
        printf 'visible_tail_block\n'
    fi
}

extract_endgate_carrier_field() {
    local file="$1"
    local key="$2"
    local structured_carrier
    local valid_visible_block

    structured_carrier="$(extract_structured_endgate_carrier_object "$file")"
    if structured_endgate_carrier_is_complete "$structured_carrier"; then
        printf '%s\n' "$structured_carrier" | jq -r --arg key "$key" '.[$key] // empty'
        return 0
    fi

    valid_visible_block="$(print_valid_visible_endgate_packet_block "$file")"
    if [ -n "$valid_visible_block" ]; then
        printf '%s\n' "$valid_visible_block" | extract_endgate_packet_field_from_text "$key"
    fi
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
    extract_endgate_carrier_field "$file" "$key"
}
