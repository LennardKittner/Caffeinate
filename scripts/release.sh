#!/bin/bash
# Build Caffeinate.app and package it as Caffeinate.app.zip — the same asset
# name the upstream repo attaches to its GitHub releases.
#
# After running this, publish with (pick your own tag/title/notes):
#   gh release create vX.Y.Z Caffeinate.app.zip --title "Version X.Y.Z" --notes "..."
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/make-app.sh

rm -f Caffeinate.app.zip
# Plain zip (-X drops AppleDouble/extra attributes, -y keeps symlinks) so the
# archive extracts cleanly with any unzipper — including chezmoi's Go extractor,
# which would otherwise leave stray ._* files inside the bundle. The ad-hoc code
# signature lives in the Mach-O and _CodeSignature/, so it survives this fine.
zip -r -X -y Caffeinate.app.zip Caffeinate.app >/dev/null
echo "Created Caffeinate.app.zip ($(du -h Caffeinate.app.zip | cut -f1))"
