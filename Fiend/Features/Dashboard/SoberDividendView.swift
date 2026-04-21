import SwiftUI
import Charts

struct SoberDividendView: View {
    let dividend: SoberDividend

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Sober dividend").font(.headline)
                Text("Time and money the habit didn't take this run.")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)

                HStack(spacing: Theme.Space.l) {
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        Text("Hours reclaimed")
                            .font(.caption)
                            .foregroundStyle(Theme.onSurfaceMuted)
                        Text("\(Int(dividend.hoursReclaimed))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        Text("Dollars reclaimed")
                            .font(.caption)
                            .foregroundStyle(Theme.onSurfaceMuted)
                        Text("$\(Int(dividend.dollarsReclaimed))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primary)
                    }
                }
                .padding(.top, Theme.Space.xs)

                Chart {
                    BarMark(x: .value("kind", "Time back"), y: .value("hours", dividend.hoursReclaimed))
                        .foregroundStyle(Theme.accent)
                    BarMark(x: .value("kind", "Would've spent"), y: .value("hours", dividend.daysClean * dividend.hoursPerDay))
                        .foregroundStyle(Theme.warning)
                }
                .chartYAxisLabel("Hours")
                .frame(height: 120)
            }
        }
    }
}
