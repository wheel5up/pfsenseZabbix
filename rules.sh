#!/bin/sh

pfctl -vv -sr | /usr/bin/nawk '
BEGIN {
  print "["
  first = 1
}

/^@/ {
  if (!first) {
    printf(",\n")
  }
  first = 0

  # Reset fields
  rule_number = ""
  raw = $0
  action_type = ""
  direction = ""
  log_flag = "false"
  quick = "false"
  interface = ""
  label = ""
  proto = ""
  ridentifier = ""
  evaluations = 0
  packets = 0
  bytes = 0
  states = 0

  # Extract rule number from @
  rule_number = substr($1, 2)

  # Action type is second field
  action_type = $2

  # Parse known attributes from early fields only
  for (i = 2; i <= 12 && i <= NF; i++) {
    if ($i == "in") {
      direction = "in"; coef = 1
    } else if ($i == "out") {
      direction = "out"; coef = -1
    } else if ($i == "log") log_flag = "true"
    else if ($i == "quick") quick = "true"
    else if ($i == "on" && (i + 1) <= NF) interface = $(i + 1)
    else if ($i == "proto" && (i + 1) <= NF) proto = $(i + 1)
    else if ($i == "inet") family = "ipv4"
    else if ($i == "inet6") family = "ipv6"
  }

  pos = index($0, "label \"")
  if (pos > 0) {
    rest = substr($0, pos + 7) 
    endquote = index(rest, "\"")
    if (endquote > 0) {
      label = substr(rest, 1, endquote - 1)
      gsub(/"/, "\\\"", label)
    }
  }

  # Extract ridentifier
  for (i = 1; i < NF; i++) {
    if ($i == "ridentifier" && (i + 1) <= NF) {
      ridentifier = $(i + 1)
      break
    }
  }

  # Escape double quotes in raw line
  gsub(/"/, "\\\"", raw)

  # Save rule line and set active flag
  rule_raw = raw
  rule_active = 1
}

/Evaluations:/ && rule_active {
  gsub(/\[|\]/, "")
  for (i = 1; i <= NF; i++) {
    if ($i == "Evaluations:") evaluations = $(i + 1)
    else if ($i == "Packets:") packets = $(i + 1)
    else if ($i == "Bytes:") bytes = $(i + 1)
    else if ($i == "States:") states = $(i + 1)
  }

  printf("{\"rule_number\":%s,", rule_number)
  #printf("\"raw\":\"%s\",", rule_raw)
  printf("\"action_type\":\"%s\",", action_type)
  printf("\"log_flag\":%s,", log_flag)
  printf("\"quick\":%s,", quick)
  printf("\"interface\":\"%s\",", interface)
  printf("\"direction\":\"%s\",", direction)
  printf("\"family\":\"%s\",", family)
  printf("\"coef\":\"%s\",", coef)
  printf("\"proto\":\"%s\",", proto)
  printf("\"label\":\"%s\",", label)
  printf("\"ridentifier\":\"%s\",", ridentifier)
  printf("\"evaluations\":%s,", evaluations)
  printf("\"packets\":%s,", packets)
  printf("\"bytes\":%s,", bytes)
  printf("\"states\":%s}", states)

  rule_active = 0
}

END {
  print "\n]"
}
'
