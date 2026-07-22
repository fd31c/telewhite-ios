load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import",
)

# Telewhite: ONNX Runtime C API, vendored from the official iOS distribution
# (https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.24.2.zip, the
# same binary the onnxruntime-swift-package-manager SPM package points at).
# Used by the voice-changer inference pipeline (HuBERT + RVC .onnx models the
# user imports themselves); no bundled model weights ship with this archive.
apple_static_xcframework_import(
    name = "onnxruntime",
    xcframework_imports = glob(["onnxruntime.xcframework/**"]),
    visibility = [
        "//visibility:public",
    ],
)
