# Afterdark Homebrew Tap

Install a published formula:

    brew tap afterdarksys/tap
    brew install formula-name

## Publish from a versioned project spec

Copy templates/homebrew-formula.json into a source repository and set its
metadata plus one build kind: script, node-script, python-script, go, rust,
cmake, make, or autotools. Then tag and push that source repository.

From this tap checkout:

    scripts/publish-spec.sh --spec ~/development/project/homebrew-formula.json

Review the generated Formula/project-name.rb. When it is right:

    scripts/publish-spec.sh --spec ~/development/project/homebrew-formula.json --publish

The generator downloads the immutable tag archive, calculates the SHA-256, and
selects a fixed recipe for the declared build kind. It does not accept arbitrary
build commands. Python package dependency graphs and unusual C build systems
need a hand-authored formula extension after generation.

## Quick path for scripts and Node CLIs

scripts/publish-formula.sh remains available for projects without a checked-in
spec. Fable also retains its short wrapper.

## License

MIT, see [LICENSE](LICENSE).
