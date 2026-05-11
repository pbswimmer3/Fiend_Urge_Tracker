import SwiftUI

/// Fullscreen celebration shown the first time the user opens the app after
/// crossing a new milestone. Dismissed via tap or the explicit button.
struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let habitName: String
    var onDismiss: () -> Void

    @State private var pulse = false
    @State private var confettiSeed = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.primaryDeep, Theme.primary, Theme.accent.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ConfettiView(seed: confettiSeed)
                .allowsHitTesting(false)

            VStack(spacing: Theme.Space.l) {
                Spacer()
                Image(systemName: milestone.symbol)
                    .resizable().scaledToFit()
                    .frame(width: 140, height: 140)
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.4), radius: 24)
                    .scaleEffect(pulse ? 1.05 : 0.92)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                VStack(spacing: Theme.Space.xs) {
                    Text("Milestone unlocked")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(milestone.label)
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("free of \(habitName)")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Label("Keep going", systemImage: "arrow.forward.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: .white.opacity(0.25)))
                .padding(.horizontal, Theme.Space.l)
                .padding(.bottom, Theme.Space.l)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pulse = true
            confettiSeed = Int.random(in: 0...10_000)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .onTapGesture { onDismiss() }
    }
}

// MARK: - Confetti

private struct ConfettiView: View {
    let seed: Int

    private let colors: [Color] = [
        Theme.accent, .white, Theme.warning, .yellow.opacity(0.85), .cyan.opacity(0.8)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0)) { ctx in
            Canvas { context, size in
                let elapsed = ctx.date.timeIntervalSinceReferenceDate
                var rng = SeededGenerator(seed: UInt64(seed) &+ 1)
                for _ in 0..<80 {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let speed = CGFloat.random(in: 60...160, using: &rng)
                    let phase = CGFloat.random(in: 0...10, using: &rng)
                    let y = ((CGFloat(elapsed) * speed) + phase * 80).truncatingRemainder(dividingBy: size.height + 60) - 30
                    let w = CGFloat.random(in: 4...8, using: &rng)
                    let h = CGFloat.random(in: 8...14, using: &rng)
                    let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    let path = Path(roundedRect: rect, cornerRadius: 2)
                    context.fill(path, with: .color(color.opacity(0.85)))
                }
            }
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xdead_beef : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }
}
