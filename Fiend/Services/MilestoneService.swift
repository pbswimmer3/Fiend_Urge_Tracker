import Foundation

/// Pure functions over the `Milestone.all` table. No persistence.
enum MilestoneService {
    /// Most recent milestone the user has reached, given elapsed clean time.
    static func currentMilestone(elapsed: TimeInterval) -> Milestone? {
        Milestone.all.last(where: { elapsed >= $0.interval })
    }

    /// Next milestone ahead of the user.
    static func nextMilestone(elapsed: TimeInterval) -> Milestone? {
        Milestone.all.first(where: { elapsed < $0.interval })
    }

    /// Progress (0...1) from the previous milestone to the next.
    static func progress(elapsed: TimeInterval) -> Double {
        guard let next = nextMilestone(elapsed: elapsed) else { return 1.0 }
        let prevInterval = currentMilestone(elapsed: elapsed)?.interval ?? 0
        let span = next.interval - prevInterval
        guard span > 0 else { return 0 }
        return min(1, max(0, (elapsed - prevInterval) / span))
    }

    /// Time remaining (in seconds) to the next milestone.
    static func timeToNext(elapsed: TimeInterval) -> TimeInterval? {
        nextMilestone(elapsed: elapsed).map { $0.interval - elapsed }
    }

    /// All milestones the user has reached, ordered most-recent first.
    static func reached(elapsed: TimeInterval) -> [Milestone] {
        Milestone.all.filter { elapsed >= $0.interval }.reversed()
    }

    /// Returns the milestone to celebrate, if any, given the user's last acknowledgment.
    static func milestoneToCelebrate(elapsed: TimeInterval, lastAcknowledgedID: String?) -> Milestone? {
        guard let current = currentMilestone(elapsed: elapsed) else { return nil }
        if current.id == lastAcknowledgedID { return nil }
        return current
    }
}
