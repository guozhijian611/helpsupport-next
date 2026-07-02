#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBSPEC="${FLUTTER_APP_DIR}/pubspec.yaml"

DEFAULT_VERSION="$(awk -F'[:+ ]+' '$1 == "version" { print $2; exit }' "${PUBSPEC}")"
DEFAULT_BUILD_NUMBER="$(awk -F'[:+ ]+' '$1 == "version" { print $3; exit }' "${PUBSPEC}")"

BUILD_NAME="${BUILD_NAME:-${DEFAULT_VERSION:-1.0.0}}"
BUILD_NUMBER="${BUILD_NUMBER:-${DEFAULT_BUILD_NUMBER:-1}}"
EXPORT_METHOD="${EXPORT_METHOD:-app-store}"
RUN_PUB_GET="${PUB_GET:-1}"
RUN_CLEAN="${CLEAN:-0}"
BUILD_ANDROID_LLAMA="${BUILD_ANDROID_LLAMA:-0}"
SPLIT_PER_ABI="${SPLIT_PER_ABI:-0}"
DRY_RUN="${DRY_RUN:-0}"
TARGETS=()

usage() {
  cat <<'USAGE'
Build HelpSupport Flutter release artifacts.

Usage:
  ./tool/package_release.sh [target...] [options]

Targets:
  all                 Build apk, aab, and ipa. Default.
  android             Build apk and aab.
  ios                 Build ipa.
  apk                 Build Android APK.
  aab                 Build Android App Bundle.
  ipa                 Build iOS IPA.

Options:
  --build-name VALUE      Version name, for example 1.0.0.
  --build-number VALUE    Build number, for example 12.
  --export-method VALUE   iOS export method: app-store, ad-hoc, development, enterprise.
                          Default: app-store.
  --split-per-abi         Build Android APKs split by ABI.
  --android-llama         Rebuild Android llama native runtime before Android artifacts.
  --clean                 Run flutter clean before packaging.
  --no-pub-get            Skip flutter pub get.
  --dry-run               Print commands without running builds.
  -h, --help              Show this help.

Environment:
  BUILD_NAME              Same as --build-name.
  BUILD_NUMBER            Same as --build-number.
  EXPORT_METHOD           Same as --export-method.
  PUB_GET=0               Same as --no-pub-get.
  CLEAN=1                 Same as --clean.
  BUILD_ANDROID_LLAMA=1   Same as --android-llama.
  SPLIT_PER_ABI=1         Same as --split-per-abi.
  DRY_RUN=1               Same as --dry-run.

Examples:
  ./tool/package_release.sh
  ./tool/package_release.sh android --build-name 1.0.0 --build-number 2
  ./tool/package_release.sh ipa --export-method ad-hoc
  BUILD_ANDROID_LLAMA=1 ./tool/package_release.sh apk
USAGE
}

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not found"
}

add_target() {
  local target="$1"
  case "${target}" in
    all)
      TARGETS+=(apk aab ipa)
      ;;
    android)
      TARGETS+=(apk aab)
      ;;
    ios)
      TARGETS+=(ipa)
      ;;
    apk | aab | ipa)
      TARGETS+=("${target}")
      ;;
    *)
      fail "Unknown target: ${target}"
      ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      all | android | ios | apk | aab | ipa)
        add_target "$1"
        shift
        ;;
      --build-name)
        [[ $# -ge 2 ]] || fail "--build-name requires a value"
        BUILD_NAME="$2"
        shift 2
        ;;
      --build-number)
        [[ $# -ge 2 ]] || fail "--build-number requires a value"
        BUILD_NUMBER="$2"
        shift 2
        ;;
      --export-method)
        [[ $# -ge 2 ]] || fail "--export-method requires a value"
        EXPORT_METHOD="$2"
        shift 2
        ;;
      --split-per-abi)
        SPLIT_PER_ABI=1
        shift
        ;;
      --android-llama)
        BUILD_ANDROID_LLAMA=1
        shift
        ;;
      --clean)
        RUN_CLEAN=1
        shift
        ;;
      --no-pub-get)
        RUN_PUB_GET=0
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done

  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    add_target all
  fi
}

target_enabled() {
  local expected="$1"
  local target
  for target in "${TARGETS[@]}"; do
    [[ "${target}" == "${expected}" ]] && return 0
  done
  return 1
}

has_android_target() {
  target_enabled apk || target_enabled aab
}

validate_export_method() {
  case "${EXPORT_METHOD}" in
    app-store | ad-hoc | development | enterprise)
      ;;
    *)
      fail "Unsupported iOS export method: ${EXPORT_METHOD}"
      ;;
  esac
}

warn_android_release_signing() {
  local gradle_file="${FLUTTER_APP_DIR}/android/app/build.gradle.kts"
  if grep -q 'release[[:space:]]*{[^}]*signingConfig = signingConfigs.getByName("debug")' "${gradle_file}" 2>/dev/null; then
    warn "Android release is still configured with debug signing. Configure release keystore before store/channel distribution."
    return
  fi

  if grep -q 'signingConfig = signingConfigs.getByName("debug")' "${gradle_file}" 2>/dev/null; then
    warn "Android release may still use debug signing. Check android/app/build.gradle.kts before store/channel distribution."
  fi
}

run_flutter_pub_get() {
  if [[ "${RUN_PUB_GET}" == "1" ]]; then
    log "Running flutter pub get"
    run_cmd flutter pub get
  else
    log "Skipping flutter pub get"
  fi
}

run_flutter_clean() {
  if [[ "${RUN_CLEAN}" == "1" ]]; then
    log "Running flutter clean"
    run_cmd flutter clean
  fi
}

build_android_llama_runtime() {
  if [[ "${BUILD_ANDROID_LLAMA}" == "1" ]]; then
    log "Building Android llama native runtime"
    run_cmd "${SCRIPT_DIR}/build_android_llama.sh"
  fi
}

build_apk() {
  local args=(build apk --release --build-name "${BUILD_NAME}" --build-number "${BUILD_NUMBER}")
  if [[ "${SPLIT_PER_ABI}" == "1" ]]; then
    args+=(--split-per-abi)
  fi

  log "Building Android APK"
  run_cmd flutter "${args[@]}"
}

build_aab() {
  log "Building Android App Bundle"
  run_cmd flutter build appbundle --release --build-name "${BUILD_NAME}" --build-number "${BUILD_NUMBER}"
}

build_ipa() {
  log "Building iOS IPA (${EXPORT_METHOD})"
  run_cmd flutter build ipa --release --export-method "${EXPORT_METHOD}" --build-name "${BUILD_NAME}" --build-number "${BUILD_NUMBER}"
}

run_cmd() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'

  if [[ "${DRY_RUN}" == "1" ]]; then
    return
  fi

  "$@"
}

print_outputs() {
  cat <<EOF

Release artifacts:
  APK: build/app/outputs/flutter-apk/
  AAB: build/app/outputs/bundle/release/app-release.aab
  IPA: build/ios/ipa/

Build config:
  build-name: ${BUILD_NAME}
  build-number: ${BUILD_NUMBER}
  iOS export-method: ${EXPORT_METHOD}
EOF
}

main() {
  parse_args "$@"
  validate_export_method
  if [[ "${DRY_RUN}" != "1" ]]; then
    require_command flutter
  fi

  cd "${FLUTTER_APP_DIR}"
  log "Working directory: ${FLUTTER_APP_DIR}"
  log "Targets: ${TARGETS[*]}"
  [[ "${DRY_RUN}" == "1" ]] && log "Dry run enabled"

  run_flutter_clean
  run_flutter_pub_get

  if has_android_target; then
    warn_android_release_signing
    build_android_llama_runtime
  fi

  target_enabled apk && build_apk
  target_enabled aab && build_aab
  target_enabled ipa && build_ipa

  print_outputs
}

main "$@"
