import Cadova
import Helical

/// The plate that closes the underside of the base, carrying the feet and the logo.
struct Bottom: Geometry3D {
    static let thickness = 3.0
    static let stepperSpaceThickness = 2.0

    static let mountBoltEquivalent = Bolt.phillipsCountersunk(.m3, length: 13)
    static let mountPilotHoleDiameter = 2.65
    static let mountPilotHoleDepth = 10.0

    static let mountStepperWallYOffset = 32.5
    static let mountSideAngularOffset = 9°
    static let mountSideInset = 5.8

    static let logoScale = 12.0
    static let logoDepth = 1.0

    static var footDiameter: Double {
        @Environment(\.tolerance) var tolerance
        return 30.0 + tolerance
    }

    /// Distance from the center out to the face of a stepper wall, where a foot is centered.
    private static let stepperWallX = Frame.outerPointDistance
        - Base.stepperWallInset
        - Base.stepperWallThickness

    var body: any Geometry3D {
        let countersink = Self.mountBoltEquivalent.clearanceHole(entry: .recessedHead)
            .flipped(along: .z)
            .translated(z: Self.thickness)

        Frame.shape
            .extruded(height: Self.thickness, topEdge: .chamfer(depth: Base.topChamferSize))
            .subtracting {
                // Recess for the steppers hanging below the base
                Rectangle(x: StepperMotor.size.z, y: StepperMotor.size.x)
                    .aligned(at: .centerY, .maxX)
                    .offset(amount: 1, style: .miter)
                    .translated(x: Self.stepperWallX)
                    .repeated(count: 3)
                    .extruded(height: Self.stepperSpaceThickness + 1)
                    .translated(z: -1)

                // Feet
                Circle(diameter: Self.footDiameter)
                    .translated(x: Self.stepperWallX - StepperMotor.size.z / 2)
                    .repeated(count: 3)
                    .extruded(height: Self.thickness + 2)
                    .translated(z: -1)

                // Mounts into the stepper walls
                countersink
                    .translated(
                        x: Frame.outerPointDistance - Base.stepperWallInset - Base.stepperWallThickness / 2,
                        y: Self.mountStepperWallYOffset
                    )
                    .symmetry(over: .y)
                    .repeated(around: .z, count: 3)

                // Mounts into the side walls
                countersink
                    .translated(x: Frame.width - Self.mountSideInset)
                    .rotated(z: 180° + Self.mountSideAngularOffset)
                    .translated(x: Frame.edgePivotDistance)
                    .symmetry(over: .y)
                    .repeated(around: .z, count: 3)

                Logo()
                    .rotated(90°)
                    .scaled(Self.logoScale)
                    .extruded(height: Self.logoDepth + 1)
                    .translated(z: Self.thickness - Self.logoDepth)
            }
    }
}
