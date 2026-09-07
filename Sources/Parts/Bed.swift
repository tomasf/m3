import Cadova

/// The inductive probe that senses the bed at each tower.
enum BedSensor {
    static let diameter = 20.0
    static let thickness = 0.4
    static let maxThickness = 1.0
    static let centerClearDiameter = 5.0
}

/// The board the bed probes report to.
enum BedSensorBoard {
    static let size = Vector3D(33, 15.3, 1.5)
    static let lengthIncludingWires = 55.0
    static let fullHeight = 8.0
    static let mountBarSize = Vector3D(15.5, 5.0, 5.0)
    static let mountBarHoleDiameter = 2.8
    static let mountBarHoleDistance = 9.0
}

/// The print bed, and the three-point probe mounting it needs from the base.
///
/// The bed rests on a sprung flap at each tower. The flap is cut free from the base's top surface
/// so it can deflect onto the probe underneath; `mounts`, `flapCutouts` and `probeClearances` are
/// the three passes the base applies, in that order, to produce it.
enum Bed {
    static let diameter = 160.0

    static let sensorFlapWidth = 16.0
    static let sensorFlapLength = 20.0
    static let sensorFlapClearance = 0.6
    static let sensorFlapThickness = 1.2

    static let sensorHolderWallThickness = 3.0
    static let sensorHolderWallHeight = 1.6
    static let sensorHolderHoleOffset = 15.0
    static let sensorHolderHoleAreaDiameter = 6.0
    static let sensorHolderHolePilotDiameter = 2.1
    static let sensorHolderCoverThickness = 1.4

    static var sensorHolderHoleFullDiameter: Double {
        @Environment(\.tolerance) var tolerance
        return 2.2 + tolerance
    }

    /// Radius at which the three probes sit.
    static let sensorAreaRadius = diameter / 2 - 5
    /// Center of one probe, on the +X axis.
    static let sensorCenterX = sensorAreaRadius - sensorFlapWidth / 2

    /// Outline of the probe holder: a disc for the sensor with an ear at each side for its screws.
    static var sensorHolderOutline: any Geometry2D {
        @Environment(\.tolerance) var tolerance

        return Circle(diameter: BedSensor.diameter + sensorHolderWallThickness * 2 + tolerance)
            .adding {
                Circle(diameter: sensorHolderHoleAreaDiameter)
                    .translated(y: sensorHolderHoleOffset)
                    .symmetry(over: .y)
            }
            .convexHull()
    }

    /// The printed lid that clamps a probe into its holder.
    static var sensorCover: any Geometry3D {
        @Environment(\.tolerance) var tolerance

        return sensorHolderOutline
            .subtracting {
                Circle(diameter: sensorHolderHoleFullDiameter)
                    .translated(y: sensorHolderHoleOffset)
                    .symmetry(over: .y)
            }
            .extruded(height: sensorHolderCoverThickness)
            .adding {
                Cylinder(
                    diameter: BedSensor.diameter - tolerance,
                    height: sensorHolderWallHeight - BedSensor.thickness
                )
                .translated(z: sensorHolderCoverThickness)
            }
    }

    /// Walls that locate each probe, added under the base's top surface.
    static var mounts: any Geometry3D {
        @Environment(\.tolerance) var tolerance

        return sensorHolderOutline
            .subtracting {
                Circle(diameter: BedSensor.diameter + tolerance)
            }
            .extruded(height: sensorHolderWallHeight)
            .translated(x: sensorCenterX, z: Base.height - Base.topThickness - sensorHolderWallHeight)
            .repeated(around: .z, count: 3)
    }

    /// The slot that frees each sprung flap from the surrounding top surface, plus the thinning
    /// of the flap itself and the pilot holes for the cover screws.
    static var flapCutouts: any Geometry3D {
        let flapShape = Circle(diameter: sensorFlapWidth)
            .adding {
                Rectangle([sensorFlapLength - sensorFlapWidth / 2, sensorFlapWidth])
                    .aligned(at: .maxX, .centerY)
            }
            .aligned(at: .maxX)
        let clearedShape = flapShape.offset(amount: sensorFlapClearance, style: .round)

        return clearedShape
            .subtracting(flapShape)
            .subtracting {
                // Leave the flap attached along its inner end, so it acts as a hinge
                Rectangle([sensorFlapClearance + 2, sensorFlapWidth])
                    .aligned(at: .centerY)
                    .translated(x: -sensorFlapLength - sensorFlapClearance - 1)
            }
            .extruded(height: Base.topThickness + sensorHolderWallHeight + 2)
            .translated(z: Base.height - Base.topThickness - sensorHolderWallHeight - 1)
            .adding {
                // Thin the flap down to its spring thickness
                clearedShape
                    .extruded(height: Base.topThickness + sensorHolderWallHeight)
                    .translated(
                        z: Base.height - sensorFlapThickness - Base.topThickness - sensorHolderWallHeight
                    )

                Cylinder(
                    diameter: sensorHolderHolePilotDiameter,
                    height: Base.topThickness + sensorHolderWallHeight + 1 - 0.4
                )
                .translated(x: -sensorFlapWidth / 2)
                .translated(y: sensorHolderHoleOffset)
                .symmetry(over: .y)
                .translated(z: Base.height - Base.topThickness - sensorHolderWallHeight - 1)
            }
            .translated(x: sensorAreaRadius)
            .repeated(around: .z, count: 3)
    }

    /// Bosses that restore the material the flap slot removed directly over each probe, giving
    /// the sensor a solid, constant-thickness target to read.
    static var probeClearances: any Geometry3D {
        Cylinder(diameter: BedSensor.centerClearDiameter, height: Base.topThickness)
            .translated(x: sensorCenterX, z: Base.height - Base.topThickness)
            .repeated(around: .z, count: 3)
    }
}
