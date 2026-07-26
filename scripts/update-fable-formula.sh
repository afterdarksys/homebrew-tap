#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 v<version> [--publish]" >&2
  exit 64
fi

TAG="$1"
shift
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/publish-formula.sh" \
  --repo afterdarksys/ads-fable-skills \
  --tag "$TAG" \
  --formula fable \
  --class Fable \
  --description "Build, validate, and install reusable agent-neutral skills" \
  --install bin/fable.js \
  --node \
  --license MIT \
  "$@"
