import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \UrgeLog.timestamp) private var urges: [UrgeLog]
    @Query(sort: \Slip.timestamp) private var slips: [Slip]
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.l) {
                    if urges.isEmpty {
                        emptyState
                    } else {
                        let engine = AnalyticsEngine(urges: urges, slips: slips)

                        if let insight = engine.topCorrelation() {
                            CorrelationInsightCard(text: insight)
                        }

                        HourHeatmapView(buckets: engine.hourlyBuckets())
                        WeekdayChartView(buckets: engine.weekdayBuckets())
                        UrgeWaveView(points: engine.urgeWave())
                        SuccessRateView(stats: engine.refocusSuccessRate())
                        DangerZoneMapView(zones: engine.dangerZones(), urges: urges)

                        if let profile = profiles.first {
                            SoberDividendView(
                                dividend: engine.soberDividend(
                                    since: profile.cleanStartDate,
                                    hoursPerDay: profile.dailyHoursReclaimed,
                                    dollarsPerDay: profile.dailyDollarsReclaimed
                                )
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Insights")
        }
    }

    private var emptyState: some View {
        Card {
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.primary.opacity(0.6))
                Text("Your charts will appear here.")
                    .font(.headline)
                Text("Log a few urges and come back. Insights unlock as your data grows.")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.m)
        }
    }
}

struct CorrelationInsightCard: View {
    let text: String
    var body: some View {
        Card {
            HStack(alignment: .top, spacing: Theme.Space.m) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pattern detected").font(.headline)
                    Text(text).font(.subheadline).foregroundStyle(Theme.onSurface)
                }
            }
        }
    }
}
