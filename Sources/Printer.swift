import Cadova

/// The whole machine, assembled. Printed parts are shown as they are modeled; the hardware they
/// bolt to is drawn in the background so the fits can be checked visually.
struct Printer: Geometry3D {
    static let armDiameter = 6.0
    static let beltWidth = 6.0
    static let beltLength = 300.0

    /// Where the carriage sits on its rail in this view.
    static let carriageZ = 145.0

    /// The base with one tower's rail, carriage and belts standing on each corner.
    static var baseWithSides: any Geometry3D {
        Base()
            .adding {
                LinearRail()
                    .colored(.gray)
                    .adding {
                        LinearRailCarriage()
                            .colored(.red)
                            .adding {
                                Carriage()
                                    .colored(.orange)
                                    .rotated(z: -90°)
                                    .translated(z: LinearRailCarriage.size.z)
                            }
                            .translated(z: LinearRailCarriage.offsetFromRail)
                            .rotated(y: -90°, z: 90°)
                            .translated(y: LinearRail.size.y, z: carriageZ)
                    }
                    .rotated(z: 90°)
                    .translated(
                        x: Frame.outerPointDistance - Motion.railInset,
                        z: Motion.railOffsetFromBottom
                    )
                    .adding {
                        Box([beltWidth, Carriage.beltThickness, beltLength])
                            .aligned(at: .centerX)
                            .translated(y: Motion.beltInnerYOffset)
                            .symmetry(over: .y)
                            .translated(x: Motion.beltCenterX, z: Base.stepperZCenter)
                            .colored(.black)
                    }
                    .repeated(around: .z, count: 3)
                    .inBackground()
            }
    }

    /// What lives inside the base: the control board and the three steppers, seen from below.
    static var baseContents: any Geometry3D {
        Duet()
            .translated(x: -26)
            .adding {
                StepperMotor()
                    .colored(.darkGray, alpha: 0.3)
                    .adding {
                        Pulley()
                            .translated(z: StepperMotor.size.z + StepperMotor.shaftLength - Pulley.length)
                    }
                    .rotated(y: 90°)
                    .aligned(at: .bottom)
                    .translated(x: -StepperMotor.size.z)
                    .translated(x: Base.stepperWallX)
                    .translated(z: Base.stepperZFromTop)
                    .repeated(around: .z, count: 3)
                    .inBackground()
            }
    }

    var body: any Geometry3D {
        Self.baseWithSides
            .adding {
                CornerCover(height: CornerCover.standardHeight)
                    .repeated(around: .z, count: 3)
                    .translated(z: Base.height)

                RailCover(length: RailCover.standardLength)
                    .rotated(z: -90°)
                    .translated(
                        x: Frame.outerPointDistance - Motion.railInset - LinearRail.size.y
                            - RailCover.centerThickness,
                        z: Base.height
                    )
            }
            // Flip over to drop the contents in from below, then back upright
            .rotated(x: 180°)
            .translated(z: Base.height - Base.topThickness)
            .adding {
                Self.baseContents
            }
            .translated(z: -Base.height + Base.topThickness)
            .rotated(x: 180°)
            .adding {
                Top()
                    .translated(z: Motion.railOffsetFromBottom + LinearRail.size.z - Top.height)

                Cylinder(diameter: Bed.diameter, height: 1)
                    .translated(z: Base.height)

                Self.effectorAtBedEdge
            }
    }

    /// The effector parked at the edge of the usable bed, with its arms at the extremes of their
    /// travel: the pair that is nearly horizontal, and the pair that is steepest.
    private static var effectorAtBedEdge: any Geometry3D {
        Effector()
            .rotated(z: 60°)
            .adding {
                Cylinder(diameter: armDiameter, height: Kinematics.minArmLength)
                    .rotated(y: 90° - 20°)
                    .translated(x: Effector.armOffset, y: Motion.rodSpacing / 2)
                    .symmetry(over: .y)
                    .rotated(z: 180°)

                Cylinder(diameter: armDiameter, height: Kinematics.minArmLength)
                    .rotated(y: 90° - 62°)
                    .rotated(z: -57°)
                    .translated(x: Effector.armOffset)
                    .distributed(at: [Motion.rodSpacing / 2, -Motion.rodSpacing / 2], along: .y)
                    .rotated(z: 180° + 120°)
            }
            .colored(.lightBlue)
            .translated(x: Kinematics.usableBedRadius, z: Base.height + 3 + 20)
            .rotated(z: 180°)
    }
}
