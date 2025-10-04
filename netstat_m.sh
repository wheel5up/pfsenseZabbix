#!/bin/sh

netstat -m | /usr/bin/nawk '
BEGIN {
  printf("[\n")
  obj_count = 0
}

/^[0-9]+\/[0-9]+\/[0-9]+ mbufs in use/ {
  split($1, a, "/")
  if (obj_count++ > 0) printf(",\n")
  printf("  {\n")
  printf("    \"type\": \"mbufs_in_use\",\n")
  printf("    \"current\": %d,\n", a[1])
  printf("    \"cache\": %d,\n", a[2])
  printf("    \"total\": %d\n", a[3])
  printf("  }")
}

/^[0-9]+\/[0-9]+\/[0-9]+\/[0-9]+ mbuf clusters in use/ {
  split($1, a, "/")
  if (obj_count++ > 0) printf(",\n")
  printf("  {\n")
  printf("    \"type\": \"mbuf_clusters_in_use\",\n")
  printf("    \"current\": %d,\n", a[1])
  printf("    \"cache\": %d,\n", a[2])
  printf("    \"total\": %d,\n", a[3])
  printf("    \"max\": %d\n", a[4])
  printf("  }")
}

/^[0-9]+K\/[0-9]+K\/[0-9]+K bytes allocated/ {
  split($1, a, "K/")
  gsub("K", "", a[3])
  if (obj_count++ > 0) printf(",\n")
  printf("  {\n")
  printf("    \"type\": \"bytes_allocated\",\n")
  printf("    \"current_kb\": %d,\n", a[1])
  printf("    \"cache_kb\": %d,\n", a[2])
  printf("    \"total_kb\": %d\n", a[3])
  printf("  }")
}

END {
  printf("\n]\n")
}
'
