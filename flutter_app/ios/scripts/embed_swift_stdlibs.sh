#!/bin/sh
set -eu

case "${SDK_NAME:-}" in
  iphoneos*) ;;
  *) exit 0 ;;
esac

frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
executable_path="${TARGET_BUILD_DIR}/${EXECUTABLE_PATH}"
swift_lib_root="${TOOLCHAIN_DIR}/usr/lib"
needed_file="${DERIVED_FILE_DIR}/helpsupport-swift-stdlibs.txt"

if [ ! -d "${frameworks_dir}" ]; then
  exit 0
fi

: > "${needed_file}"

scan_binary() {
  binary="$1"
  if [ -f "${binary}" ]; then
    otool -L "${binary}" 2>/dev/null | awk '/\/usr\/lib\/swift\/libswift.*\.dylib/ {
      sub(/^.*\/usr\/lib\/swift\//, "");
      sub(/ .*/, "");
      print
    }' >> "${needed_file}" || true
  fi
}

scan_binary "${executable_path}"

find "${frameworks_dir}" -type f -perm -111 -print | while IFS= read -r binary; do
  scan_binary "${binary}"
done

sort -u "${needed_file}" -o "${needed_file}"

copied_count=0
while IFS= read -r lib_name; do
  [ -n "${lib_name}" ] || continue
  lib_path="$(find "${swift_lib_root}" -path "*/swift-*/iphoneos/${lib_name}" -type f | sort | head -n 1)"
  if [ -z "${lib_path}" ]; then
    continue
  fi

  destination="${frameworks_dir}/${lib_name}"
  cp -f "${lib_path}" "${destination}"
  copied_count=$((copied_count + 1))
done < "${needed_file}"

if [ "${copied_count}" -gt 0 ]; then
  echo "Embedded ${copied_count} Swift standard libraries into ${FRAMEWORKS_FOLDER_PATH}"
fi
