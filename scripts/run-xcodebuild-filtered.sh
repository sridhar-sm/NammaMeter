#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: scripts/run-xcodebuild-filtered.sh <command> [args...]"
  echo "Example: scripts/run-xcodebuild-filtered.sh xcodebuild test -scheme NammaMeter"
  exit 64
fi

# Narrow suppression for known simulator launch-metrics noise.
readonly CA_EVENT_PREFIX='[General] Failed to send CA Event for app launch measurements'

set +e
"$@" 2>&1 | awk -v prefix="$CA_EVENT_PREFIX" 'index($0, prefix) == 0 { print }'
command_status=${PIPESTATUS[0]}
set -e

exit "$command_status"
