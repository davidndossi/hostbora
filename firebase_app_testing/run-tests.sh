#!/usr/bin/env bash
# Run HostBora Firebase App Testing agent suites against a local APK/AAB.
#
# Usage:
#   export TEST_PHONE="0701001001"
#   export TEST_PASSWORD="your-stage-password"
#   ./firebase_app_testing/run-tests.sh
#
# Optional:
#   SMOKE=1                         # auth login test only (recommended first run)
#   TEST_FILE_PATTERN="00-setup-auth"
#   TEST_NAME_PATTERN="Login with phone"
#   FIREBASE_DEBUG=1                # pass --debug to firebase CLI
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
APK_PATH="${1:-$ROOT_DIR/build/app/outputs/bundle/prodRelease/app-prod-release.aab}"
TEST_DIR="$SCRIPT_DIR/tests"
DEVICES_FILE="$SCRIPT_DIR/test-devices.txt"

if [[ ! -f "$APK_PATH" ]]; then
  echo "Binary not found: $APK_PATH" >&2
  echo "Build one first, e.g.:" >&2
  echo "  flutter build appbundle --flavor prod -t lib/main_prod.dart" >&2
  exit 1
fi

PASSWORD_FILE="$(mktemp)"
trap 'rm -f "$PASSWORD_FILE"' EXIT
printf '%s' "${TEST_PASSWORD:?Set TEST_PASSWORD}" > "$PASSWORD_FILE"

firebase_cli() {
  if firebase help apptesting:execute 2>&1 | grep -q "is not a valid command"; then
    if [[ -z "${FIREBASE_UPGRADE_WARNED:-}" ]]; then
      echo "Note: firebase-tools $(firebase --version) has no apptesting:execute." >&2
      echo "      Using npx firebase-tools@latest. To upgrade globally:" >&2
      echo "        npm install -g firebase-tools@latest" >&2
      FIREBASE_UPGRADE_WARNED=1
    fi
    npx --yes firebase-tools@latest "$@"
  else
    firebase "$@"
  fi
}

if [[ -n "${SMOKE:-}" ]]; then
  TEST_FILE_PATTERN="${TEST_FILE_PATTERN:-00-setup-auth}"
  TEST_NAME_PATTERN="${TEST_NAME_PATTERN:-Login with phone}"
fi

ARGS=(
  --project "$PROJECT"
  apptesting:execute
  --app="$APP_ID"
  --test-dir="$TEST_DIR"
  --test-devices-file="$DEVICES_FILE"
  --test-username="${TEST_PHONE:?Set TEST_PHONE}"
  --test-password-file="$PASSWORD_FILE"
)

if [[ -n "${TEST_FILE_PATTERN:-}" ]]; then
  ARGS+=(--test-file-pattern="$TEST_FILE_PATTERN")
fi
if [[ -n "${TEST_NAME_PATTERN:-}" ]]; then
  ARGS+=(--test-name-pattern="$TEST_NAME_PATTERN")
fi
if [[ -n "${FIREBASE_DEBUG:-}" ]]; then
  ARGS=(--debug "${ARGS[@]}")
fi

echo "Project:  $PROJECT"
echo "App ID:   $APP_ID"
echo "Binary:   $APK_PATH"
echo "Devices:  $DEVICES_FILE"

firebase_cli "${ARGS[@]}" "$APK_PATH"
