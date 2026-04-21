import Foundation
import SwiftData

@Model
final class Slip {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var reflection: String = ""
    var relatedUrgeID: UUID?

    init(timestamp: Date = Date(), reflection: String, relatedUrgeID: UUID? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.reflection = reflection
        self.relatedUrgeID = relatedUrgeID
    }
}
