#!/bin/sh

# Usage check
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <interface1> <interface2> ..."
  exit 1
fi

# Create temp file to collect pfctl output
TMPFILE=$(mktemp)

# Run pfctl per interface and collect output
for iface in "$@"; do
  pfctl -vv -s Interfaces -i "$iface" >> "$TMPFILE"
done

# Inline nawk parser to emit a JSON array
nawk '
BEGIN {
  print "["
  first = 1
}

NF == 1 {
  if (!first) {
    printf "  {\n    \"interface\": \"%s\",\n    \"cleared\": \"%s\",\n    \"references\": %d,\n    \"stats\": [\n      %s\n    ]\n  },\n", iface, cleared, references, stat_block
  }
  iface = $1
  cleared = ""
  references = 0
  stat_block = ""
  first = 0
  next
}

/Cleared:/ {
  sub(/^.*Cleared:[ \t]+/, "")
  cleared = $0
  next
}

/References:/ {
  references = $2
  next
}

/(Pass|Block):[ \t]+\[ Packets:/ {
  gsub(/\[/, "")
  gsub(/\]/, "")
  type = $1
  gsub(":", "", type)
  pkt = bytes = ""
  for (i = 1; i <= NF; i++) {
    if ($i == "Packets:") pkt = $(i+1)
    if ($i == "Bytes:")   bytes = $(i+1)
  }
  if (type ~ /^In4/) {
    direction = "in"; version = "ipv4"; coef = 1
  } else if (type ~ /^Out4/) {
    direction = "out"; version = "ipv4"; coef = -1
  } else if (type ~ /^In6/) {
    direction = "in"; version = "ipv6"; coef = 1
  } else if (type ~ /^Out6/) {
    direction = "out"; version = "ipv6"; coef = -1
  } else {
    direction = ""; version = ""
  }
  if (type ~ /Pass$/) {
      action = "pass"
  } else if (type ~ /Block$/) {
      action = "block"
  } else {
      action = "unknown"
  }

  stats_json = sprintf("{ \"type\": \"%s\", \"interface\": \"%s\", \"packets\": %s, \"bytes\": %s, \"direction\": \"%s\", \"version\": \"%s\", \"action\": \"%s\", \"coef\": %d }",
                       type, iface, pkt, bytes, direction, version, action, coef)

  stat_block = (stat_block == "" ? stats_json : stat_block ",\n      " stats_json)
  next
}

END {
  if (iface != "") {
    printf "  {\n    \"interface\": \"%s\",\n    \"cleared\": \"%s\",\n    \"references\": %d,\n    \"stats\": [\n      %s\n    ]\n  }\n", iface, cleared, references, stat_block
  }
  print "]"
}
' "$TMPFILE"
# Clean up
rm "$TMPFILE"

