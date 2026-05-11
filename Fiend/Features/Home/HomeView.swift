import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Query(sort: \UrgeLog.timestamp, order: .reverse) private var urges: [UrgeLog]
    @Query(sort: \Slip.timestamp, order: .reverse) private var slips: [Slip]

    @State private var showingLogger = false
    @State private var showingSlip = false
    @State private var showingWhyEditor = false
    @State private var showingCounselor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.l) {
                    SoberDaysBadge(cleanStartDate: profile.cleanStartDate)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    countdownHero
                    MilestoneTrackerCard(cleanStartDate: profile.cleanStartDate)
                    oneTapLogger
                    WhyCard(why: profile.whyImDoingThis) { showingWhyEditor = true }
                    counselorEntry
                    todaySummary
                    recentActivity
                }
                .padding()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Fiend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSlip = true
                    } label: {
                        Label("Log slip", systemImage: "exclamationmark.triangle")
                    }
                    .tint(Theme.warning)
                }
            }
            .sheet(isPresented: $showingLogger) {
                UrgeLoggerView(profile: profile) { _ in
                    updateWidgetSnapshot()
                }
            }
            .sheet(isPresented: $showingSlip) {
                SlipLoggerView(profile: profile)
                    .onDisappear { updateWidgetSnapshot() }
            }
            .sheet(isPresented: $showingWhyEditor) {
                WhyEditor(profile: profile)
            }
            .onAppear { updateWidgetSnapshot() }
        }
    }

    // MARK: - Sections

    private var countdownHero: some View {
        Card {
            VStack(spacing: Theme.Space.m) {
                Text("Clean from \(profile.habitName)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.onSurfaceMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SoberCountdownView(
                    cleanStartDate: profile.cleanStartDate,
                    habitName: profile.habitName
                )
                .frame(maxWidth: .infinity)

                let cleanDays = AnalyticsEngine(urges: urges, slips: slips)
                    .cleanDaysInLast30(cleanStart: profile.cleanStartDate)
                HStack(spacing: Theme.Space.s) {
                    Image(systemName: "calendar")
                    Text("\(cleanDays) of the last 30 days clean")
                }
                .font(.footnote)
                .foregroundStyle(Theme.onSurfaceMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var oneTapLogger: some View {
        Button {
            showingLogger = true
        } label: {
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 36, weight: .bold))
                Text("Log an Urge")
                    .font(.title2.bold())
                Text("One tap. We'll handle the rest.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.vertical, Theme.Space.l)
        }
        .buttonStyle(PrimaryButtonStyle(tint: Theme.primary))
        .shadow(color: Theme.primary.opacity(0.25), radius: 14, y: 6)
    }

    private var counselorEntry: some View {
        NavigationLink {
            CounselorView(profile: profile)
        } label: {
            Card {
                HStack(spacing: Theme.Space.m) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's counselor digest")
                            .font(.headline)
                            .foregroundStyle(Theme.onSurface)
                        Text("A short read on what you might feel today.")
                            .font(.caption)
                            .foregroundStyle(Theme.onSurfaceMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var todaySummary: some View {
        let cal = Calendar.current
        let today = urges.filter { cal.isDateInToday($0.timestamp) }
        let avg = today.isEmpty ? 0 : Double(today.map(\.intensity).reduce(0, +)) / Double(today.count)
        return Card {
            HStack(spacing: Theme.Space.l) {
                stat(value: "\(today.count)", label: "today")
                stat(value: String(format: "%.1f", avg), label: "avg intensity")
                stat(value: "\(today.filter { $0.isHighIntensity }.count)", label: "high intensity")
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.bold()).foregroundStyle(Theme.primary)
            Text(label).font(.caption).foregroundStyle(Theme.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentActivity: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                HStack {
                    Text("Recent").font(.headline)
                    Spacer()
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Text("View all").font(.footnote.weight(.semibold))
                    }
                }
                if urges.isEmpty {
                    Text("No urges logged yet. When you feel one coming on, tap the big button above.")
                        .font(.footnote)
                        .foregroundStyle(Theme.onSurfaceMuted)
                } else {
                    let recent = Array(urges.prefix(5))
                    ForEach(recent, id: \.id) { urge in
                        UrgeRow(urge: urge)
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(urge)
                                    try? context.save()
                                    updateWidgetSnapshot()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        if urge.id != recent.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Widget snapshot

    private func updateWidgetSnapshot() {
        let elapsed = max(0, Date().timeIntervalSince(profile.cleanStartDate))
        let next = MilestoneService.nextMilestone(elapsed: elapsed)
        let nextDate = next.map { profile.cleanStartDate.addingTimeInterval($0.interval) }
        let engine = AnalyticsEngine(urges: urges, slips: slips)
        let snapshot = WidgetSnapshot(
            habitName: profile.habitName,
            cleanStartDate: profile.cleanStartDate,
            totalUrges: urges.count,
            totalSlips: slips.count,
            lastUrgeIntensity: urges.first?.intensity,
            lastUrgeDate: urges.first?.timestamp,
            cleanDaysInLast30: engine.cleanDaysInLast30(cleanStart: profile.cleanStartDate),
            nextMilestoneLabel: next?.label,
            nextMilestoneDate: nextDate,
            motivation: profile.whyImDoingThis.isEmpty ? nil : profile.whyImDoingThis
        )
        WidgetBridge.write(snapshot)
    }
}

// MARK: - Why editor

struct WhyEditor: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.m) {
                    Text("The reason you started.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.onSurfaceMuted)
                    TextEditor(text: $text)
                        .frame(minHeight: 200)
                        .padding(Theme.Space.s)
                        .background(Theme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                }
                .padding()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Why")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile.whyImDoingThis = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .onAppear { text = profile.whyImDoingThis }
        }
    }
}

// MARK: - Urge row (kept here for reuse)

struct UrgeRow: View {
    let urge: UrgeLog

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            ZStack {
                Circle()
                    .fill(Theme.intensityColor(urge.intensity).opacity(0.2))
                Text("\(urge.intensity)")
                    .font(.headline)
                    .foregroundStyle(Theme.intensityColor(urge.intensity))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(urge.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                if !urge.tags.isEmpty {
                    Text(urge.tags.map(\.rawValue).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
            }
            Spacer()
            if urge.usedRefocus {
                Image(systemName: urge.refocusSucceeded == true ? "wind.circle.fill" : "wind.circle")
                    .foregroundStyle(urge.refocusSucceeded == true ? Theme.accent : Theme.onSurfaceMuted)
            }
        }
    }
}
