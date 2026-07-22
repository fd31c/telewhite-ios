#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Telewhite: thin Objective-C wrapper around the ONNX Runtime C API
// (OrtApi). Exposes just enough to run a single named-input/named-output
// model with float32 tensors — sufficient for both the HuBERT feature
// extractor and the RVC decoder, which are the only two model shapes this
// pipeline calls. Batching, quantized dtypes and execution-provider
// selection beyond CPU are out of scope: ponytail, add when a real profiling
// need shows up, not speculatively.

@interface ONNXTensorInput : NSObject

- (instancetype)initWithName:(NSString *)name
                       shape:(NSArray<NSNumber *> *)shape
                       float:(const float *)data
                       count:(NSUInteger)count NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(name:shape:float:count:));
- (instancetype)init NS_UNAVAILABLE;

@end

@interface ONNXTensorOutput : NSObject

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSArray<NSNumber *> *shape;
// Owned by this object; valid for its lifetime.
@property (nonatomic, readonly) const float *floatData;
@property (nonatomic, readonly) NSUInteger floatCount;

@end

@interface ONNXSession : NSObject

// Loads a model from an on-disk .onnx path. Returns nil and populates `error`
// on failure (malformed file, unsupported ops, out of memory).
- (nullable instancetype)initWithModelPath:(NSString *)path
                                threadCount:(NSInteger)threadCount
                                      error:(NSError **)error NS_SWIFT_NAME(init(modelPath:threadCount:));
- (instancetype)init NS_UNAVAILABLE;

// Runs the loaded graph. `inputs` must name every required graph input.
// Returns nil and populates `error` on shape mismatch or a runtime failure
// inside the ONNX graph (e.g. an unsupported dynamic shape).
- (nullable NSArray<ONNXTensorOutput *> *)runWithInputs:(NSArray<ONNXTensorInput *> *)inputs
                                             outputNames:(NSArray<NSString *> *)outputNames
                                                   error:(NSError **)error NS_SWIFT_NAME(run(inputs:outputNames:));

@end

NS_ASSUME_NONNULL_END
