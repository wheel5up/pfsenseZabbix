#!/bin/sh

pfctl -vv -si | /usr/bin/nawk '
BEGIN {
    in_state_table = 0
    in_counters = 0
    in_limit_counters = 0
    print "["
    first = 1
}

# Detect section headers
/^State Table/ {
    in_state_table = 1
    in_counters = 0
    in_limit_counters = 0
    next
}

/^Counters$/ {
    in_state_table = 0
    in_counters = 1
    in_limit_counters = 0
    next
}

/^Limit Counters$/ {
    in_state_table = 0
    in_counters = 0
    in_limit_counters = 1
    next
}

# Exit current section if we hit a new unrelated section
/^[A-Za-z]/ && !/^\s/ && !/^State Table/ && !/^Counters$/ && !/^Limit Counters$/ {
    in_state_table = 0
    in_counters = 0
    in_limit_counters = 0
    next
}

# Parse relevant data lines
(in_state_table || in_counters || in_limit_counters) && NF >= 2 {
    section = in_state_table ? "state_table" : (in_counters ? "counters" : "limit_counters")

    # Handle special case: "current entries" with no rate
    if (in_state_table && $1 == "current" && $2 == "entries") {
        key = "current_entries"
        total = $3
        rate = "null"
    } else {
        key = ""
        for (i = 1; i <= NF - 2; i++) {
            key = key (i == 1 ? "" : " ") $i
        }

        total = $(NF - 1)
        rate = $(NF)

        if (rate ~ /^[0-9.]+\/s$/) {
            sub("/s", "", rate)
        } else if (total ~ /^[0-9]+$/) {
            rate = "null"
        } else {
            next  # Skip malformed lines
        }
    }

    if (!first) {
        printf(",\n")
    }
    first = 0

    printf("{\"section\":\"%s\", \"name\":\"%s\", \"total\":%s, \"rate\":%s}", section, key, total, rate)
}

END {
    print "\n]"
}'

