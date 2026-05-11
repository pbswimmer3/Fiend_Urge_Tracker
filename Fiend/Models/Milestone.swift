import Foundation

/// Recovery milestones. Pure value type — milestone progress is computed,
/// not stored, so we never have to migrate old "achieved milestones" rows.
struct Milestone: Identifiable, Hashable, Sendable {
    let id: String
    let interval: TimeInterval
    let label: String
    let symbol: String

    static let all: [Milestone] = {
        let h: TimeInterval = 3600
        let d: TimeInterval = 86_400
        return [
            Milestone(id: "12h",   interval: 12 * h,     label: "12 hours",    symbol: "12.circle.fill"),
            Milestone(id: "24h",   interval: 24 * h,     label: "24 hours",    symbol: "24.circle.fill"),
            Milestone(id: "2d",    interval: 2 * d,      label: "2 days",      symbol: "2.circle.fill"),
            Milestone(id: "3d",    interval: 3 * d,      label: "3 days",      symbol: "3.circle.fill"),
            Milestone(id: "4d",    interval: 4 * d,      label: "4 days",      symbol: "4.circle.fill"),
            Milestone(id: "5d",    interval: 5 * d,      label: "5 days",      symbol: "5.circle.fill"),
            Milestone(id: "6d",    interval: 6 * d,      label: "6 days",      symbol: "6.circle.fill"),
            Milestone(id: "7d",    interval: 7 * d,      label: "1 week",      symbol: "7.circle.fill"),
            Milestone(id: "10d",   interval: 10 * d,     label: "10 days",     symbol: "10.circle.fill"),
            Milestone(id: "14d",   interval: 14 * d,     label: "2 weeks",     symbol: "calendar"),
            Milestone(id: "21d",   interval: 21 * d,     label: "3 weeks",     symbol: "calendar"),
            Milestone(id: "30d",   interval: 30 * d,     label: "1 month",     symbol: "30.circle.fill"),
            Milestone(id: "45d",   interval: 45 * d,     label: "6 weeks",     symbol: "calendar.badge.clock"),
            Milestone(id: "60d",   interval: 60 * d,     label: "2 months",    symbol: "calendar"),
            Milestone(id: "90d",   interval: 90 * d,     label: "3 months",    symbol: "calendar"),
            Milestone(id: "100d",  interval: 100 * d,    label: "100 days",    symbol: "100.circle.fill"),
            Milestone(id: "182d",  interval: 182 * d,    label: "6 months",    symbol: "calendar.badge.checkmark"),
            Milestone(id: "200d",  interval: 200 * d,    label: "200 days",    symbol: "star.fill"),
            Milestone(id: "300d",  interval: 300 * d,    label: "300 days",    symbol: "star.fill"),
            Milestone(id: "365d",  interval: 365 * d,    label: "1 year",      symbol: "crown.fill"),
            Milestone(id: "500d",  interval: 500 * d,    label: "500 days",    symbol: "crown.fill"),
            Milestone(id: "547d",  interval: 547 * d,    label: "1.5 years",   symbol: "crown.fill"),
            Milestone(id: "730d",  interval: 730 * d,    label: "2 years",     symbol: "crown.fill"),
            Milestone(id: "1095d", interval: 1095 * d,   label: "3 years",     symbol: "trophy.fill"),
            Milestone(id: "1825d", interval: 1825 * d,   label: "5 years",     symbol: "trophy.fill")
        ]
    }()
}
