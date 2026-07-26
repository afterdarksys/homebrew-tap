# Afterdark Homebrew Tap

This tap publishes Homebrew formulae maintained by Afterdark Systems.

Once installed, users can add the tap and install Fable with:

    brew tap afterdarksys/tap
    brew install fable

## Publishing Fable

First create and push a version tag in afterdarksys/ads-fable-skills. Then run:

    scripts/update-fable-formula.sh v0.1.0 --publish

The script downloads the immutable GitHub tag archive, calculates its SHA-256,
updates Formula/fable.rb, commits the formula, and pushes this tap. Without
--publish it only writes the formula so it can be reviewed first.
