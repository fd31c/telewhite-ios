load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TelewhiteVoiceChanger",
    module_name = "TelewhiteVoiceChanger",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelewhiteVoiceChanger/ONNXBridge:ONNXBridge",
    ],
    visibility = [
        "//visibility:public",
    ],
)
