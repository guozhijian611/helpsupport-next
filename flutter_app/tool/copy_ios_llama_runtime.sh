#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGE_CONFIG="${FLUTTER_APP_DIR}/.dart_tool/package_config.json"

log() {
  printf '==> %s\n' "$*"
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

resolve_llama_package_dir() {
  [[ -f "${PACKAGE_CONFIG}" ]] ||
    fail "Missing ${PACKAGE_CONFIG}. Run flutter pub get first."

  local root_uri
  root_uri="$(
    awk '
      /"name"[[:space:]]*:[[:space:]]*"llama_cpp_dart"/ { found = 1; next }
      found && /"rootUri"/ {
        line = $0
        sub(/^.*"rootUri"[[:space:]]*:[[:space:]]*"/, "", line)
        sub(/".*$/, "", line)
        print line
        exit
      }
    ' "${PACKAGE_CONFIG}"
  )"
  [[ -n "${root_uri}" ]] || fail "llama_cpp_dart not found in package_config.json"
  [[ "${root_uri}" == file://* ]] ||
    fail "Unsupported llama_cpp_dart rootUri: ${root_uri}"

  local package_dir="${root_uri#file://}"
  package_dir="${package_dir//%20/ }"
  [[ -d "${package_dir}" ]] || fail "llama_cpp_dart directory not found: ${package_dir}"
  printf '%s\n' "${package_dir}"
}

select_runtime_dir() {
  if [[ -n "${HELP_SUPPORT_LLAMA_IOS_RUNTIME_DIR:-}" ]]; then
    [[ -d "${HELP_SUPPORT_LLAMA_IOS_RUNTIME_DIR}" ]] ||
      fail "HELP_SUPPORT_LLAMA_IOS_RUNTIME_DIR not found: ${HELP_SUPPORT_LLAMA_IOS_RUNTIME_DIR}"
    printf '%s\n' "${HELP_SUPPORT_LLAMA_IOS_RUNTIME_DIR}"
    return
  fi

  local package_dir platform arch runtime_subdir
  package_dir="$(resolve_llama_package_dir)"
  platform="${PLATFORM_NAME:-iphonesimulator}"
  arch="${CURRENT_ARCH:-${NATIVE_ARCH_ACTUAL:-${ARCHS:-$(uname -m)}}}"

  case "${platform}" in
    iphonesimulator)
      if [[ "${arch}" == *x86_64* && "${arch}" != *arm64* ]]; then
        runtime_subdir="SIMULATOR64"
      else
        runtime_subdir="SIMULATORARM64"
      fi
      ;;
    iphoneos)
      runtime_subdir="OS64"
      ;;
    *)
      log "Skipping llama runtime copy for platform: ${platform}"
      return
      ;;
  esac

  local runtime_dir="${package_dir}/bin/${runtime_subdir}"
  [[ -d "${runtime_dir}" ]] ||
    fail "llama_cpp_dart runtime directory not found: ${runtime_dir}"
  printf '%s\n' "${runtime_dir}"
}

sign_runtime_library() {
  local library_path="$1"
  command -v codesign >/dev/null 2>&1 || return

  local identity="${EXPANDED_CODE_SIGN_IDENTITY:-}"
  if [[ -n "${identity}" && "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]]; then
    codesign --force --sign "${identity}" --timestamp=none "${library_path}" >/dev/null 2>&1
    return
  fi

  codesign --force --sign - --timestamp=none "${library_path}" >/dev/null 2>&1
}

main() {
  local runtime_dir target_dir
  runtime_dir="$(select_runtime_dir)"
  [[ -n "${runtime_dir}" ]] || exit 0

  target_dir="${TARGET_BUILD_DIR:-${FLUTTER_APP_DIR}/build/ios/Debug-iphonesimulator}/${FRAMEWORKS_FOLDER_PATH:-Runner.app/Frameworks}"
  mkdir -p "${target_dir}"

  local copied=0
  for library in "${runtime_dir}"/lib*.dylib; do
    [[ -f "${library}" ]] || continue
    cp "${library}" "${target_dir}/"
    chmod 755 "${target_dir}/$(basename "${library}")"
    sign_runtime_library "${target_dir}/$(basename "${library}")"
    copied=$((copied + 1))
  done

  [[ "${copied}" -gt 0 ]] ||
    fail "No llama runtime dylibs found in ${runtime_dir}"
  [[ -f "${target_dir}/libllama.dylib" ]] ||
    fail "libllama.dylib was not copied to ${target_dir}"

  log "Copied ${copied} llama runtime dylibs to ${target_dir}"
}

main "$@"
