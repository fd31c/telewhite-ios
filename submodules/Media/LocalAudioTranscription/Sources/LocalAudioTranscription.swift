import Foundation
import SwiftSignalKit
import Speech

private var sharedRecognizers: [String: NSObject] = [:]

private struct TranscriptionResult {
    var text: String
    var confidence: Float
    var isFinal: Bool
}

private func transcribeAudio(path: String, locale: String) -> Signal<TranscriptionResult?, NoError> {
    return Signal { subscriber in
        let disposable = MetaDisposable()
        
        if #available(iOS 13.0, *) {
            SFSpeechRecognizer.requestAuthorization { status in
                Queue.mainQueue().async {
                    switch status {
                    case .notDetermined:
                        subscriber.putNext(nil)
                        subscriber.putCompletion()
                    case .restricted:
                        subscriber.putNext(nil)
                        subscriber.putCompletion()
                    case .denied:
                        subscriber.putNext(nil)
                        subscriber.putCompletion()
                    case .authorized:
                        let speechRecognizer: SFSpeechRecognizer
                        if let sharedRecognizer = sharedRecognizers[locale] as? SFSpeechRecognizer {
                            speechRecognizer = sharedRecognizer
                        } else {
                            guard let speechRecognizerValue = SFSpeechRecognizer(locale: Locale(identifier: locale)), speechRecognizerValue.isAvailable else {
                                subscriber.putNext(nil)
                                subscriber.putCompletion()
                                
                                return
                            }
                            speechRecognizerValue.defaultTaskHint = .dictation
                            sharedRecognizers[locale] = speechRecognizerValue
                            speechRecognizer = speechRecognizerValue
                            
                            if locale == "en-US" {
                                speechRecognizer.supportsOnDeviceRecognition = true
                            } else {
                                speechRecognizer.supportsOnDeviceRecognition = false
                            }
                            speechRecognizer.supportsOnDeviceRecognition = true
                        }
                        
                        let tempFilePath = NSTemporaryDirectory() + "/\(UInt64.random(in: 0 ... UInt64.max)).m4a"
                        let _ = try? FileManager.default.copyItem(atPath: path, toPath: tempFilePath)
                        
                        let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: tempFilePath))
                        if #available(iOS 16.0, *) {
                            request.addsPunctuation = true
                        }
                        request.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
                        request.shouldReportPartialResults = false
                        
                        let task = speechRecognizer.recognitionTask(with: request, resultHandler: { result, error in
                            if let result = result {
                                var confidence: Float = 0.0
                                for segment in result.bestTranscription.segments {
                                    confidence += segment.confidence
                                }
                                confidence /= Float(result.bestTranscription.segments.count)
                                subscriber.putNext(TranscriptionResult(text: result.bestTranscription.formattedString, confidence: confidence, isFinal: result.isFinal))
                                
                                if result.isFinal {
                                    subscriber.putCompletion()
                                }
                            } else {
                                print("transcribeAudio: locale: \(locale), error: \(String(describing: error))")
                                
                                subscriber.putNext(nil)
                                subscriber.putCompletion()
                            }
                        })
                        
                        disposable.set(ActionDisposable {
                            task.cancel()
                        })
                    @unknown default:
                        subscriber.putNext(nil)
                        subscriber.putCompletion()
                    }
                }
            }
        } else {
            subscriber.putNext(nil)
            subscriber.putCompletion()
        }
        
        return disposable
    }
    |> runOn(.mainQueue())
}

public struct LocallyTranscribedAudio {
    public var text: String
    public var isFinal: Bool
}

public func transcribeAudio(path: String, appLocale: String) -> Signal<LocallyTranscribedAudio?, NoError> {
    var signals: [Signal<TranscriptionResult?, NoError>] = []
    var locales: [String] = []
    if !locales.contains(Locale.current.identifier) {
        locales.append(Locale.current.identifier)
    }
    if locales.isEmpty {
        locales.append("en-US")
    }
    for locale in locales {
        signals.append(transcribeAudio(path: path, locale: locale))
    }
    var resultSignal: Signal<[TranscriptionResult?], NoError> = .single([])
    for signal in signals {
        resultSignal = resultSignal |> mapToSignal { result -> Signal<[TranscriptionResult?], NoError> in
            return signal |> map { next in
                return result + [next]
            }
        }
    }
    
    return resultSignal
    |> map { results -> LocallyTranscribedAudio? in
        let sortedResults = results.compactMap({ $0 }).sorted(by: { lhs, rhs in
            return lhs.confidence > rhs.confidence
        })
        return sortedResults.first.flatMap { result -> LocallyTranscribedAudio in
            return LocallyTranscribedAudio(text: result.text, isFinal: result.isFinal)
        }
    }
}

private func appendMultipartString(_ string: String, to data: inout Data) {
    if let stringData = string.data(using: .utf8) {
        data.append(stringData)
    }
}

public func transcribeAudioWithOpenRouter(path: String, apiKey: String) -> Signal<LocallyTranscribedAudio?, NoError> {
    return Signal { subscriber in
        guard !apiKey.isEmpty, let url = URL(string: "https://openrouter.ai/api/v1/audio/transcriptions"), let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            subscriber.putNext(nil)
            subscriber.putCompletion()
            return EmptyDisposable
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        appendMultipartString("--\(boundary)\r\n", to: &body)
        appendMultipartString("Content-Disposition: form-data; name=\"model\"\r\n\r\n", to: &body)
        appendMultipartString("openai/whisper-1\r\n", to: &body)
        appendMultipartString("--\(boundary)\r\n", to: &body)
        appendMultipartString("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n", to: &body)
        appendMultipartString("Content-Type: audio/mp4\r\n\r\n", to: &body)
        body.append(fileData)
        appendMultipartString("\r\n--\(boundary)--\r\n", to: &body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String else {
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return
            }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            subscriber.putNext(trimmed.isEmpty ? nil : LocallyTranscribedAudio(text: trimmed, isFinal: true))
            subscriber.putCompletion()
        }
        task.resume()

        return ActionDisposable {
            task.cancel()
        }
    }
}
