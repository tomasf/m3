import Cadova

/// An assembly jig that holds a pair of arm rods at exactly `Kinematics.armLength` between
/// centers while their ball joints are glued on. Both arms of a pair have to match to within a
/// fraction of a millimeter, so they are built in the jig rather than measured individually.
struct ArmJig: Geometry3D {
    static let armCount = 2

    var body: any Geometry3D {
        @Environment(\.tolerance) var tolerance

        let pinDiameter = 3.0 - tolerance
        let pinLength = 7.0
        let socketDiameter = 7.0 + tolerance
        let socketLength = 3.0
        let socketInset = 1.0
        let width = socketDiameter + 6.0
        let baseThickness = 3.0
        let endLength = 17.0
        let ringThickness = 3.0
        let barThickness = 2.0
        let barOffset = 3.0
        let ringBaseDiameter = 6.0
        let raiseHeight = 3.0

        // One end stop: a pin the rod slips over, braced back to a cradle for the ball joint
        let holder = Union {
            Cylinder(diameter: ringBaseDiameter, height: raiseHeight)
                .translated(z: baseThickness)

            Cylinder(diameter: pinDiameter, height: pinLength)
                .translated(z: baseThickness + raiseHeight)

            Box([barThickness, width, baseThickness + pinLength / 2 - ringThickness / 2 + raiseHeight])
                .aligned(at: .maxX, .centerY)
                .translated(x: -barOffset)

            Box([socketLength, width, baseThickness + socketDiameter / 2 + raiseHeight])
                .aligned(at: .centerY)
                .subtracting {
                    Cylinder(diameter: socketDiameter, height: socketLength + 2)
                        .translated(z: -1)
                        .rotated(y: 90°)
                        .translated(z: baseThickness + socketDiameter / 2 + raiseHeight)
                }
                .translated(x: -endLength + socketInset)
        }

        holder
            .translated(x: Kinematics.armLength / 2)
            .symmetry(over: .x)
            .repeated(along: .y, step: width, count: Self.armCount)
            .translated(y: width / 2)

        Box([Kinematics.armLength + width, width * Double(Self.armCount), baseThickness])
            .cuttingEdgeProfile(.fillet(radius: width / 2), along: .z)
            .aligned(at: .centerX)
    }
}
