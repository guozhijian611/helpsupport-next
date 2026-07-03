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

runtime_framework_name() {
  local library_name="$1"
  printf '%s\n' "${library_name%.dylib}"
}

runtime_framework_install_name() {
  local library_name framework_name
  library_name="$1"
  framework_name="$(runtime_framework_name "${library_name}")"
  printf '@rpath/%s.framework/%s\n' "${framework_name}" "${framework_name}"
}

write_framework_info_plist() {
  local plist_path="$1"
  local framework_name="$2"

  cat > "${plist_path}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${framework_name}</string>
  <key>CFBundleIdentifier</key>
  <string>com.openb8.helpsupport.runtime.${framework_name}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${framework_name}</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>MinimumOSVersion</key>
  <string>15.0</string>
</dict>
</plist>
PLIST
}

copy_runtime_framework() {
  local library="$1"
  local runtime_dir="$2"
  local target_dir="$3"
  local library_name framework_name framework_dir executable_path dependency dependency_name

  library_name="$(basename "${library}")"
  framework_name="$(runtime_framework_name "${library_name}")"
  framework_dir="${target_dir}/${framework_name}.framework"
  executable_path="${framework_dir}/${framework_name}"

  rm -rf "${framework_dir}"
  rm -f "${target_dir}/${library_name}"
  mkdir -p "${framework_dir}"
  cp "${library}" "${executable_path}"
  chmod 755 "${executable_path}"
  codesign --remove-signature "${executable_path}" >/dev/null 2>&1 || true

  install_name_tool -id "$(runtime_framework_install_name "${library_name}")" "${executable_path}"
  for dependency in "${runtime_dir}"/lib*.dylib; do
    [[ -f "${dependency}" ]] || continue
    dependency_name="$(basename "${dependency}")"
    if otool -L "${executable_path}" | grep -q "@rpath/${dependency_name}"; then
      install_name_tool \
        -change "@rpath/${dependency_name}" \
        "$(runtime_framework_install_name "${dependency_name}")" \
        "${executable_path}"
    fi
  done

  write_framework_info_plist "${framework_dir}/Info.plist" "${framework_name}"
  sign_runtime_library "${framework_dir}"
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
    copy_runtime_framework "${library}" "${runtime_dir}" "${target_dir}"
    copied=$((copied + 1))
  done

  [[ "${copied}" -gt 0 ]] ||
    fail "No llama runtime dylibs found in ${runtime_dir}"
  [[ -f "${target_dir}/libllama.framework/libllama" ]] ||
    fail "libllama framework was not copied to ${target_dir}"

  log "Copied ${copied} llama runtime frameworks to ${target_dir}"
}

main "$@"
