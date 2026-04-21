import SwiftUI

struct SuccessRateView: View {
    let stats: RefocusStats

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Refocus success rate").font(.headline)
                Text("How often breathing or grounding carried you through.")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)

                if stats.attempts == 0 {
                    Text("Trigger a high-intensity log to start using Refocus.")
                        .font(.footnote)
                        .foregroundStyle(Theme.onSurfaceMuted)
                        .padding(.vertical, Theme.Space.m)
                } else {
                    HStack(alignment: .center, spacing: Theme.Space.l) {
                        ZStack {
                            Circle()
                                .stroke(Theme.accent.opacity(0.15), lineWidth: 10)
                            Circle()
                                .trim(from: 0, to: stats.rate)
                                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(stats.rate * 100))%")
                                .font(.title3.bold())
                                .foregroundStyle(Theme.accent)
                        }
                        .frame(width: 90, height: 90)

                        VStack(alignment: .leading, spacing: Theme.Space.xs) {
                            Label("\(stats.attempts) attempts", systemImage: "wind")
                            Label("\(stats.successes) carried through", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}
