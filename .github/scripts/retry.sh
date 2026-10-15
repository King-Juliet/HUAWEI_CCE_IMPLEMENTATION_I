#!/usr/bin/env bash
# Source this file, then run:  retry <command> [args...]
# Re-runs the command only when it failed because the cluster API connection dropped
# (connection refused / unreachable / timeout). Any other failure stops straight away,
# so real errors are not hidden behind retries.
retry() {
  local i out rc
  for i in 1 2 3 4 5 6 7 8; do
    out=$("$@" 2>&1) && rc=0 || rc=$?
    echo "$out"
    [ "$rc" -eq 0 ] && return 0
    if echo "$out" | grep -qiE 'connection refused|cluster unreachable|i/o timeout|TLS handshake timeout|connection reset|unexpected EOF'; then
      echo "API connection problem (attempt $i/8) - retrying in 15s"
      sleep 15
    else
      return "$rc"
    fi
  done
  return 1
}