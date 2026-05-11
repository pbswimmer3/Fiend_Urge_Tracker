import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UrgeLog.timestamp, order: .reverse) private var urges: [UrgeLog]
    @Query(sort: \Slip.timestamp, order: .reverse) private var slips: [Slip]

    enum Tab: String, CaseIterable { case urges = "Urges", slips = "Slips" }
    @State private var tab: Tab = .urges

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                switch tab {
                case .urges:
                    if urges.isEmpty {
                        ContentUnavailableView("No urges yet", systemImage: "hand.tap")
                    } else {
                        ForEach(urges, id: \.id) { urge in
                            UrgeRow(urge: urge)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        context.delete(urge)
                                        try? context.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                case .slips:
                    if slips.isEmpty {
                        ContentUnavailableView("No slips logged", systemImage: "leaf")
                    } else {
                        ForEach(slips, id: \.id) { slip in
                            SlipRow(slip: slip)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        context.delete(slip)
                                        try? context.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Theme.surface.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SlipRow: View {
    let slip: Slip
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(slip.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.medium))
            Text(slip.reflection)
                .font(.caption)
                .foregroundStyle(Theme.onSurfaceMuted)
                .lineLimit(3)
        }
        .padding(.vertical, Theme.Space.xs)
    }
}
