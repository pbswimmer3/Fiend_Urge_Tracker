import SwiftUI
import Charts

struct UrgeWaveView: View {
    let points: [UrgeWavePoint]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("The Urge Wave").font(.headline)
                Text("7-day rolling average intensity. Watch it flatten.")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)

                if points.count < 2 {
                    Text("Log at least two days of urges to see your trend line.")
                        .font(.footnote)
                        .foregroundStyle(Theme.onSurfaceMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Theme.Space.m)
                } else {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Intensity", point.rollingAvgIntensity)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.primary)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Intensity", point.rollingAvgIntensity)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.primary.opacity(0.3), Theme.primary.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    }
                    .chartYScale(domain: 0...5)
                    .frame(height: 180)
                }
            }
        }
    }
}
