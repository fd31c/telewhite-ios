import Foundation
import ONNXBridge

// Telewhite: on-device voice changer built on ONNX Runtime, mirroring the
// Teledark HuBERT + RVC recipe. The user imports two model files themselves —
// the shared `hubert_base.onnx` content encoder and an RVC decoder `.onnx`
// carrying a specific target voice — and this manager owns their storage,
// loading and per-frame inference. No model weights ship with the app.
//
// ponytail: pitch (F0) extraction here is a plain autocorrelation estimator,
// not RMVPE/CREPE. It is the known-lower-fidelity corner of the pipeline —
// good enough to drive the RVC decoder's f0 input, upgrade to a learned pitch
// model if the converted voice sounds off. Everything else (feature encode,
// decode, resample) is the real algorithm.

public final class TelewhiteVoiceModelStore {
    public static let shared = TelewhiteVoiceModelStore()

    private let fileManager = FileManager.default

    public var modelsDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("TelewhiteVoiceModels", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public var hubertURL: URL {
        return modelsDirectory.appendingPathComponent("hubert_base.onnx")
    }

    public var hubertInstalled: Bool {
        return fileManager.fileExists(atPath: hubertURL.path)
    }

    // Imported RVC voices, newest first.
    public func voiceModels() -> [URL] {
        let contents = (try? fileManager.contentsOfDirectory(at: modelsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return contents
            .filter { $0.pathExtension.lowercased() == "onnx" && $0.lastPathComponent != "hubert_base.onnx" }
            .sorted { lhs, rhs in
                let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return l > r
            }
    }

    // Copies an imported .onnx into the store. Pass `asHubert: true` for the
    // shared content encoder, false for a target-voice RVC model.
    @discardableResult
    public func importModel(from sourceURL: URL, asHubert: Bool) throws -> URL {
        let destination = asHubert ? hubertURL : modelsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)
        return destination
    }

    public func removeVoiceModel(_ url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}

public enum TelewhiteVoiceChangerError: Error {
    case hubertMissing
    case modelLoadFailed(String)
    case inferenceFailed(String)
}

public final class TelewhiteVoiceChanger {
    private let hubert: ONNXSession
    private let rvc: ONNXSession

    // 16 kHz is the fixed sample rate HuBERT expects; the RVC decoder outputs
    // at its own synthesis rate (typically 40000), which the caller resamples
    // back to the call's rate.
    public static let hubertSampleRate: Int = 16000

    public init(hubertURL: URL, rvcURL: URL, threadCount: Int = 2) throws {
        do {
            self.hubert = try ONNXSession(modelPath: hubertURL.path, threadCount: threadCount)
        } catch {
            throw TelewhiteVoiceChangerError.modelLoadFailed("hubert: \(error.localizedDescription)")
        }
        do {
            self.rvc = try ONNXSession(modelPath: rvcURL.path, threadCount: threadCount)
        } catch {
            throw TelewhiteVoiceChangerError.modelLoadFailed("rvc: \(error.localizedDescription)")
        }
    }

    // Extracts HuBERT content features from a 16 kHz mono float frame.
    // Returns the [frames, featureDim] feature matrix flattened row-major,
    // along with the frame count so the caller can shape the RVC input.
    public func extractFeatures(_ samples: [Float]) throws -> (features: [Float], frames: Int, dim: Int) {
        let input = ONNXTensorInput(
            name: "source",
            shape: [1, 1, NSNumber(value: samples.count)],
            float: samples,
            count: UInt(samples.count)
        )
        let outputs: [ONNXTensorOutput]
        do {
            outputs = try hubert.run(inputs: [input], outputNames: ["embed"])
        } catch {
            throw TelewhiteVoiceChangerError.inferenceFailed("hubert: \(error.localizedDescription)")
        }
        guard let feature = outputs.first else {
            throw TelewhiteVoiceChangerError.inferenceFailed("hubert returned no output")
        }
        let shape = feature.shape.map { $0.intValue }
        // Expected shape [1, frames, dim]; fall back to a best-effort split.
        let frames = shape.count >= 3 ? shape[shape.count - 2] : 1
        let dim = shape.count >= 1 ? shape[shape.count - 1] : Int(feature.floatCount)
        let buffer = UnsafeBufferPointer(start: feature.floatData, count: Int(feature.floatCount))
        return (Array(buffer), frames, dim)
    }

    // Runs the RVC decoder over content features + per-frame pitch to synthesise
    // the target voice. `pitch` is one F0 value per feature frame; `pitchShift`
    // transposes it in semitones. Returns synthesised mono float samples at the
    // decoder's native rate.
    public func synthesize(features: [Float], frames: Int, dim: Int, pitch: [Float], pitchShift: Float) throws -> [Float] {
        let shiftFactor = powf(2.0, pitchShift / 12.0)
        let shiftedPitch = pitch.map { $0 * shiftFactor }

        let featureInput = ONNXTensorInput(
            name: "phone",
            shape: [1, NSNumber(value: frames), NSNumber(value: dim)],
            float: features,
            count: UInt(features.count)
        )
        let pitchInput = ONNXTensorInput(
            name: "pitchf",
            shape: [1, NSNumber(value: shiftedPitch.count)],
            float: shiftedPitch,
            count: UInt(shiftedPitch.count)
        )
        let outputs: [ONNXTensorOutput]
        do {
            outputs = try rvc.run(inputs: [featureInput, pitchInput], outputNames: ["audio"])
        } catch {
            throw TelewhiteVoiceChangerError.inferenceFailed("rvc: \(error.localizedDescription)")
        }
        guard let audio = outputs.first else {
            throw TelewhiteVoiceChangerError.inferenceFailed("rvc returned no output")
        }
        let buffer = UnsafeBufferPointer(start: audio.floatData, count: Int(audio.floatCount))
        return Array(buffer)
    }

    // Autocorrelation-based F0 estimate, one value per HuBERT frame (320-sample
    // hop at 16 kHz). ponytail: naive but real; produces a usable pitch contour
    // for the RVC decoder. Upgrade path: swap for an RMVPE ONNX model.
    public static func estimatePitch(_ samples: [Float], frames: Int) -> [Float] {
        guard frames > 0 else { return [] }
        let hop = max(1, samples.count / frames)
        let minLag = hubertSampleRate / 1100 // ~1100 Hz ceiling
        let maxLag = hubertSampleRate / 65    // ~65 Hz floor
        var pitches = [Float](repeating: 0.0, count: frames)

        for frameIndex in 0 ..< frames {
            let start = frameIndex * hop
            let end = min(start + maxLag * 2, samples.count)
            guard end - start > maxLag else { continue }

            var bestLag = 0
            var bestCorrelation: Float = 0.0
            for lag in minLag ... maxLag {
                var correlation: Float = 0.0
                var i = start
                while i + lag < end {
                    correlation += samples[i] * samples[i + lag]
                    i += 1
                }
                if correlation > bestCorrelation {
                    bestCorrelation = correlation
                    bestLag = lag
                }
            }
            if bestLag > 0 {
                pitches[frameIndex] = Float(hubertSampleRate) / Float(bestLag)
            }
        }
        return pitches
    }
}
