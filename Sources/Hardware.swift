import Cadova

// Reference models for the off-the-shelf hardware the printer is built around. They are never
// printed; they exist so parts can be dimensioned against them and so assemblies can show what
// the machine actually looks like. Dimensions are static so callers can measure a part without
// instantiating it.

/// A MGN9-style linear rail, one per tower.
struct LinearRail: Geometry3D {
    static let size = Vector3D(9, 6.54, 300)
    static let holeDiameter = 3.5
    static let holeDistance = 20.0
    static let holeHeadDiameter = 5.8
    static let holeHeadDepth = 4.0

    var body: any Geometry3D {
        Box(Self.size)
            .aligned(at: .centerX)
            .subtracting {
                Cylinder(diameter: Self.holeDiameter, height: Self.size.y + 2)
                    .adding {
                        Cylinder(diameter: Self.holeHeadDiameter, height: 1 + Self.holeHeadDepth)
                    }
                    .translated(z: -1)
                    .rotated(x: -90°)
                    .repeated(along: .z, in: 0..<Self.size.z, step: Self.holeDistance)
                    .translated(z: Self.holeDistance / 2)
            }
    }
}

/// The block that rides the linear rail and carries the printed carriage.
struct LinearRailCarriage: Geometry3D {
    static let size = Vector3D(40, 20, 8)
    static let holeDepth = 4.0
    static let holeDistance = Vector2D(16, 15)
    static let offsetFromRail = 2.0
    static let holeDiameter = 3.0

    var body: any Geometry3D {
        Box(Self.size)
            .aligned(at: .centerXY)
            .subtracting {
                Cylinder(diameter: Self.holeDiameter, height: Self.holeDepth + 1)
                    .translated(z: Self.size.z - Self.holeDepth)
                    .translated(.init(Self.holeDistance / 2))
                    .symmetry(over: .xy)
            }
    }
}

/// A NEMA 17 stepper, one per tower.
struct StepperMotor: Geometry3D {
    static let size = Vector3D(42, 42, 30.0)
    static let circleDiameter = 22.0
    static let circleThickness = 2.0
    static let holeDistance = 31.0
    static let holeDiameter = 3.0
    static let holeDepth = 3.0
    static let shaftDiameter = 5.0
    static let shaftLength = 20.0
    static let shaftFlatDepth = 0.5
    static let shaftFlatLength = 17.0

    var body: any Geometry3D {
        Box(Self.size)
            .aligned(at: .centerXY)
            .adding {
                Cylinder(diameter: Self.circleDiameter, height: Self.size.z + Self.circleThickness)
                Cylinder(diameter: Self.shaftDiameter, height: Self.size.z + Self.shaftLength)
            }
            .subtracting {
                Cylinder(diameter: Self.holeDiameter, height: Self.holeDepth + 1)
                    .translated(z: Self.size.z - Self.holeDepth)
                    .translated(x: Self.holeDistance / 2, y: Self.holeDistance / 2)
                    .symmetry(over: .xy)

                Box([Self.shaftFlatDepth + 1, Self.shaftDiameter, Self.shaftFlatLength + 1])
                    .aligned(at: .centerY)
                    .translated(x: Self.shaftDiameter / 2 - Self.shaftFlatDepth)
                    .translated(z: Self.size.z + Self.shaftLength - Self.shaftFlatLength)
            }
    }
}

/// The GT2 pulley pressed onto each stepper shaft.
struct Pulley: Geometry3D {
    static let length = 14.5
    static let wideDiameter = 16.0
    static let solidLength = 6.3
    static let flangeThickness = 1.0
    static let feedDiameter = 12.2

    var body: any Geometry3D {
        Cylinder(diameter: Self.feedDiameter, height: Self.length)
        Cylinder(diameter: Self.wideDiameter, height: Self.solidLength)
        Cylinder(diameter: Self.wideDiameter, height: Self.flangeThickness)
            .translated(z: Self.length - Self.flangeThickness)
    }
}

/// The toothless idler at the top of each tower that returns the belt.
struct Idler: Geometry3D {
    static let outerDiameter = 15.0
    static let feedDiameter = 12.0
    static let width = 10.0
    static let flangeThickness = 1.5
    static let centerDiameter = 5.0

    var body: any Geometry3D {
        Stack(.z, alignment: .centerXY) {
            Cylinder(diameter: Self.outerDiameter, height: Self.flangeThickness)
            Cylinder(diameter: Self.feedDiameter, height: Self.width - 2 * Self.flangeThickness)
            Cylinder(diameter: Self.outerDiameter, height: Self.flangeThickness)
        }
        .subtracting {
            Cylinder(diameter: Self.centerDiameter, height: Self.width + 2)
                .translated(z: -1)
        }
    }
}

/// The Duet control board mounted to the underside of the base.
struct Duet: Geometry3D {
    static let size = Vector3D(123, 100, 1.5)
    static let holeDiameter = 4.2
    static let holeInset = 4.0

    static let screwLength = 8.0
    static let screwPilotHoleDiameter = 3.4
    static let screwPostDiameter = 8.0

    var body: any Geometry3D {
        Rectangle(Self.size.xy)
            .aligned(at: .center)
            .subtracting {
                Circle(diameter: Self.holeDiameter)
                    .translated(Self.size.xy / 2 - Self.holeInset)
                    .symmetry(over: .xy)
            }
            .extruded(height: Self.size.z)
    }
}

/// The board carrying each tower's homing endstop, mounted in the top.
struct EndstopBoard: Geometry3D {
    static let size = Vector3D(27.25, 12.25, 1.6)
    static let holeInset = 3.0
    static let holeDiameter = 3.0
    static let endstopSize = Vector3D(13, 6.2, 6.5)

    var body: any Geometry3D {
        Rectangle(Self.size.xy)
            .cuttingEdgeProfile(.fillet(radius: Self.holeInset), on: .top)
            .aligned(at: .centerX)
            .subtracting {
                Circle(diameter: Self.holeDiameter)
                    .translated(x: Self.size.x / 2 - Self.holeInset, y: Self.size.y - Self.holeInset)
                    .symmetry(over: .x)
            }
            .extruded(height: Self.size.z)

        Box(Self.endstopSize)
            .aligned(at: .centerX, .maxY)
            .translated(y: Self.size.y, z: Self.size.z)
    }
}

/// The indicator LED board recessed into the front edge of the base.
enum LEDBoard {
    static let size = Vector3D(19.05, 15.05, 1.5)
    static let holePilotDiameter = 2.0
    static let holeInset = 2.5
    static let ledSpaceSize = 6.0
    static let ledXCenter = 9.0
    static let ledThickness = 1.6
    static let connectorInset = 4.0
    static let connectorThickness = 5.5
}
