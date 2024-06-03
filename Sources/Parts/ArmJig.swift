import Foundation
import SwiftSCAD
import Helical

struct ArmJig: Shape3D {
    var body: Geometry3D {
        EnvironmentReader { e in
            let armCount = 2
            let pinDiameter = 3.0 - e.tolerance
            let pinLength = 7.0
            let baseDiameter = 7.0 + e.tolerance
            let baseLength = 3.0
            let baseInset = 1.0
            let width = baseDiameter + 4.0
            let baseThickness = 3.0
            let endLength = 17.0
            let ringThickness = 3.0
            let barThickness = 2.0
            let barOffset = 3.0

            let holder = Union {
                //Cylinder(diameter: width, height: baseThickness)
                Cylinder(diameter: pinDiameter, height: pinLength)
                    .translated(z: baseThickness)
                Box([barThickness, width, baseThickness + pinLength / 2 - ringThickness / 2])
                    .aligned(at: .maxX, .centerY)
                    .translated(x: -barOffset)

                Box([baseLength, width, baseThickness + baseDiameter / 2])
                    .aligned(at: .centerY)
                    .subtracting {
                        Cylinder(diameter: baseDiameter, height: baseLength + 2)
                            .translated(z: -1)
                            .rotated(y: 90°)
                            .translated(z: baseThickness + baseDiameter / 2)
                    }
                    .translated(x: -endLength + baseInset)
            }
            holder
                .translated(x: armLength / 2)
                .symmetry(over: .x)
                .repeated(along: .y, step: width, count: armCount)
                .translated(y: width / 2)
            Box([armLength + width, width * Double(armCount), baseThickness])
                .roundingBoxCorners(axis: .z, radius: width / 2)
                .aligned(at: .centerX)
        }
    }
}
