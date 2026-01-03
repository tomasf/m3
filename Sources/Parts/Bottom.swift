import Foundation
import Cadova
import Helical

struct Bottom: Shape3D {
    static let thickness = 3.0

    static let stepperSpaceThickness = 2.0
    static let footDiameter = 30.0 + tolerance

    static let mountBoltEquivalent = Bolt.phillipsCountersunk(.m3, length: 13)
    static let mountPilotHoleDiameter = 2.65
    static let mountPilotHoleDepth = 10.0

    static let mountStepperWallYOffset = 32.5
    static let mountSideAnglularOffset = 9°
    static let mountSideInset = 5.8

    var body: any Geometry3D {
        baseShape
            .extruded(height: Bottom.thickness, topEdge: .chamfer(depth: baseTopChamferSize))
            .subtracting {
                Rectangle(x: stepper.size.z, y: stepper.size.x)
                    .aligned(at: .centerY, .maxX)
                    .offset(amount: 1, style: .miter)
                    .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness)
                    .repeated(count: 3)
                    .extruded(height: Bottom.stepperSpaceThickness + 1)
                    .translated(z: -1)

                Circle(diameter: Bottom.footDiameter)
                    .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness - stepper.size.z / 2)
                    .repeated(count: 3)
                    .extruded(height: Bottom.thickness + 2)
                    .translated(z: -1)

                let countersink = Bottom.mountBoltEquivalent.clearanceHole(recessedHead: true)
                    .flipped(along: .z)
                    .translated(z: Bottom.thickness)

                countersink.translated(
                    x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness / 2,
                    y: Bottom.mountStepperWallYOffset
                )
                .symmetry(over: .y)
                .repeated(around: .z, count: 3)

                countersink
                    .translated(x: outerShapeWidth - Bottom.mountSideInset)
                    .rotated(z: 180° + Bottom.mountSideAnglularOffset)
                    .translated(x: distanceToEdgePivot)
                    .symmetry(over: .y)
                    .repeated(around: .z, count: 3)

                logo
                    .rotated(90°)
                    .scaled(12)
                    .extruded(height: 2)
                    .translated(z: Bottom.thickness - 1)
            }
            .withTolerance(0.3)

    }
}
