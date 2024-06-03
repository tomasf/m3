import Foundation
import SwiftSCAD

struct LinearRail: Shape3D {
    let size = Vector3D(9, 6.54, 300)
    let holeDiameter = 3.5
    let holeDistance = 20.0
    let holeHeadDiameter = 5.8
    let holeHeadDepth = 4.0

    var body: Geometry3D {
        Box(size)
            .aligned(at: .centerX)
            .subtracting {
                Cylinder(diameter: holeDiameter, height: size.y + 2)
                    .adding {
                        Cylinder(diameter: holeHeadDiameter, height: 1 + holeHeadDepth)
                    }
                    .translated(z: -1)
                    .rotated(x: -90°)
                    .repeated(along: .z, in: 0..<size.z, step: holeDistance)
                    .translated(z: holeDistance / 2)
            }
    }
}

struct LinearRailCarriage: Shape3D {
    let size = Vector3D(40, 20, 8)
    let holeDepth = 4.0
    let holeDistance = Vector2D(16, 15)
    let offsetFromRail = 2.0

    var body: Geometry3D {
        Box(size)
            .aligned(at: .centerXY)
            .subtracting {
                Cylinder(diameter: 3, height: holeDepth + 1)
                    .translated(z: size.z - holeDepth)
                    .translated(.init(holeDistance / 2))
                    .symmetry(over: .xy)
            }
    }
}

struct StepperMotor: Shape3D {
    let size = Vector3D(42, 42, 30.0)
    let circleDiameter = 22.0
    let circleThickness = 2.0
    let holeDistance = 31.0
    let holeDiameter = 3.0
    let holeDepth = 3.0
    let shaftDiameter = 5.0
    let shaftLength = 20.0
    let shaftFlatDepth = 0.5
    let shaftFlatLength = 17.0

    var body: Geometry3D {
        Box(size)
            .aligned(at: .centerXY)
            .adding {
                Cylinder(diameter: circleDiameter, height: size.z + circleThickness)
                Cylinder(diameter: shaftDiameter, height: size.z + shaftLength)
            }
            .subtracting {
                Cylinder(diameter: holeDiameter, height: holeDepth + 1)
                    .translated(z: size.z - holeDepth)
                    .translated(x: holeDistance / 2, y: holeDistance / 2)
                    .symmetry(over: .xy)

                Box([shaftFlatDepth + 1, shaftDiameter, shaftFlatLength + 1])
                    .aligned(at: .centerY)
                    .translated(x: shaftDiameter / 2 - shaftFlatDepth)
                    .translated(z: size.z + shaftLength - shaftFlatLength)
            }
    }
}

struct Pulley: Shape3D {
    let length = 14.5
    let wideDiameter = 16.0
    let solidLength = 6.3
    let flangeThickness = 1.0
    let feedDiameter = 12.2

    var body: Geometry3D {
        Cylinder(diameter: feedDiameter, height: length)
        Cylinder(diameter: wideDiameter, height: solidLength)
        Cylinder(diameter: wideDiameter, height: flangeThickness)
            .translated(z: length - flangeThickness)
    }
}

struct Idler: Shape3D {
    let outerDiameter = 18.0
    let feedDiameter = 12.0
    let width = 8.6
    let flangeThickness = 1.0
    let centerDiameter = 3.0

    var body: Geometry3D {
        Stack(.z, alignment: .centerXY) {
            Cylinder(diameter: outerDiameter, height: flangeThickness)
            Cylinder(diameter: feedDiameter, height: width - 2 * flangeThickness)
            Cylinder(diameter: outerDiameter, height: flangeThickness)
        }
        .subtracting {
            Cylinder(diameter: centerDiameter, height: width + 2)
                .translated(z: -1)
        }
    }
}

struct Duet: Shape3D {
    static let size = Vector3D(123, 100, 1.5)
    static let holeDiameter = 4.2
    static let holeInset = 4.0

    static let screwLength = 8.0
    static let screwPilotHoleDiameter = 3.4
    static let screwPostDiameter = 8.0

    var body: Geometry3D {
        Rectangle(Duet.size.xy)
            .aligned(at: .center)
            .subtracting {
                Circle(diameter: Duet.holeDiameter)
                    .translated(Duet.size.xy / 2 - Duet.holeInset)
                    .symmetry(over: .xy)
            }
            .extruded(height: Duet.size.z)
    }
}

struct EndstopBoard: Shape3D {
    let size = Vector3D(27.25, 12.25, 1.6)
    let holeInset = 3.0
    let holeDiameter = 3.0
    let endstopSize = Vector3D(13, 6.2, 6.5)

    var body: Geometry3D {
        Rectangle(size.xy)
            .roundingRectangleCorners(.top, radius: holeInset)
            .aligned(at: .centerX)
            .subtracting {
                Circle(diameter: holeDiameter)
                    .translated(x: size.x / 2 - holeInset, y: size.y - holeInset)
                    .symmetry(over: .x)
            }
            .extruded(height: size.z)
        Box(endstopSize)
            .aligned(at: .centerX, .maxY)
            .translated(y: size.y, z: size.z)
    }
}
