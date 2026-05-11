import SwiftUI
import SwiftData

/// Parent container for the EMI intervention. Lets the user pick breathing or grounding,
/// then records whether it helped them ride the wave without relapsing.
struct RefocusView: View {
    let log: UrgeLog
    var onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @State private var mode: Mode = .breathing
    @State private var stage: Stage = .intervention

    enum Mode: String, CaseIterable { case breathing = "Breathing", grounding = "Grounding" }
    enum Stage { case intervention, verdict }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.primaryDeep, Theme.primary],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Theme.Space.l) {
                header

                switch stage {
                case .intervention:
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Theme.Space.l)

                    Group {
                        switch mode {
                        case .breathing: BreathingPacer()
                        case .grounding: GroundingExercise()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Button("I feel steadier") {
                        withAnimation { stage = .verdict }
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.accent))
                    .padding(.horizontal, Theme.Space.l)

                case .verdict:
                    verdictPane
                }
            }
            .padding(.vertical, Theme.Space.l)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: Theme.Space.xs) {
            Text("Refocus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            Text("Let's ride this wave together.")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Space.l)
        }
    }

    private var verdictPane: some View {
        VStack(spacing: Theme.Space.m) {
            Text("Did that help?")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(spacing: Theme.Space.s) {
                Button {
                    record(success: true, slip: false)
                } label: {
                    Label("Yes, the urge passed", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.accent))

                Button {
                    record(success: false, slip: false)
                } label: {
                    Label("Still there, but I'm holding", systemImage: "wind")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.primary.opacity(0.7)))

                Button {
                    record(success: false, slip: true)
                } label: {
                    Label("I slipped — I'll reflect on it", systemImage: "exclamationmark.triangle.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.warning))
            }
            .padding(.horizontal, Theme.Space.l)
        }
    }

    private func record(success: Bool, slip: Bool) {
        log.usedRefocus = true
        log.refocusSucceeded = success
        log.resultedInSlip = slip
        try? context.save()
        onFinish()
    }
}

// MARK: - Breathing pacer

struct BreathingPacer: View {
    /// 4-7-8 pacing: inhale 4s, hold 7s, exhale 8s.
    /// One cycle = 19s. 60 seconds ≈ 3 full cycles.
    @State private var phase: Phase = .inhale
    @State private var remainingCycles: Int = 3
    @State private var timer: Timer?
    @State private var scale: CGFloat = 0.6

    enum Phase { case inhale, hold, exhale, done
        var duration: Double {
            switch self {
            case .inhale: return 4
            case .hold: return 7
            case .exhale: return 8
            case .done: return 0
            }
        }
        var next: Phase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .inhale
            case .done: return .done
            }
        }
        var label: String {
            switch self {
            case .inhale: return "Breathe in"
            case .hold: return "Hold"
            case .exhale: return "Breathe out"
            case .done: return "Well done"
            }
        }
    }

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.12 - Double(i) * 0.03), lineWidth: 1)
                        .frame(width: 260 + CGFloat(i) * 40, height: 260 + CGFloat(i) * 40)
                }
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: phase.duration), value: scale)
                VStack {
                    Text(phase.label)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(remainingCycles) cycle\(remainingCycles == 1 ? "" : "s") left")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .onAppear { start() }
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        advance()
    }

    private func advance() {
        switch phase {
        case .inhale: scale = 1.0
        case .hold:   scale = 1.0
        case .exhale: scale = 0.6
        case .done:   return
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: phase.duration, repeats: false) { _ in
            let next = phase.next
            if phase == .exhale {
                remainingCycles -= 1
                if remainingCycles <= 0 {
                    phase = .done
                    return
                }
            }
            phase = next
            advance()
        }
    }
}

// MARK: - Grounding (voice-gated)

struct GroundingExercise: View {
    private let prompts: [(Int, String, String)] = [
        (5, "see", "eye"),
        (4, "feel", "hand.raised"),
        (3, "hear", "ear"),
        (2, "smell", "nose"),
        (1, "taste", "mouth")
    ]
    @StateObject private var speech = SpeechService()
    @State private var index = 0
    @State private var requestedPermission = false

    private var currentPrompt: (Int, String, String) { prompts[index] }
    private var requiredWords: Int { currentPrompt.0 }
    private var canAdvance: Bool { speech.wordCount >= requiredWords }
    private var isLast: Bool { index == prompts.count - 1 }

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            Image(systemName: currentPrompt.2)
                .font(.system(size: 64, weight: .regular))
                .foregroundStyle(.white)

            Text("Name \(requiredWords) things you can \(currentPrompt.1)")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Space.l)

            VStack(spacing: Theme.Space.xs) {
                Text(speech.transcript.isEmpty ? "Tap the mic and say them out loud." : speech.transcript)
                    .font(.body)
                    .foregroundStyle(.white.opacity(speech.transcript.isEmpty ? 0.6 : 1.0))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Space.l)
                    .frame(minHeight: 60)

                Text("\(speech.wordCount) / \(requiredWords) words")
                    .font(.caption)
                    .foregroundStyle(canAdvance ? Theme.accent : .white.opacity(0.6))
            }

            HStack(spacing: Theme.Space.s) {
                Button {
                    if speech.isListening {
                        speech.stop()
                    } else {
                        speech.start()
                    }
                } label: {
                    Label(speech.isListening ? "Stop" : "Listen", systemImage: speech.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, Theme.Space.m)
                        .padding(.vertical, Theme.Space.s)
                        .background(.white.opacity(speech.isListening ? 0.35 : 0.18))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }

                Button {
                    speech.stop()
                    if isLast {
                        // Final prompt: parent's "I feel steadier" button completes the flow.
                        // We just mark this one done — the user can tap that button.
                    } else {
                        index += 1
                        speech.reset()
                    }
                } label: {
                    Text(isLast ? "Done" : "Next")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, Theme.Space.l)
                        .padding(.vertical, Theme.Space.s)
                        .background(canAdvance ? Theme.accent : Color.white.opacity(0.18))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                        .opacity(canAdvance ? 1 : 0.6)
                }
                .disabled(!canAdvance)
                .animation(.easeInOut(duration: 0.2), value: canAdvance)
            }

            if let err = speech.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Space.l)
            }
        }
        .task {
            if !requestedPermission {
                requestedPermission = true
                await speech.requestAuthorization()
            }
        }
        .onDisappear { speech.stop() }
    }
}
