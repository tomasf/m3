import Cadova

/// A filament spool roller: a printed tube running on a bearing at each end, with the bearings
/// held by screws driven into the tube's ends.
struct Roller: Geometry3D {
    static let bearingDiameter = 10.0
    static let bearingThickness = 4.0
    static let screwHeadDiameter = 5.5
    static let screwHeadThickness = 2.2
    static let screwPilotHoleDiameter = 2.6
    static let screwPilotHoleDepth = 12.0
    static let washerThickness = 0.5
    static let washerDiameter = 7.0

    static let outerDiameter = bearingDiameter + 5.0

    let length: Double

    var body: any Geometry3D {
        Cylinder(diameter: Self.outerDiameter, height: length)
            .adding {
                Cylinder(diameter: Self.washerDiameter, height: Self.washerThickness)
                    .translated(z: length)

                // Bearing and screw head, shown for reference at both ends
                Stack(.z, alignment: .center) {
                    Cylinder(diameter: Self.bearingDiameter, height: Self.bearingThickness)
                    Cylinder(diameter: Self.screwHeadDiameter, height: Self.screwHeadThickness)
                }
                .translated(z: length / 2 + Self.washerThickness)
                .symmetry(over: .z)
                .translated(z: length / 2)
                .inBackground()
            }
            .subtracting {
                // Screw pilot holes
                Cylinder(
                    diameter: Self.screwPilotHoleDiameter,
                    height: Self.screwPilotHoleDepth + Self.washerThickness + 1
                )
                .translated(z: length / 2 - Self.screwPilotHoleDepth)
                .symmetry(over: .z)
                .translated(z: length / 2)
            }
    }
}
