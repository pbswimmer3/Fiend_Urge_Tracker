import SwiftUI
import SwiftData

struct SlipLoggerView: View {
    let profile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var reflection: String = ""
    @State private var timestamp: Date = Date()
    @State private var resetCleanDate: Bool = false

    private let minReflectionChars = 40

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    intro
                    dateRow
                    reflectionBox
                    resetToggle
                }
                .padding()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Slip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(reflection.count < minReflectionChars)
                }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("A slip is data, not a verdict.")
                .font(.title2.bold())
            Text("Take a breath. Answer honestly. Your \"clean days in the last 30\" will still show the truth — a streak reset can't erase the days you already did.")
                .foregroundStyle(Theme.onSurfaceMuted)
        }
    }

    private var dateRow: some View {
        Card {
            DatePicker("When did it happen?", selection: $timestamp, in: ...Date())
                .tint(Theme.primary)
        }
    }

    private var reflectionBox: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("What happened?").font(.headline)
                Text("Where were you, who were you with, what was the trigger, what did you feel right before?")
                    .font(.footnote)
                    .foregroundStyle(Theme.onSurfaceMuted)
                TextEditor(text: $reflection)
                    .frame(minHeight: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.s)
                            .stroke(Theme.onSurfaceMuted.opacity(0.25))
                    )
                Text("\(reflection.count) / \(minReflectionChars) characters minimum")
                    .font(.caption)
                    .foregroundStyle(reflection.count >= minReflectionChars ? Theme.accent : Theme.onSurfaceMuted)
            }
        }
    }

    private var resetToggle: some View {
        Card {
            Toggle(isOn: $resetCleanDate) {
                VStack(alignment: .leading) {
                    Text("Reset clean start to this moment")
                        .font(.subheadline.weight(.medium))
                    Text("Optional. Many people prefer to keep the original date and focus on the \"clean days out of 30\" metric instead.")
                        .font(.caption)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
            }
            .tint(Theme.primary)
        }
    }

    private func save() {
        let slip = Slip(timestamp: timestamp, reflection: reflection)
        context.insert(slip)
        if resetCleanDate {
            profile.cleanStartDate = timestamp
            profile.lastAcknowledgedMilestoneID = nil
            Task {
                await NotificationService.shared.scheduleUpcomingMilestoneAlerts(cleanStart: profile.cleanStartDate)
            }
        }
        try? context.save()
        dismiss()
    }
}
