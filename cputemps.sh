#!/bin/sh

# List of sysctl parameters to query, space-separated
SYSCTL_PARAMS="
dev.cpu.0.temperature
dev.cpu.0.coretemp.throttle_log
dev.cpu.0.coretemp.tjmax
dev.cpu.0.coretemp.delta
dev.cpu.1.temperature
dev.cpu.1.coretemp.throttle_log
dev.cpu.1.coretemp.tjmax
dev.cpu.1.coretemp.delta
dev.cpu.2.temperature
dev.cpu.2.coretemp.throttle_log
dev.cpu.2.coretemp.tjmax
dev.cpu.2.coretemp.delta
dev.cpu.3.temperature
dev.cpu.3.coretemp.throttle_log
dev.cpu.3.coretemp.tjmax
dev.cpu.3.coretemp.delta
"

# Run sysctl and pipe output into nawk for JSON formatting
sysctl $SYSCTL_PARAMS | nawk '

BEGIN {
    print "["
    current_cpu = -1
}

/^dev\.cpu\.[0-9]+\./ {
    split($0, kv, ":")
    gsub(/^ +| +$/, "", kv[1])  # trim spaces
    gsub(/^ +| +$/, "", kv[2])  # trim spaces

    split(kv[1], parts, ".")
    cpu = parts[3]
    field = parts[4]

    if (cpu != current_cpu) {
        if (current_cpu != -1) {
            print "\n  },"
        }
        printf "  {\n    \"core\": %s", cpu
        current_cpu = cpu
    }

    gsub("C", "", kv[2])  # remove °C

    if (field == "temperature") {
        printf ",\n    \"temperature\": %.1f", kv[2]
    } else if (field == "coretemp") {
        metric = parts[5]
        if (metric == "throttle_log") {
            printf ",\n    \"throttle_log\": %d", kv[2]
        } else if (metric == "tjmax") {
            printf ",\n    \"tjmax\": %.1f", kv[2]
        } else if (metric == "delta") {
            printf ",\n    \"delta\": %d", kv[2]
        }
    }
}

END {
    if (current_cpu != -1) {
        print "\n  }"
    }
    print "]"
}
'

