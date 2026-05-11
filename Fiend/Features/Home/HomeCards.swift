import SwiftUI

// MARK: - Sober days badge

struct SoberDaysBadge: View {
    let cleanStartDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { ctx in
            let days = max(0, Int(ctx.date.timeIntervalSince(cleanStartDate)) / 86_400)
            HStack(spacing: Theme.Space.s) {
                ZStack {
                    Capsule()
                        .fill(Theme.primary)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.white)
                        Text("\(days) day\(days == 1 ? "" : "s") sober")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, Theme.Space.m)
                    .padding(.vertical, Theme.Space.s)
                }
                .fixedSize()

                VStack(alignment: .leading, spacing: 0) {
                    Text("Since")
                        .font(.caption2)
                        .foregroundStyle(Theme.onSurfaceMuted)
                    Text(cleanStartDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.onSurface)
                }
            }
        }
    }
}

// MARK: - Why card

struct WhyCard: View {
    let why: String
    var onEdit: () -> Void

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: Theme.Space.m) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why I'm doing this")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.onSurfaceMuted)
                    if why.isEmpty {
                        Text("Tap to write the reason you started.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.onSurfaceMuted)
                            .italic()
                    } else {
                        Text(why)
                            .font(.body)
                            .foregroundStyle(Theme.onSurface)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(Theme.primary)
                }
            }
        }
    }
}

// MARK: - Milestone tracker card

struct MilestoneTrackerCard: View {
    let cleanStartDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { ctx in
            let elapsed = max(0, ctx.date.timeIntervalSince(cleanStartDate))
            let last = MilestoneService.currentMilestone(elapsed: elapsed)
            let next = MilestoneService.nextMilestone(elapsed: elapsed)
            let progress = MilestoneService.progress(elapsed: elapsed)
            let remaining = MilestoneService.timeToNext(elapsed: elapsed)

            Card {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text("Milestones").font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last")
                                .font(.caption)
                                .foregroundStyle(Theme.onSurfaceMuted)
                            HStack(spacing: 4) {
                                Image(systemName: last?.symbol ?? "circle")
                                    .foregroundStyle(Theme.accent)
                                Text(last?.label ?? "Just started")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next")
                                .font(.caption)
                                .foregroundStyle(Theme.onSurfaceMuted)
                            HStack(spacing: 4) {
                                Text(next?.label ?? "All complete")
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: next?.symbol ?? "checkmark.circle.fill")
                                    .foregroundStyle(Theme.primary)
                            }
                        }
                    }

                    ProgressView(value: progress)
                        .tint(Theme.primary)

                    if let remaining {
                        Text("\(remainingLabel(seconds: remaining)) to go")
                            .font(.caption)
                            .foregroundStyle(Theme.onSurfaceMuted)
                    }
                }
            }
        }
    }

    private func remainingLabel(seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes / 60) % 24
        let mins = totalMinutes % 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}
