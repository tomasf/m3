import Foundation
import Cadova
import Helical

struct RailCover: Shape3D {
    let length: Double
    static let standardLength = cornerCoverHeight

    let width = railCarriage.size.y + 0.5
    static let centerThickness = 6.0
    let edgeThickness = 2.0

    let holeDiameter = 2.75
    let holeDepth = 5.0

    var body: any Geometry3D {
        Circle(chordLength: width, sagitta: Self.centerThickness - edgeThickness)
            .aligned(at: .minY)
            .intersecting {
                Rectangle(x: width, y: Self.centerThickness)
                    .aligned(at: .centerX)
            }
            .extruded(height: length)
            .translated(z: baseHeight + 0.2)
            .subtracting {
                Cylinder(diameter: holeDiameter, height: holeDepth + 1)
                    .translated(z: -1)
                    .rotated(x: 90°)
                    .translated(y: Self.centerThickness)
                    .translated(z: railOffsetFromBottom + rail.holeDistance / 2)
                    .repeated(along: .z, in: 0..<rail.size.z, step: rail.holeDistance)
            }
            .aligned(at: .bottom)
    }
}

let railCover = RailCover(length: RailCover.standardLength)

