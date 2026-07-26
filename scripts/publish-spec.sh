#!/usr/bin/env bash
set -euo pipefail

SPEC=""
PUBLISH=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --spec) shift; SPEC="$1" ;;
    --publish) PUBLISH=1 ;;
    *) echo "usage: $0 --spec /path/to/homebrew-formula.json [--publish]" >&2; exit 64 ;;
  esac
  shift
done
[ -f "$SPEC" ] || { echo "spec file not found" >&2; exit 66; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1])).repo)' "$SPEC")"
TAG="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1])).tag)' "$SPEC")"
FORMULA="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1])).formula)' "$SPEC")"
ARCHIVE="$(mktemp)"
trap 'rm -f "$ARCHIVE"' EXIT
curl --fail --location --silent --show-error "https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz" --output "$ARCHIVE"
SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
mkdir -p "$ROOT/Formula"
node "$ROOT/scripts/formula-generator.mjs" --spec "$SPEC" --sha256 "$SHA256" --output "$ROOT/Formula/$FORMULA.rb"
if [ "$PUBLISH" -eq 0 ]; then echo "wrote Formula/$FORMULA.rb; review it, then rerun with --publish"; exit 0; fi
git -C "$ROOT" diff --check
git -C "$ROOT" add "Formula/$FORMULA.rb"
git -C "$ROOT" commit -m "$FORMULA $TAG"
git -C "$ROOT" push origin main
