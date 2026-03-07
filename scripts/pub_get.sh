#!/usr/bin/env bash
# Run this instead of "flutter pub get" to also regenerate localizations (appLocalization).
# Usage: ./scripts/pub_get.sh   or   bash scripts/pub_get.sh

set -e
cd "$(dirname "$0")/.."
flutter pub get
flutter gen-l10n
echo "Done: dependencies updated and l10n generated."
