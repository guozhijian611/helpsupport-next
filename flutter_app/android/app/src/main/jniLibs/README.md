# Native llama runtime

Run the project script to build CPU-only llama.cpp Android libraries:

```bash
./tool/build_android_llama.sh
```

The script writes generated binaries here by Android ABI:

```text
arm64-v8a/libmtmd.so
arm64-v8a/libllama.so
arm64-v8a/libggml*.so
arm64-v8a/libggml-vulkan.so
arm64-v8a/libc++_shared.so
arm64-v8a/libomp.so
```

Generated `.so` files are ignored by Git. Only commit binaries after confirming
their source, license, ABI, and build flags.
