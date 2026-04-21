import SwiftUI
import MapKit

struct DangerZoneMapView: View {
    let zones: [DangerZone]
    let urges: [UrgeLog]

    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Text("Trigger zones").font(.headline)
                Text("Places where urges cluster. Stays on this device.")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)

                if !hasAnyCoordinates {
                    Text("Turn on location and log a few urges — the map fills in from there.")
                        .font(.footnote)
                        .foregroundStyle(Theme.onSurfaceMuted)
                        .padding(.vertical, Theme.Space.m)
                } else {
                    Map(position: $camera) {
                        ForEach(urges, id: \.id) { urge in
                            if let c = urge.coordinate {
                                Annotation("", coordinate: c) {
                                    Circle()
                                        .fill(Theme.intensityColor(urge.intensity).opacity(0.55))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        ForEach(zones) { zone in
                            MapCircle(center: zone.coordinate, radius: 200)
                                .foregroundStyle(Theme.danger.opacity(0.2))
                                .stroke(Theme.danger.opacity(0.6), lineWidth: 1.5)
                            Annotation("\(zone.count) urges", coordinate: zone.coordinate) {
                                Label("\(zone.count)", systemImage: "exclamationmark.triangle.fill")
                                    .labelStyle(.iconOnly)
                                    .padding(6)
                                    .background(Circle().fill(Theme.danger))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .flat))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                }
            }
        }
    }

    private var hasAnyCoordinates: Bool {
        urges.contains(where: { $0.coordinate != nil })
    }
}
