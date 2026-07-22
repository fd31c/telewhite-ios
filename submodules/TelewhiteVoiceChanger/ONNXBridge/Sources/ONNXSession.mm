#import <ONNXBridge/ONNXSession.h>
// Bazel's apple_static_xcframework_import adds the framework's Headers/ dir
// directly to the include search path (unlike a dynamic -F framework
// import), so the header is reachable by its bare name, not framework-
// prefixed as `<onnxruntime/onnxruntime_c_api.h>`.
#import <onnxruntime_c_api.h>

#import <vector>
#import <string>

static NSError *TelewhiteONNXError(NSString *domain, NSInteger code, NSString *message) {
    return [NSError errorWithDomain:domain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

static const OrtApi *TelewhiteOrtApi(void) {
    static const OrtApi *api = nullptr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const OrtApiBase *base = OrtGetApiBase();
        api = base->GetApi(ORT_API_VERSION);
    });
    return api;
}

// Converts an OrtStatus into an NSError and releases the status. Returns nil
// (no error) when status is null, matching the ONNX Runtime C API convention
// that a null OrtStatus* means success.
static NSError *_Nullable TelewhiteConsumeStatus(OrtStatus *status) {
    if (status == nullptr) {
        return nil;
    }
    const OrtApi *ort = TelewhiteOrtApi();
    NSString *message = [NSString stringWithUTF8String:ort->GetErrorMessage(status)];
    ort->ReleaseStatus(status);
    return TelewhiteONNXError(@"ONNXSession", -1, message);
}

@implementation ONNXTensorInput {
    @package
    NSString *_name;
    std::vector<int64_t> _shape;
    std::vector<float> _data;
}

- (instancetype)initWithName:(NSString *)name shape:(NSArray<NSNumber *> *)shape float:(const float *)data count:(NSUInteger)count {
    self = [super init];
    if (self) {
        _name = [name copy];
        _shape.reserve(shape.count);
        for (NSNumber *dim in shape) {
            _shape.push_back(dim.longLongValue);
        }
        _data.assign(data, data + count);
    }
    return self;
}

@end

@implementation ONNXTensorOutput {
    @package
    NSString *_name;
    NSArray<NSNumber *> *_shape;
    std::vector<float> _data;
}

- (NSString *)name { return _name; }
- (NSArray<NSNumber *> *)shape { return _shape; }
- (const float *)floatData { return _data.data(); }
- (NSUInteger)floatCount { return _data.size(); }

@end

@implementation ONNXSession {
    OrtEnv *_env;
    OrtSession *_session;
    OrtMemoryInfo *_memoryInfo;
}

- (nullable instancetype)initWithModelPath:(NSString *)path threadCount:(NSInteger)threadCount error:(NSError **)error {
    self = [super init];
    if (!self) {
        return nil;
    }

    const OrtApi *ort = TelewhiteOrtApi();
    if (ort == nullptr) {
        if (error) {
            *error = TelewhiteONNXError(@"ONNXSession", -2, @"ONNX Runtime API unavailable (version mismatch with the linked xcframework).");
        }
        return nil;
    }

    NSError *creationError = TelewhiteConsumeStatus(ort->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "TelewhiteVoiceChanger", &_env));
    if (creationError) {
        if (error) { *error = creationError; }
        return nil;
    }

    OrtSessionOptions *options = nullptr;
    creationError = TelewhiteConsumeStatus(ort->CreateSessionOptions(&options));
    if (creationError) {
        if (error) { *error = creationError; }
        ort->ReleaseEnv(_env);
        return nil;
    }
    // Telewhite: RVC/HuBERT graphs are small per-frame; a couple of threads is
    // enough to keep the call's audio thread from starving. Raising this
    // trades battery for latency headroom — tune only if real-device
    // profiling shows underruns.
    ort->SetIntraOpNumThreads(options, (int)MAX(1, threadCount));
    ort->SetSessionGraphOptimizationLevel(options, ORT_ENABLE_ALL);

    creationError = TelewhiteConsumeStatus(ort->CreateSession(_env, path.fileSystemRepresentation, options, &_session));
    ort->ReleaseSessionOptions(options);
    if (creationError) {
        if (error) { *error = creationError; }
        ort->ReleaseEnv(_env);
        return nil;
    }

    creationError = TelewhiteConsumeStatus(ort->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &_memoryInfo));
    if (creationError) {
        if (error) { *error = creationError; }
        ort->ReleaseSession(_session);
        ort->ReleaseEnv(_env);
        return nil;
    }

    return self;
}

- (void)dealloc {
    const OrtApi *ort = TelewhiteOrtApi();
    if (_memoryInfo) { ort->ReleaseMemoryInfo(_memoryInfo); }
    if (_session) { ort->ReleaseSession(_session); }
    if (_env) { ort->ReleaseEnv(_env); }
}

- (nullable NSArray<ONNXTensorOutput *> *)runWithInputs:(NSArray<ONNXTensorInput *> *)inputs outputNames:(NSArray<NSString *> *)outputNames error:(NSError **)error {
    const OrtApi *ort = TelewhiteOrtApi();

    std::vector<std::string> inputNameStorage;
    std::vector<const char *> inputNames;
    std::vector<OrtValue *> inputValues;
    inputNameStorage.reserve(inputs.count);
    inputNames.reserve(inputs.count);
    inputValues.reserve(inputs.count);

    for (ONNXTensorInput *input in inputs) {
        inputNameStorage.push_back(std::string(input->_name.UTF8String));
        OrtValue *value = nullptr;
        NSError *tensorError = TelewhiteConsumeStatus(ort->CreateTensorWithDataAsOrtValue(
            _memoryInfo,
            input->_data.data(),
            input->_data.size() * sizeof(float),
            input->_shape.data(),
            input->_shape.size(),
            ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
            &value));
        if (tensorError) {
            for (OrtValue *created : inputValues) { ort->ReleaseValue(created); }
            if (error) { *error = tensorError; }
            return nil;
        }
        inputValues.push_back(value);
    }
    for (const std::string &name : inputNameStorage) {
        inputNames.push_back(name.c_str());
    }

    std::vector<std::string> outputNameStorage;
    std::vector<const char *> outputNamesRaw;
    outputNameStorage.reserve(outputNames.count);
    outputNamesRaw.reserve(outputNames.count);
    for (NSString *name in outputNames) {
        outputNameStorage.push_back(std::string(name.UTF8String));
    }
    for (const std::string &name : outputNameStorage) {
        outputNamesRaw.push_back(name.c_str());
    }

    std::vector<OrtValue *> outputValues(outputNames.count, nullptr);
    NSError *runError = TelewhiteConsumeStatus(ort->Run(
        _session,
        nullptr,
        inputNames.data(),
        (const OrtValue *const *)inputValues.data(),
        inputValues.size(),
        outputNamesRaw.data(),
        outputNamesRaw.size(),
        outputValues.data()));

    for (OrtValue *value : inputValues) { ort->ReleaseValue(value); }

    if (runError) {
        for (OrtValue *value : outputValues) { if (value) { ort->ReleaseValue(value); } }
        if (error) { *error = runError; }
        return nil;
    }

    NSMutableArray<ONNXTensorOutput *> *results = [NSMutableArray arrayWithCapacity:outputValues.size()];
    BOOL failed = NO;
    NSError *extractionError = nil;
    for (NSUInteger i = 0; i < outputValues.size(); i++) {
        OrtValue *value = outputValues[i];

        OrtTensorTypeAndShapeInfo *shapeInfo = nullptr;
        extractionError = TelewhiteConsumeStatus(ort->GetTensorTypeAndShape(value, &shapeInfo));
        if (extractionError) { failed = YES; ort->ReleaseValue(value); continue; }

        size_t dimCount = 0;
        ort->GetDimensionsCount(shapeInfo, &dimCount);
        std::vector<int64_t> dims(dimCount);
        ort->GetDimensions(shapeInfo, dims.data(), dimCount);

        size_t elementCount = 0;
        ort->GetTensorShapeElementCount(shapeInfo, &elementCount);
        ort->ReleaseTensorTypeAndShapeInfo(shapeInfo);

        float *data = nullptr;
        extractionError = TelewhiteConsumeStatus(ort->GetTensorMutableData(value, (void **)&data));
        if (extractionError) { failed = YES; ort->ReleaseValue(value); continue; }

        ONNXTensorOutput *output = [ONNXTensorOutput new];
        output->_name = outputNames[i];
        NSMutableArray<NSNumber *> *shapeArray = [NSMutableArray arrayWithCapacity:dims.size()];
        for (int64_t dim : dims) { [shapeArray addObject:@(dim)]; }
        output->_shape = shapeArray;
        output->_data.assign(data, data + elementCount);

        [results addObject:output];
        ort->ReleaseValue(value);
    }

    if (failed) {
        if (error) { *error = extractionError; }
        return nil;
    }
    return results;
}

@end
