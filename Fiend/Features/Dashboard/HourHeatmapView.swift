import SwiftUI
import Charts

struct HourHeatmapView: View {
    let buckets: [HourBucket]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Time of day").font(.headline)
                Text("When your urges tend to show up.")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)

                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Hour", bucket.hour),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(Theme.intensityColor(max(1, Int(bucket.avgIntensity.rounded()))))
                    .cornerRadius(2)
                }
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                        AxisValueLabel {
                            if let hr = value.as(Int.self) {
                                Text(hourLabel(hr))
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private func hourLabel(_ h: Int) -> String {
        switch h {
        case 0: return "12a"
        case 12: return "12p"
        case 1..<12: return "\(h)a"
        default: return "\(h - 12)p"
        }
    }
}
