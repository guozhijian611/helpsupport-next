#!/bin/sh
set -eu

if [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  echo "Skipping Swift stdlib embedding for platform ${PLATFORM_NAME:-unknown}"
  exit 0
fi

if [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ]; then
  echo "Skipping Swift stdlib embedding because code signing is disabled"
  exit 0
fi

app_dir="${CODESIGNING_FOLDER_PATH:-${TARGET_BUILD_DIR}/${WRAPPER_NAME}}"
frameworks_dir="${app_dir}/Frameworks"
executable_path="${app_dir}/${EXECUTABLE_NAME}"

if [ ! -d "${app_dir}" ]; then
  echo "warning: app bundle not found for Swift stdlib embedding: ${app_dir}"
  exit 0
fi

mkdir -p "${frameworks_dir}"

swift_stdlib_tool="$(xcrun --find swift-stdlib-tool)"
swift_source_dir="$(cd "$(dirname "${swift_stdlib_tool}")/../lib/swift-5.0/iphoneos" && pwd)"
sign_identity="${EXPANDED_CODE_SIGN_IDENTITY:-}"

if [ -z "${sign_identity}" ]; then
  echo "warning: EXPANDED_CODE_SIGN_IDENTITY is empty; Swift stdlibs will not be embedded"
  exit 0
fi

unsigned_destination=""
case "${TARGET_BUILD_DIR:-}" in
  */InstallationBuildProductsLocation/Applications)
    archive_intermediates="${TARGET_BUILD_DIR%/InstallationBuildProductsLocation/Applications}"
    unsigned_destination="${archive_intermediates}/BuildProductsPath/SwiftSupport/iphoneos"
    mkdir -p "${unsigned_destination}"
    ;;
esac

archive_swift_support=""
archive_root="${TARGET_BUILD_DIR%%/IntermediateBuildFilesPath/ArchiveIntermediates/*}"
if [ -d "${archive_root}" ] && [ "${archive_root}" != "${TARGET_BUILD_DIR}" ]; then
  archive_swift_support="${archive_root}/SwiftSupport/iphoneos"
  mkdir -p "${archive_swift_support}"
fi

echo "Embedding Swift stdlibs into ${frameworks_dir}"
if [ -n "${unsigned_destination}" ]; then
  echo "Writing unsigned SwiftSupport copies into ${unsigned_destination}"
fi
if [ -n "${archive_swift_support}" ]; then
  echo "Writing archive SwiftSupport copies into ${archive_swift_support}"
fi
echo "Using Swift stdlib source ${swift_source_dir}"

required_libs_file="${DERIVED_FILE_DIR:-${TMPDIR:-/tmp}}/b8_required_swift_stdlibs.txt"
: > "${required_libs_file}"

collect_required_libs() {
  binary_path="$1"
  if [ -f "${binary_path}" ]; then
    otool -L "${binary_path}" 2>/dev/null \
      | awk '/\/usr\/lib\/swift\/libswift.*\.dylib/ { name = $1; sub(".*/", "", name); print name }' \
      >> "${required_libs_file}"
  fi
}

collect_required_libs "${executable_path}"
for candidate in "${frameworks_dir}"/*.framework/* "${frameworks_dir}"/*.dylib; do
  collect_required_libs "${candidate}"
done

sort -u "${required_libs_file}" -o "${required_libs_file}"

if [ ! -s "${required_libs_file}" ]; then
  echo "No Swift stdlib dependencies found"
  exit 0
fi

while IFS= read -r library_name; do
  source_library="${swift_source_dir}/${library_name}"
  if [ ! -f "${source_library}" ]; then
    echo "Skipping ${library_name}; not present in ${swift_source_dir}"
    continue
  fi

  app_library="${frameworks_dir}/${library_name}"
  cp -f "${source_library}" "${app_library}"
  codesign --force --sign "${sign_identity}" --timestamp=none "${app_library}"

  if [ -n "${unsigned_destination}" ]; then
    cp -f "${source_library}" "${unsigned_destination}/${library_name}"
  fi
  if [ -n "${archive_swift_support}" ]; then
    cp -f "${source_library}" "${archive_swift_support}/${library_name}"
  fi
done < "${required_libs_file}"

find "${frameworks_dir}" -maxdepth 1 -name 'libswift*.dylib' -print
