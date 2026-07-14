#!/usr/bin/env bash
# Import HostBora YAML test cases into Firebase App Distribution.
#
# Usage:
#   ./firebase_app_testing/import-tests.sh
#
# App ID is read from android/app/google-services.json unless FIREBASE_APP_ID is set.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GOOGLE_SERVICES="$ROOT_DIR/android/app/google-services.json"

read_app_id() {
  grep -o '"mobilesdk_app_id": "[^"]*"' "$GOOGLE_SERVICES" | head -1 | cut -d'"' -f4
}

APP_ID="${FIREBASE_APP_ID:-$(read_app_id)}"
PROJECT="${FIREBASE_PROJECT:-paa-yangu}"
TEST_DIR="$SCRIPT_DIR/tests"

firebase_cli() {
  if firebase help appdistribution:testcases:import 2>&1 | grep -q "is not a valid command"; then
    if [[ -z "${FIREBASE_UPGRADE_WARNED:-}" ]]; then
      echo "Note: firebase-tools $(firebase --version) has no appdistribution:testcases:import." >&2
      echo "      Using npx firebase-tools@latest. To upgrade globally:" >&2
      echo "        npm install -g firebase-tools@latest" >&2
      FIREBASE_UPGRADE_WARNED=1
    fi
    npx --yes firebase-tools@latest "$@"
  else
    firebase "$@"
  fi
}

echo "Project: $PROJECT"
echo "App ID:  $APP_ID"

firebase_cli --project "$PROJECT" appdistribution:testcases:import \
  --app="$APP_ID" \
  "$TEST_DIR"
