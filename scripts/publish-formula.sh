#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: publish-formula.sh --repo owner/repo --tag vX.Y.Z --formula name \
  --class FormulaClass --description "one sentence" --install path [--node] \
  [--license SPDX] [--publish]

Writes Formula/name.rb from an immutable GitHub tag archive. The installed path
must be an executable script in the source archive. Use --node for Node CLIs.
Without --publish, this only writes the formula for review.
EOF
  exit 64
}

REPO=""
TAG=""
FORMULA=""
CLASS=""
DESCRIPTION=""
INSTALL=""
LICENSE="MIT"
NODE=0
PUBLISH=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) shift; REPO="$1" ;;
    --tag) shift; TAG="$1" ;;
    --formula) shift; FORMULA="$1" ;;
    --class) shift; CLASS="$1" ;;
    --description) shift; DESCRIPTION="$1" ;;
    --install) shift; INSTALL="$1" ;;
    --license) shift; LICENSE="$1" ;;
    --node) NODE=1 ;;
    --publish) PUBLISH=1 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
  shift
done

[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || usage
[[ "$TAG" =~ ^v[0-9]+[.][0-9]+[.][0-9]+([.-][A-Za-z0-9._-]+)?$ ]] || usage
[[ "$FORMULA" =~ ^[a-z0-9][a-z0-9@._-]*$ ]] || usage
[[ "$CLASS" =~ ^[A-Z][A-Za-z0-9]*$ ]] || usage
[[ "$INSTALL" =~ ^[A-Za-z0-9._/-]+$ && "$INSTALL" != *".."* ]] || usage
[[ -n "$DESCRIPTION" && "$DESCRIPTION" != *'"'* && "$DESCRIPTION" != *$'\n'* ]] || usage
[[ "$LICENSE" =~ ^[A-Za-z0-9.-]+$ ]] || usage

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$ROOT/Formula/$FORMULA.rb"
ARCHIVE="$(mktemp)"
trap 'rm -f "$ARCHIVE"' EXIT
URL="https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz"

curl --fail --location --silent --show-error "$URL" --output "$ARCHIVE"
SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
mkdir -p "$ROOT/Formula"

{
  printf 'class %s < Formula\n' "$CLASS"
  printf '  desc "%s"\n' "$DESCRIPTION"
  printf '  homepage "https://github.com/%s"\n' "$REPO"
  printf '  url "%s"\n' "$URL"
  printf '  sha256 "%s"\n' "$SHA256"
  printf '  license "%s"\n\n' "$LICENSE"
  if [ "$NODE" -eq 1 ]; then
    printf '  depends_on "node"\n\n'
  fi
  printf '  def install\n'
  printf '    libexec.install Dir["*"]\n'
  if [ "$NODE" -eq 1 ]; then
    printf '    (bin/"%s").write_env_script libexec/"%s",\n' "$FORMULA" "$INSTALL"
    printf '      PATH: "#{Formula["node"].opt_bin}:#{ENV["PATH"]}"\n'
  else
    printf '    bin.write_exec_script libexec/"%s"\n' "$INSTALL"
  fi
  printf '  end\n\n'
  printf '  test do\n'
  printf '    assert_predicate bin/"%s", :executable?\n' "$FORMULA"
  printf '  end\n'
  printf 'end\n'
} > "$TARGET"

echo "wrote $TARGET for $REPO $TAG"
if [ "$PUBLISH" -eq 0 ]; then
  echo "review it, then rerun with --publish to commit and push"
  exit 0
fi

git -C "$ROOT" diff --check
git -C "$ROOT" add "Formula/$FORMULA.rb"
git -C "$ROOT" commit -m "$FORMULA $TAG"
git -C "$ROOT" push origin main
