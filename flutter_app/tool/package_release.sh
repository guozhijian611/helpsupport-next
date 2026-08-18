#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

# 未显式覆盖时使用 Flutter 中国社区镜像，加速 pub get 与引擎下载。
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"

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

Run without arguments to select release artifacts interactively.

Targets:
  all                 Build apk, aab, and ipa.
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
                          TestFlight uses app-store and requires a local Apple Distribution certificate.
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
  ./tool/package_release.sh       # Interactive selection.
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

install_aliyun_gradle_init() {
  local source="${FLUTTER_APP_DIR}/android/gradle/init.aliyun.gradle"
  local dest="${HOME}/.gradle/init.d/helpsupport-aliyun.gradle"
  [[ -f "${source}" ]] || fail "Gradle Aliyun init script not found: ${source}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "Would install Gradle Aliyun init script to ${dest}"
    return
  fi
  mkdir -p "$(dirname "${dest}")"
  cp "${source}" "${dest}"
  log "Installed Gradle Aliyun init script: ${dest}"
}

prompt_value() {
  local label="$1"
  local current="$2"
  local input
  printf '%s [%s]: ' "${label}" "${current}" >&2
  IFS= read -r input || fail "Input cancelled"
  if [[ -n "${input}" ]]; then
    printf '%s\n' "${input}"
  else
    printf '%s\n' "${current}"
  fi
}

prompt_yes_no() {
  local label="$1"
  local default_value="$2"
  local hint input

  if [[ "${default_value}" == "1" ]]; then
    hint="Y/n"
  else
    hint="y/N"
  fi

  while true; do
    printf '%s [%s]: ' "${label}" "${hint}" >&2
    IFS= read -r input || fail "Input cancelled"
    case "${input}" in
      y | Y | yes | YES)
        printf '1\n'
        return
        ;;
      n | N | no | NO)
        printf '0\n'
        return
        ;;
      '')
        printf '%s\n' "${default_value}"
        return
        ;;
      *)
        printf 'Please enter y or n.\n' >&2
        ;;
    esac
  done
}

interactive_select() {
  local choice

  cat <<'MENU'

HelpSupport 正式包打包

请选择要输出的产物：
  1) 全部：APK + AAB + IPA(App Store/TestFlight)
  2) Android：APK + AAB
  3) Android APK
  4) Android AAB
  5) iOS IPA：App Store / TestFlight
  6) iOS IPA：Ad Hoc 内部分发
  7) iOS IPA：Development 开发签名
  8) iOS IPA：Enterprise 企业分发
MENU

  while true; do
    printf '请输入序号 [1]: '
    IFS= read -r choice || fail "Input cancelled"
    choice="${choice:-1}"
    case "${choice}" in
      1)
        add_target all
        EXPORT_METHOD="app-store"
        break
        ;;
      2)
        add_target android
        break
        ;;
      3)
        add_target apk
        break
        ;;
      4)
        add_target aab
        break
        ;;
      5)
        add_target ipa
        EXPORT_METHOD="app-store"
        break
        ;;
      6)
        add_target ipa
        EXPORT_METHOD="ad-hoc"
        break
        ;;
      7)
        add_target ipa
        EXPORT_METHOD="development"
        break
        ;;
      8)
        add_target ipa
        EXPORT_METHOD="enterprise"
        break
        ;;
      *)
        printf '请输入 1-8 的序号。\n' >&2
        ;;
    esac
  done

  BUILD_NAME="$(prompt_value '版本号 build-name' "${BUILD_NAME}")"
  BUILD_NUMBER="$(prompt_value '构建号 build-number' "${BUILD_NUMBER}")"

  if has_android_target && target_enabled apk; then
    SPLIT_PER_ABI="$(prompt_yes_no 'Android APK 是否按 ABI 拆分' "${SPLIT_PER_ABI}")"
  fi

  if has_android_target; then
    BUILD_ANDROID_LLAMA="$(prompt_yes_no '是否重新编译 Android 本地模型动态库' "${BUILD_ANDROID_LLAMA}")"
  fi

  RUN_CLEAN="$(prompt_yes_no '是否先执行 flutter clean' "${RUN_CLEAN}")"
  RUN_PUB_GET="$(prompt_yes_no '是否执行 flutter pub get' "${RUN_PUB_GET}")"
  DRY_RUN="$(prompt_yes_no '是否只打印命令不实际打包' "${DRY_RUN}")"
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
  if [[ "${EXPORT_METHOD}" == "app-store" ]]; then
    require_ios_distribution_signing
  fi
  run_cmd flutter build ipa --release --export-method "${EXPORT_METHOD}" --build-name "${BUILD_NAME}" --build-number "${BUILD_NUMBER}"
  validate_ios_app_store_ipa
}

require_ios_distribution_signing() {
  [[ "${DRY_RUN}" == "1" ]] && return
  require_command security

  if ! security find-identity -v -p codesigning | grep -Eq '"(Apple Distribution|iOS Distribution):'; then
    fail "Apple Distribution signing identity not found. TestFlight/App Store builds must be exported with a distribution certificate. Open Xcode > Settings > Accounts > Manage Certificates and create/download Apple Distribution first."
  fi
}

validate_ios_app_store_ipa() {
  [[ "${DRY_RUN}" != "1" ]] || return 0
  [[ "${EXPORT_METHOD}" == "app-store" ]] || return 0
  require_command unzip
  require_command mktemp

  local ipa_dir="${FLUTTER_APP_DIR}/build/ios/ipa"
  local ipa ipa_count=0 tmpdir dylib dylib_name
  local -a unsupported_dylibs=()

  [[ -d "${ipa_dir}" ]] || fail "iOS IPA output directory not found: ${ipa_dir}"

  while IFS= read -r -d '' ipa; do
    ipa_count=$((ipa_count + 1))
    tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/helpsupport-ipa-check.XXXXXX")"
    unzip -q "${ipa}" -d "${tmpdir}"
    while IFS= read -r dylib; do
      dylib_name="$(basename "${dylib}")"
      [[ "${dylib_name}" == libswift* ]] && continue
      unsupported_dylibs+=("$(basename "${ipa}"): ${dylib#${tmpdir}/}")
    done < <(find "${tmpdir}/Payload" -name '*.dylib' -print 2>/dev/null)
    rm -rf "${tmpdir}"
  done < <(find "${ipa_dir}" -maxdepth 1 -type f -name '*.ipa' -print0)

  [[ "${ipa_count}" -gt 0 ]] || fail "No IPA found in ${ipa_dir}"
  if [[ "${#unsupported_dylibs[@]}" -gt 0 ]]; then
    printf 'Error: App Store IPA contains unsupported embedded dylibs. Package native libraries as .framework bundles before upload:\n' >&2
    printf '  %s\n' "${unsupported_dylibs[@]}" >&2
    exit 1
  fi
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
  local arg_count="$#"

  parse_args "$@"
  if [[ "${arg_count}" -eq 0 ]]; then
    interactive_select
  elif [[ ${#TARGETS[@]} -eq 0 ]]; then
    add_target all
  fi

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
    install_aliyun_gradle_init
    warn_android_release_signing
    build_android_llama_runtime
  fi

  target_enabled apk && build_apk
  target_enabled aab && build_aab
  target_enabled ipa && build_ipa

  print_outputs
}

main "$@"
