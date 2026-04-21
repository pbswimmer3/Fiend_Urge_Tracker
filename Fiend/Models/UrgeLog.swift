import Foundation
import SwiftData
import CoreLocation

@Model
final class UrgeLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var intensity: Int = 1
    var latitude: Double?
    var longitude: Double?
    var tagsRaw: String = ""
    var usedRefocus: Bool = false
    var refocusSucceeded: Bool?
    var resultedInSlip: Bool = false
    var notes: String?

    init(
        timestamp: Date = Date(),
        intensity: Int,
        coordinate: CLLocationCoordinate2D? = nil,
        tags: [EmotionalTag] = [],
        usedRefocus: Bool = false,
        refocusSucceeded: Bool? = nil,
        resultedInSlip: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.intensity = intensity
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
        self.tagsRaw = tags.map(\.rawValue).joined(separator: ",")
        self.usedRefocus = usedRefocus
        self.refocusSucceeded = refocusSucceeded
        self.resultedInSlip = resultedInSlip
        self.notes = notes
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var tags: [EmotionalTag] {
        get {
            tagsRaw.split(separator: ",")
                .compactMap { EmotionalTag(rawValue: String($0)) }
        }
        set {
            tagsRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var isHighIntensity: Bool { intensity >= 4 }
}

enum EmotionalTag: String, CaseIterable, Identifiable, Codable {
    case hungry = "Hungry"
    case angry = "Angry"
    case lonely = "Lonely"
    case tired = "Tired"
    case stressed = "Stressed"
    case bored = "Bored"
    case anxious = "Anxious"
    case sad = "Sad"
    case celebratory = "Celebratory"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .hungry: return "fork.knife"
        case .angry: return "flame"
        case .lonely: return "person"
        case .tired: return "moon.zzz"
        case .stressed: return "bolt.heart"
        case .bored: return "clock.badge.questionmark"
        case .anxious: return "wind"
        case .sad: return "cloud.rain"
        case .celebratory: return "party.popper"
        }
    }
}
