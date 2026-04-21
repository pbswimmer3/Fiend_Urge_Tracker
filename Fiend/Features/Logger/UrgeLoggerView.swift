import SwiftUI
import SwiftData
import CoreLocation

struct UrgeLoggerView: View {
    let profile: UserProfile
    /// Called when the sheet dismisses. Passes the log, or nil if cancelled.
    var onComplete: ((UrgeLog?) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var intensity: Double = 3
    @State private var selectedTags: Set<EmotionalTag> = []
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var flashFeedback: Bool = false
    @State private var showRefocus: Bool = false
    @State private var pendingHighIntensityLog: UrgeLog?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    header
                    intensitySelector
                    tagGrid
                    notesField
                }
                .padding()
            }
            .background(Theme.surface.ignoresSafeArea())
            .navigationTitle("Log Urge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete?(nil)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
            .overlay {
                if flashFeedback {
                    SavedFlash()
                        .transition(.opacity)
                }
            }
            .fullScreenCover(isPresented: $showRefocus) {
                if let log = pendingHighIntensityLog {
                    RefocusView(log: log) {
                        flashAndDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("How strong is the pull?")
                .font(.title2.bold())
            Text("One to five. No wrong answer.")
                .font(.subheadline)
                .foregroundStyle(Theme.onSurfaceMuted)
        }
    }

    private var intensitySelector: some View {
        VStack(spacing: Theme.Space.m) {
            ZStack {
                Circle()
                    .fill(Theme.intensityColor(Int(intensity.rounded())).opacity(0.15))
                    .frame(width: 180, height: 180)
                Text("\(Int(intensity.rounded()))")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.intensityColor(Int(intensity.rounded())))
                    .contentTransition(.numericText())
            }
            Slider(value: $intensity, in: 1...5, step: 1)
                .tint(Theme.intensityColor(Int(intensity.rounded())))
            HStack {
                Text("Mild").font(.caption).foregroundStyle(Theme.onSurfaceMuted)
                Spacer()
                Text("Overwhelming").font(.caption).foregroundStyle(Theme.onSurfaceMuted)
            }
        }
        .animation(.spring(duration: 0.25), value: intensity)
    }

    private var tagGrid: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("What's going on?").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Theme.Space.s)], spacing: Theme.Space.s) {
                ForEach(EmotionalTag.allCases) { tag in
                    TagChip(tag: tag, selected: selectedTags.contains(tag)) {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("Notes (optional)").font(.headline)
            TextField("Anything you want to remember about this moment…", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)
        }
    }

    // MARK: - Save flow

    @MainActor
    private func save() async {
        isSaving = true
        defer { isSaving = false }

        var coordinate: CLLocationCoordinate2D? = nil
        if profile.locationPermissionGranted {
            coordinate = await LocationService.shared.oneShotLocation()?.coordinate
        }

        let level = Int(intensity.rounded())
        let log = UrgeLog(
            intensity: level,
            coordinate: coordinate,
            tags: Array(selectedTags),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        context.insert(log)
        try? context.save()

        if level >= 4 {
            pendingHighIntensityLog = log
            showRefocus = true
        } else {
            flashAndDismiss()
        }
    }

    private func flashAndDismiss() {
        withAnimation { flashFeedback = true }
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onComplete?(pendingHighIntensityLog)
            dismiss()
        }
    }
}

private struct TagChip: View {
    let tag: EmotionalTag
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.xs) {
                Image(systemName: tag.symbol)
                Text(tag.rawValue)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, Theme.Space.m)
            .padding(.vertical, Theme.Space.s)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .fill(selected ? Theme.primary : Theme.primary.opacity(0.08))
            )
            .foregroundStyle(selected ? .white : Theme.primary)
        }
        .buttonStyle(.plain)
    }
}

private struct SavedFlash: View {
    var body: some View {
        ZStack {
            Theme.accent.opacity(0.15).ignoresSafeArea()
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.accent)
                Text("Logged").font(.title3.bold())
            }
        }
    }
}
