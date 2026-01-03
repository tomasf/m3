import Foundation
import Cadova
import Helical

struct ArmJig: Shape3D {
    @Environment(\.tolerance) var tolerance

    var body: any Geometry3D {
        let armCount = 2
        let pinDiameter = 3.0 - tolerance
        let pinLength = 7.0
        let baseDiameter = 7.0 + tolerance
        let baseLength = 3.0
        let baseInset = 1.0
        let width = baseDiameter + 6.0
        let baseThickness = 3.0
        let endLength = 17.0
        let ringThickness = 3.0
        let barThickness = 2.0
        let barOffset = 3.0

        let ringBaseDiameter = 6.0
        let raiseHeight = 3.0

        let holder = Union {
            //Cylinder(diameter: width, height: baseThickness)
            Cylinder(diameter: ringBaseDiameter, height: raiseHeight)
                .translated(z: baseThickness)
            Cylinder(diameter: pinDiameter, height: pinLength)
                .translated(z: baseThickness + raiseHeight)

            Box([barThickness, width, baseThickness + pinLength / 2 - ringThickness / 2 + raiseHeight])
                .aligned(at: .maxX, .centerY)
                .translated(x: -barOffset)

            Box([baseLength, width, baseThickness + baseDiameter / 2 + raiseHeight])
                .aligned(at: .centerY)
                .subtracting {
                    Cylinder(diameter: baseDiameter, height: baseLength + 2)
                        .translated(z: -1)
                        .rotated(y: 90°)
                        .translated(z: baseThickness + baseDiameter / 2 + raiseHeight)
                }
                .translated(x: -endLength + baseInset)
        }
        holder
            .translated(x: armLength / 2)
            .symmetry(over: .x)
            .repeated(along: .y, step: width, count: armCount)
            .translated(y: width / 2)
        Box([armLength + width, width * Double(armCount), baseThickness])
            .cuttingEdgeProfile(.fillet(radius: width / 2), along: .z)
            .aligned(at: .centerX)
    }
}
