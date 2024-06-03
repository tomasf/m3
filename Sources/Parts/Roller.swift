import Foundation
import SwiftSCAD
import Helical

struct Roller: Shape3D {
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

    var body: Geometry3D {
        Cylinder(diameter: Roller.outerDiameter, height: length)
            .adding {
                Cylinder(
                    diameter: Roller.washerDiameter,
                    height: Roller.washerThickness
                )
                .translated(z: length)

                Stack(.z, alignment: .center) {
                    Cylinder(
                        diameter: Roller.bearingDiameter,
                        height: Roller.bearingThickness
                    )
                    Cylinder(
                        diameter: Roller.screwHeadDiameter,
                        height: Roller.screwHeadThickness
                    )
                }
                .translated(z: length / 2 + Roller.washerThickness)
                .symmetry(over: .z)
                .translated(z: length / 2)
                .background()
            }
            .subtracting {
                Cylinder(
                    diameter: Roller.screwPilotHoleDiameter,
                    height: Roller.screwPilotHoleDepth + Roller.washerThickness + 1
                )
                .translated(z: length / 2 - Roller.screwPilotHoleDepth)
                .symmetry(over: .z)
                .translated(z: length / 2)
            }
    }
}
