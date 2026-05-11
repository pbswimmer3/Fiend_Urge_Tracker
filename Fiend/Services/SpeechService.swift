import Foundation
import Speech
import AVFoundation

/// Voice-input wrapper using Apple's on-device Speech framework.
/// Used during the grounding exercise to require the user to actually verbalize
/// what they're noticing before advancing.
@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published private(set) var transcript: String = ""
    @Published private(set) var isListening: Bool = false
    @Published private(set) var authorized: Bool = false
    @Published private(set) var lastError: String?

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Requests mic + speech permission. Idempotent.
    func requestAuthorization() async {
        let speechStatus = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        authorized = (speechStatus == .authorized && micGranted)
    }

    func start() {
        guard !isListening else { return }
        guard authorized else {
            lastError = "Microphone or speech recognition is not authorized."
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            lastError = "Speech recognition isn't available right now."
            return
        }
        transcript = ""
        lastError = nil

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            lastError = "Audio session error: \(error.localizedDescription)"
            return
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if #available(iOS 16.0, *) {
            req.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
            req.addsPunctuation = false
        }
        request = req

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak req] buffer, _ in
            req?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            lastError = "Couldn't start audio engine: \(error.localizedDescription)"
            return
        }

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        isListening = false
    }

    /// Reset transcript for a fresh prompt without re-asking for permission.
    func reset() {
        transcript = ""
        lastError = nil
    }

    /// Word count helper for advancement gating.
    var wordCount: Int {
        transcript.split { $0.isWhitespace || $0.isPunctuation }.count
    }
}
