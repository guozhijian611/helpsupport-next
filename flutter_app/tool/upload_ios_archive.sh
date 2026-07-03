#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARCHIVE_PATH="${ARCHIVE_PATH:-${FLUTTER_APP_DIR}/build/ios/archive/Runner.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-${FLUTTER_APP_DIR}/build/ios/upload}"
TEAM_ID="${TEAM_ID:-33ZX95D3LJ}"
UPLOAD_SYMBOLS="${UPLOAD_SYMBOLS:-1}"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not found"
}

bool_plist_value() {
  if [[ "$1" == "1" ]]; then
    printf '<true/>'
  else
    printf '<false/>'
  fi
}

validate_archive_has_no_unsupported_dylibs() {
  local app_dir dylib dylib_name
  local -a unsupported_dylibs=()

  while IFS= read -r -d '' app_dir; do
    while IFS= read -r dylib; do
      dylib_name="$(basename "${dylib}")"
      [[ "${dylib_name}" == libswift* ]] && continue
      unsupported_dylibs+=("${dylib#${ARCHIVE_PATH}/Products/Applications/}")
    done < <(find "${app_dir}" -name '*.dylib' -print 2>/dev/null)
  done < <(find "${ARCHIVE_PATH}/Products/Applications" -maxdepth 1 -type d -name '*.app' -print0)

  if [[ "${#unsupported_dylibs[@]}" -gt 0 ]]; then
    printf 'Error: Archive contains unsupported embedded dylibs. Package native libraries as .framework bundles and rebuild the archive before upload:\n' >&2
    printf '  %s\n' "${unsupported_dylibs[@]}" >&2
    exit 1
  fi
}

usage() {
  cat <<'USAGE'
Upload HelpSupport iOS archive directly to App Store Connect/TestFlight.

This uses Xcode's archive upload flow instead of dragging a local IPA into
Transporter. Use it for App Store/TestFlight uploads when SwiftSupport
validation rejects the exported IPA.

Usage:
  ./tool/upload_ios_archive.sh

Environment:
  ARCHIVE_PATH      Path to Runner.xcarchive. Default: build/ios/archive/Runner.xcarchive
  EXPORT_PATH       Temporary Xcode export/upload output directory. Default: build/ios/upload
  TEAM_ID           Apple Developer Team ID. Default: 33ZX95D3LJ
  UPLOAD_SYMBOLS=0  Disable dSYM upload warnings for third-party native libs.
  SKIP_DISTRIBUTION_SIGNING_CHECK=1
                    Skip the local Apple Distribution certificate preflight.
USAGE
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  '')
    ;;
  *)
    fail "Unknown argument: $1"
    ;;
esac

require_command xcodebuild
require_command mktemp

[[ -d "${ARCHIVE_PATH}" ]] || fail "Archive not found: ${ARCHIVE_PATH}. Build it first with ./tool/package_release.sh ipa --export-method app-store."
validate_archive_has_no_unsupported_dylibs

if [[ "${SKIP_DISTRIBUTION_SIGNING_CHECK:-0}" != "1" ]]; then
  require_command security
  if ! security find-identity -v -p codesigning | grep -Eq '"(Apple Distribution|iOS Distribution):'; then
    fail "Apple Distribution signing identity not found. TestFlight/App Store uploads require a distribution-signed export. Open Xcode > Settings > Accounts > Manage Certificates and create/download Apple Distribution first."
  fi
fi

mkdir -p "${EXPORT_PATH}"
options_plist="$(mktemp "${TMPDIR:-/tmp}/helpsupport-upload-options.XXXXXX.plist")"
trap 'rm -f "${options_plist}"' EXIT

cat > "${options_plist}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>upload</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>uploadSymbols</key>
  $(bool_plist_value "${UPLOAD_SYMBOLS}")
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${options_plist}" \
  -allowProvisioningUpdates
