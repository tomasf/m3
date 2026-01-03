import Foundation
import Cadova
import Helical

struct BedSensor {
    static let diameter = 20.0
    static let thickness = 0.4
    static let maxThickness = 1.0
    static let centerClearDiameter = 5.0
}

struct BedSensorBoard {
    static let size = Vector3D(33, 15.3, 1.5)
    static let lengthIncludingWires = 55.0
    static let fullHeight = 8.0
    static let mountBarSize = Vector3D(15.5, 5.0, 5.0)
    static let mountBarHoleDiameter = 2.8
    static let mountBarHoleDistance = 9.0
}

struct Bed: Part3D {
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
    static let sensorHolderHoleFullDiameter = 2.2 + tolerance
    static let sensorHolderCoverThickness = 1.4

    static var sensorCover: any Geometry3D {
        Circle(diameter: BedSensor.diameter + Bed.sensorHolderWallThickness * 2 + tolerance)
            .adding {
                Circle(diameter: Bed.sensorHolderHoleAreaDiameter)
                    .translated(y: Bed.sensorHolderHoleOffset)
                    .symmetry(over: .y)
            }
            .convexHull()
            .subtracting {
                Circle(diameter: Bed.sensorHolderHoleFullDiameter)
                    .translated(y: Bed.sensorHolderHoleOffset)
                    .symmetry(over: .y)
            }
            .extruded(height: sensorHolderCoverThickness)
            .adding {
                Cylinder(diameter: BedSensor.diameter - tolerance, height: Bed.sensorHolderWallHeight - BedSensor.thickness)
                    .translated(z: sensorHolderCoverThickness)
            }
    }

    func body(_ parent: Geometry3D) -> any Geometry3D {
        let sensorAreaRadius = Bed.diameter / 2 - 5
        let centerX = sensorAreaRadius - Bed.sensorFlapWidth / 2

        parent.adding {
            Circle(diameter: BedSensor.diameter + Bed.sensorHolderWallThickness * 2 + tolerance)
                .adding {
                    Circle(diameter: Bed.sensorHolderHoleAreaDiameter)
                        .translated(y: Bed.sensorHolderHoleOffset)
                        .symmetry(over: .y)
                }
                .convexHull()
                .subtracting {
                    Circle(diameter: BedSensor.diameter + tolerance)
                }
                .extruded(height: Bed.sensorHolderWallHeight)
                .translated(x: centerX, z: baseHeight - baseTopThickness - Bed.sensorHolderWallHeight)
                .repeated(around: .z, count: 3)
        }
        .subtracting {
            let shape = Circle(diameter: Bed.sensorFlapWidth)
                .adding {
                    Rectangle([Bed.sensorFlapLength - Bed.sensorFlapWidth / 2, Bed.sensorFlapWidth])
                        .aligned(at: .maxX, .centerY)
                }
                .aligned(at: .maxX)
            let outerShape = shape.offset(amount: Bed.sensorFlapClearance, style: .round)

            outerShape
                .subtracting(shape)
                .subtracting {
                    Rectangle([Bed.sensorFlapClearance + 2, Bed.sensorFlapWidth])
                        .aligned(at: .centerY)
                        .translated(x: -Bed.sensorFlapLength - Bed.sensorFlapClearance - 1)
                }
                .extruded(height: baseTopThickness + Bed.sensorHolderWallHeight + 2)
                .translated(z: baseHeight - baseTopThickness -  Bed.sensorHolderWallHeight - 1)
                .adding {
                    outerShape
                        .extruded(height: baseTopThickness + Bed.sensorHolderWallHeight)
                        .translated(z: baseHeight - Bed.sensorFlapThickness - baseTopThickness - Bed.sensorHolderWallHeight)

                    Cylinder(diameter: Bed.sensorHolderHolePilotDiameter, height: baseTopThickness + Bed.sensorHolderWallHeight + 1 - 0.4)
                        .translated(x: -Bed.sensorFlapWidth / 2)
                        .translated(y: Bed.sensorHolderHoleOffset)
                        .symmetry(over: .y)
                        .translated(z: baseHeight - baseTopThickness - Bed.sensorHolderWallHeight - 1)
                }
                .translated(x: sensorAreaRadius)
                .repeated(around: .z, count: 3)
        }
        .adding {
            Cylinder(diameter: BedSensor.centerClearDiameter, height: baseTopThickness)
                .translated(x: centerX, z: baseHeight - baseTopThickness)
                .repeated(around: .z, count: 3)
        }
    }
}
