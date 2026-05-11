import SwiftUI

/// Sleek countdown / progress visualization for the home screen.
/// Outer ring tracks progress to the next milestone; inner digits live-tick.
struct SoberCountdownView: View {
    let cleanStartDate: Date
    let habitName: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let elapsed = max(0, ctx.date.timeIntervalSince(cleanStartDate))
            let parts = breakdown(elapsed: elapsed)
            let progress = MilestoneService.progress(elapsed: elapsed)
            let next = MilestoneService.nextMilestone(elapsed: elapsed)

            ZStack {
                // Track
                Circle()
                    .stroke(Theme.primary.opacity(0.08), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                // Progress
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [Theme.primary, Theme.accent, Theme.primary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)

                VStack(spacing: 2) {
                    Text("\(parts.days)")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.primary)
                        .contentTransition(.numericText())
                    Text(parts.days == 1 ? "day clean" : "days clean")
                        .font(.subheadline)
                        .foregroundStyle(Theme.onSurfaceMuted)
                    Text(String(format: "%02d:%02d:%02d", parts.hours, parts.minutes, parts.seconds))
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(Theme.primary.opacity(0.75))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, Theme.Space.m)

                if let next {
                    VStack {
                        Spacer()
                        Text("next: \(next.label)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.onSurfaceMuted)
                            .padding(.horizontal, Theme.Space.s)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Theme.surfaceElevated))
                            .padding(.bottom, Theme.Space.s)
                    }
                }
            }
            .frame(width: 240, height: 240)
        }
    }

    private func breakdown(elapsed: TimeInterval) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let s = Int(elapsed)
        return (s / 86_400, (s % 86_400) / 3_600, (s % 3_600) / 60, s % 60)
    }
}
