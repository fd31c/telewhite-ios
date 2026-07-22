objc_library(
    name = "ONNXBridge",
    enable_modules = True,
    module_name = "ONNXBridge",
    srcs = glob([
        "Sources/**/*.mm",
        "Sources/**/*.h",
    ], allow_empty = True),
    hdrs = glob([
        "PublicHeaders/**/*.h",
    ]),
    includes = [
        "PublicHeaders",
    ],
    copts = [
        "-std=c++17",
    ],
    deps = [
        "//third-party/onnxruntime:onnxruntime",
    ],
    sdk_frameworks = [
        "Foundation",
    ],
    visibility = [
        "//visibility:public",
    ],
)
