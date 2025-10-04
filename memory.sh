#!/bin/sh

# List of sysctl keys to extract
SYSCTL_KEYS="
hw.pagesize
hw.realmem
vfs.bufspace
vm.stats.vm.v_cache_count
vm.stats.vm.v_user_wire_count
vm.stats.vm.v_laundry_count
vm.stats.vm.v_inactive_count
vm.stats.vm.v_active_count
vm.stats.vm.v_wire_count
vm.stats.vm.v_free_count
vm.stats.vm.v_page_count
"

# Run sysctl and format as JSON using nawk
sysctl $SYSCTL_KEYS | nawk '
BEGIN {
  print "{"
  first = 1
}

{
  split($0, kv, ":")
  gsub(/^ +| +$/, "", kv[1])  # trim spaces from key
  gsub(/^ +| +$/, "", kv[2])  # trim spaces from value

  key = kv[1]
  value = kv[2]

  # Extract just the short name (e.g., v_cache_count)
  n = split(key, parts, ".")
  short_key = parts[n]

  if (!first) {
    printf(",\n")
  }
  first = 0

  printf("  \"%s\": %s", short_key, value)
}

END {
  print "\n}"
}
'

