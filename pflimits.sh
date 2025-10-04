#!/bin/sh

pfctl -sm | /usr/bin/nawk '
BEGIN {
    print "{"
    first = 1
}
{
    key = $1
    value = $4

    if (!first) {
        printf(",\n")
    }
    printf("  \"%s\": %s", key, value)
    first = 0
}
END {
    print "\n}"
}'

