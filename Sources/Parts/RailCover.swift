import Cadova

/// The curved strip that snaps over the exposed length of a linear rail between the base and the
/// top, keeping dust off the raceway.
struct RailCover: Geometry3D {
    static let standardLength = CornerCover.standardHeight
    static let centerThickness = 6.0

    static let width = LinearRailCarriage.size.y + 0.5
    static let edgeThickness = 2.0
    static let holeDiameter = 2.75
    static let holeDepth = 5.0

    let length: Double

    var body: any Geometry3D {
        Circle(chordLength: Self.width, sagitta: Self.centerThickness - Self.edgeThickness)
            .aligned(at: .minY)
            .intersecting {
                Rectangle(x: Self.width, y: Self.centerThickness)
                    .aligned(at: .centerX)
            }
            .extruded(height: length)
            .translated(z: Base.height + 0.2)
            .subtracting {
                // Clears the rail's own mounting screws
                Cylinder(diameter: Self.holeDiameter, height: Self.holeDepth + 1)
                    .translated(z: -1)
                    .rotated(x: 90°)
                    .translated(y: Self.centerThickness)
                    .translated(z: Motion.railOffsetFromBottom + LinearRail.holeDistance / 2)
                    .repeated(along: .z, in: 0..<LinearRail.size.z, step: LinearRail.holeDistance)
            }
            .aligned(at: .bottom)
    }
}
