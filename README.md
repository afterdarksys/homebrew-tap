# Afterdark Homebrew Tap

This tap publishes Homebrew formulae maintained by Afterdark Systems.

Install a published formula:

    brew tap afterdarksys/tap
    brew install formula-name

## Publish a script or Node CLI

Create and push a version tag in the source repository, then run this from the
tap checkout:

    scripts/publish-formula.sh \
      --repo afterdarksys/project-name \
      --tag v1.2.3 \
      --formula project-name \
      --class ProjectName \
      --description "One clear sentence" \
      --install bin/project-name \
      --publish

Add --node when the executable requires Node. The script downloads the immutable
GitHub tag archive, calculates its SHA-256, writes Formula/project-name.rb, and
commits/pushes only when --publish is present. Omit --publish to inspect the
formula first.

The formula generator is for already-executable scripts and Node CLIs. Compiled
projects need an explicit build recipe in their formula; start with a generated
formula only if its archive already contains the executable you intend to run.

## Fable

Use:

    scripts/publish-formula.sh \
      --repo afterdarksys/ads-fable-skills \
      --tag v0.1.0 \
      --formula fable \
      --class Fable \
      --description "Build, validate, and install reusable agent-neutral skills" \
      --install bin/fable.js \
      --node \
      --publish
