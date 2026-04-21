import SwiftUI
import Charts

struct WeekdayChartView: View {
    let buckets: [WeekdayBucket]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Day of week").font(.headline)
                Text("Which days carry the most weight.")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)

                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Day", bucket.name),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(Theme.primary)
                    .cornerRadius(4)
                }
                .frame(height: 160)
            }
        }
    }
}
