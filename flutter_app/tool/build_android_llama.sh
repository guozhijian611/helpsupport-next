#!/usr/bin/env bash
set -euo pipefail

LLAMA_CPP_COMMIT="${LLAMA_CPP_COMMIT:-4ffc47cb2001e7d523f9ff525335bbe34b1a2858}"
LLAMA_CPP_REPO="${LLAMA_CPP_REPO:-https://github.com/ggml-org/llama.cpp}"
LLAMA_ANDROID_ABIS="${LLAMA_ANDROID_ABIS:-arm64-v8a}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ANDROID_DIR="${FLUTTER_APP_DIR}/android"
LOCAL_PROPERTIES="${ANDROID_DIR}/local.properties"
BUILD_ROOT="${FLUTTER_APP_DIR}/.dart_tool/native/llama_cpp_dart_android"
SRC_ROOT="${BUILD_ROOT}/src"
LLAMA_DIR="${SRC_ROOT}/llama.cpp"
JNI_ROOT="${ANDROID_DIR}/app/src/main/jniLibs"

android_sdk_dir() {
  if [[ -n "${ANDROID_HOME:-}" ]]; then
    printf '%s\n' "${ANDROID_HOME}"
    return
  fi
  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    printf '%s\n' "${ANDROID_SDK_ROOT}"
    return
  fi
  if [[ -f "${LOCAL_PROPERTIES}" ]]; then
    awk -F= '$1 == "sdk.dir" { print $2 }' "${LOCAL_PROPERTIES}"
    return
  fi
}

latest_child_dir() {
  local root="$1"
  find "${root}" -maxdepth 1 -mindepth 1 -type d -print | sort | tail -1
}

toolchain_triple() {
  case "$1" in
    arm64-v8a) printf '%s\n' 'aarch64-linux-android' ;;
    armeabi-v7a) printf '%s\n' 'arm-linux-androideabi' ;;
    x86_64) printf '%s\n' 'x86_64-linux-android' ;;
    x86) printf '%s\n' 'i686-linux-android' ;;
    *) printf 'Unsupported ABI: %s\n' "$1" >&2; return 1 ;;
  esac
}

openmp_arch() {
  case "$1" in
    arm64-v8a) printf '%s\n' 'aarch64' ;;
    armeabi-v7a) printf '%s\n' 'arm' ;;
    x86_64) printf '%s\n' 'x86_64' ;;
    x86) printf '%s\n' 'i386' ;;
    *) printf 'Unsupported ABI: %s\n' "$1" >&2; return 1 ;;
  esac
}

find_openmp_runtime() {
  local ndk_dir="$1"
  local abi="$2"
  local arch runtime
  arch="$(openmp_arch "${abi}")"
  runtime="$(find "${ndk_dir}/toolchains/llvm/prebuilt" \
    -path "*/lib/clang/*/lib/linux/${arch}/libomp.so" \
    -type f -print | sort | tail -1)"
  if [[ -z "${runtime}" ]]; then
    printf 'OpenMP runtime libomp.so not found for ABI %s under %s\n' \
      "${abi}" "${ndk_dir}" >&2
    return 1
  fi
  printf '%s\n' "${runtime}"
}

ensure_llama_source() {
  mkdir -p "${SRC_ROOT}"
  if [[ ! -d "${LLAMA_DIR}/.git" ]]; then
    rm -rf "${LLAMA_DIR}"
    git clone --filter=blob:none "${LLAMA_CPP_REPO}" "${LLAMA_DIR}"
  fi
  git -C "${LLAMA_DIR}" fetch --depth 1 origin "${LLAMA_CPP_COMMIT}"
  git -C "${LLAMA_DIR}" checkout --detach "${LLAMA_CPP_COMMIT}"
}

write_wrapper_cmake() {
  cat > "${SRC_ROOT}/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.22.1)
project(helpsupport_llama_android)

add_subdirectory(llama.cpp)

if (ANDROID)
    find_library(log-lib log)
    file(GLOB MTMD_MODEL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/tools/mtmd/models/*.cpp")
    add_library(mtmd SHARED
        llama.cpp/tools/mtmd/mtmd.cpp
        llama.cpp/tools/mtmd/mtmd-audio.cpp
        llama.cpp/tools/mtmd/clip.cpp
        llama.cpp/tools/mtmd/mtmd-helper.cpp
        ${MTMD_MODEL_SOURCES}
    )
    target_include_directories(mtmd PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/ggml/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/common"
        "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/tools/mtmd"
        "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/tools/mtmd/clip"
        "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/vendor"
    )
    target_link_libraries(mtmd PUBLIC llama ggml ${log-lib})
endif()
CMAKE
}

copy_runtime_libs() {
  local abi="$1"
  local out_dir="$2"
  local ndk_dir="$3"
  local target_dir="${JNI_ROOT}/${abi}"
  local triple
  triple="$(toolchain_triple "${abi}")"

  mkdir -p "${target_dir}"
  cp "${out_dir}/libmtmd.so" "${target_dir}/"
  cp "${out_dir}/bin/libllama.so" "${target_dir}/"
  cp "${out_dir}/bin/libggml.so" "${target_dir}/"
  cp "${out_dir}/bin/libggml-base.so" "${target_dir}/"
  cp "${out_dir}/bin/libggml-cpu.so" "${target_dir}/"
  cp "${ndk_dir}/toolchains/llvm/prebuilt/"*/"sysroot/usr/lib/${triple}/libc++_shared.so" "${target_dir}/"
  cp "$(find_openmp_runtime "${ndk_dir}" "${abi}")" "${target_dir}/"
}

main() {
  local sdk_dir ndk_dir cmake_dir cmake_bin
  sdk_dir="$(android_sdk_dir)"
  if [[ -z "${sdk_dir}" || ! -d "${sdk_dir}" ]]; then
    echo "Android SDK not found. Set ANDROID_HOME or android/local.properties sdk.dir." >&2
    exit 1
  fi

  ndk_dir="$(latest_child_dir "${sdk_dir}/ndk")"
  cmake_dir="$(latest_child_dir "${sdk_dir}/cmake")"
  cmake_bin="${cmake_dir}/bin/cmake"

  if [[ ! -x "${cmake_bin}" ]]; then
    echo "CMake not found under ${sdk_dir}/cmake." >&2
    exit 1
  fi
  if [[ ! -d "${ndk_dir}" ]]; then
    echo "Android NDK not found under ${sdk_dir}/ndk." >&2
    exit 1
  fi

  ensure_llama_source
  write_wrapper_cmake

  for abi in ${LLAMA_ANDROID_ABIS}; do
    local out_dir="${BUILD_ROOT}/build/${abi}"
    rm -rf "${out_dir}"
    "${cmake_bin}" -S "${SRC_ROOT}" -B "${out_dir}" \
      -G "Unix Makefiles" \
      -DCMAKE_TOOLCHAIN_FILE="${ndk_dir}/build/cmake/android.toolchain.cmake" \
      -DANDROID_ABI="${abi}" \
      -DANDROID_PLATFORM=android-24 \
      -DANDROID_STL=c++_shared \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DLLAMA_CURL=OFF \
      -DLLAMA_NATIVE=OFF \
      -DLLAMA_BUILD_TESTS=OFF \
      -DLLAMA_BUILD_EXAMPLES=OFF \
      -DLLAMA_BUILD_SERVER=OFF \
      -DLLAMA_BUILD_TOOLS=OFF \
      -DGGML_CCACHE=OFF \
      -DGGML_OPENCL=OFF
    "${cmake_bin}" --build "${out_dir}" --target mtmd -j "${LLAMA_ANDROID_JOBS:-4}"
    copy_runtime_libs "${abi}" "${out_dir}" "${ndk_dir}"
    echo "Wrote ${JNI_ROOT}/${abi}"
  done
}

main "$@"
