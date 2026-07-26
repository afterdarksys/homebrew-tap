#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 v<version> [--publish]" >&2
  exit 64
}

if [ "$#" -lt 1 ]; then usage; fi
TAG="$1"
PUBLISH=""
if [ "$#" -ge 2 ]; then PUBLISH="$2"; fi
[[ "$TAG" =~ ^v[0-9]+[.][0-9]+[.][0-9]+([.-][A-Za-z0-9._-]+)?$ ]] || usage
[[ -z "$PUBLISH" || "$PUBLISH" == "--publish" ]] || usage

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FORMULA="$ROOT/Formula/fable.rb"
ARCHIVE="$(mktemp)"
trap 'rm -f "$ARCHIVE"' EXIT
URL="https://github.com/afterdarksys/ads-fable-skills/archive/refs/tags/$TAG.tar.gz"

curl --fail --location --silent --show-error "$URL" --output "$ARCHIVE"
SHA256="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
mkdir -p "$(dirname "$FORMULA")"

cat > "$FORMULA" <<EOF
class Fable < Formula
  desc "Build, validate, and install reusable agent-neutral skills"
  homepage "https://github.com/afterdarksys/ads-fable-skills"
  url "$URL"
  sha256 "$SHA256"
  license "MIT"

  depends_on "node"

  def install
    libexec.install Dir["*"]
    (bin/"fable").write_env_script libexec/"bin/fable.js",
      PATH: "#{Formula["node"].opt_bin}:#{ENV["PATH"]}"
  end

  test do
    assert_match "fable", shell_output("#{bin}/fable --help")
  end
end
EOF

echo "wrote $FORMULA for $TAG"
if [[ "$PUBLISH" != "--publish" ]]; then
  echo "review it, then rerun with --publish to commit and push"
  exit 0
fi

git -C "$ROOT" diff --check
git -C "$ROOT" add Formula/fable.rb
git -C "$ROOT" commit -m "fable $TAG"
git -C "$ROOT" push origin main
