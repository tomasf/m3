import Cadova
import Helical

/// The printed carriage that bolts to the linear rail block, clamps the belt, and carries the
/// pair of arm rods out to the effector.
struct Carriage: Geometry3D {
    /// Material behind the belt, between the rail block and the belt channel.
    static let baseThickness = 3.0
    static let beltWidth = 7.0
    static let beltThickness = 1.38
    static let beltBackThickness = 0.63

    static let size = Vector3D(
        x: LinearRailCarriage.size.y + 6,
        y: LinearRailCarriage.size.x + 5,
        z: baseThickness + beltWidth
    )
    static let minY = -size.y / 2
    static let maxY = size.y / 2

    static let bolt = Bolt.hexSocketCountersunk(.m3, length: 8)
    static let railBlockCoverThickness = 9.0

    // MARK: - Arm mount

    static let armHoleDiameter = 3.2
    static let armNut = Nut.square(.m3, series: .thin)
    static let armMountBaseDiameter = 5.4
    static let armMountWidth = 7.0
    static let armOffset = 6.0
    static let armMountDepthOffset = 15.0

    // MARK: - Belt clamp

    static let beltSpaceWidth = beltThickness * 3
    static let beltSpaceOuterWidth = 13.3
    /// Pitch of the teeth that grip the belt's back face.
    static let beltToothSpacing = 2.0

    var body: any Geometry3D {
        @Environment(\.tolerance) var tolerance

        Box(Self.size + .z(Self.railBlockCoverThickness))
            .cuttingEdgeProfile(.fillet(radius: 3), on: .bottom, along: .z)
            .translated(z: -Self.railBlockCoverThickness)
            .aligned(at: .centerXY)
            .adding {
                Box([
                    Motion.rodSpacing - Self.armMountWidth,
                    Self.armOffset + Self.armMountBaseDiameter / 2,
                    Self.size.z
                ])
                .aligned(at: .maxY, .centerX)
                .translated(y: Self.maxY)
            }
            .convexHull()
            .adding {
                // Arm mount ears
                Box([
                    Motion.rodSpacing - Self.armMountWidth,
                    Self.armOffset + Self.armMountBaseDiameter / 2,
                    Self.size.z + Self.armMountDepthOffset
                ])
                .cuttingEdgeProfile(.fillet(radius: 2), on: .bottom, along: .x)
                .aligned(at: .maxY, .centerX)
                .translated(y: Self.maxY, z: -Self.armMountDepthOffset)
            }
            .subtracting {
                // Pocket for the rail block
                Box([
                    LinearRailCarriage.size.y + tolerance,
                    LinearRailCarriage.size.x + 2,
                    Self.armMountDepthOffset + 1
                ])
                .aligned(at: .centerXY, .top)
                .cloned {
                    $0.translated(y: 10, z: -LinearRailCarriage.size.z + 0.2)
                    $0.translated(y: -10, z: -LinearRailCarriage.size.z + 0.2)
                }

                Box([
                    LinearRailCarriage.size.y + tolerance + 1.0,
                    LinearRailCarriage.size.x + 2,
                    Self.armMountDepthOffset + 1
                ])
                .aligned(at: .maxZ, .maxY, .centerX)
                .translated(y: Self.size.y / 2 + 1, z: -Self.railBlockCoverThickness)

                // Clearance for the rail itself
                Box([
                    LinearRail.size.x + tolerance * 2,
                    Self.size.y + 2,
                    LinearRail.size.y + 10
                ])
                .aligned(at: .centerXY)
                .translated(z: -LinearRailCarriage.size.z - LinearRailCarriage.offsetFromRail + 0.2 - 10)

                // Back chamfer
                Box([20, Self.size.y + 2, 20])
                    .aligned(at: .centerY)
                    .rotated(y: 45°)
                    .translated(x: Self.size.x / 2, z: Self.size.z)
                    .symmetry(over: .x)

                // Arm rod bolt, with a captive nut at each end
                Circle(diameter: Self.armHoleDiameter)
                    .overhangSafe(.bridge)
                    .rotated(-90°)
                    .extruded(height: Motion.rodSpacing)
                    .aligned(at: .centerZ)
                    .adding {
                        Self.armNut.nutTrap(depthClearance: 0.8 + 0.6)
                            .translated(z: LinearRailCarriage.size.y / 2)
                            .symmetry(over: .z)

                        Self.armNut.nutTrap()
                            .translated(z: LinearRailCarriage.size.y / 2 + 0.8 + 0.6)
                            .symmetry(over: .z)
                            .colored(.gray, alpha: 0.6)
                            .inBackground()
                    }
                    .rotated(y: 90°)
                    .translated(
                        y: Self.maxY - Self.armOffset,
                        z: -Self.armMountDepthOffset + Self.armMountBaseDiameter / 2
                    )

                // Bolts into the rail block
                Self.bolt.clearanceHole(entry: .recessedHead)
                    .flipped(along: .z)
                    .translated(z: Self.baseThickness - 0.6)
                    .translated(
                        x: LinearRailCarriage.holeDistance.y / 2,
                        y: LinearRailCarriage.holeDistance.x / 2
                    )
                    .symmetry(over: .xy)
                    .withTolerance(tolerance + 0.1)

                // Belt channel
                Box([Self.beltSpaceWidth, Self.size.y + 2, Self.size.z])
                    .translated(
                        x: Self.beltSpaceOuterWidth / 2 - Self.beltSpaceWidth / 2 - Self.beltThickness / 2,
                        y: Self.minY - 1,
                        z: Self.baseThickness - 0.2
                    )

                // Belt clamp: a back-face slot with teeth that mesh with the belt
                Box([Self.beltBackThickness + tolerance, Self.size.y + 2, Self.size.z])
                    .translated(
                        x: -Self.beltSpaceOuterWidth / 2 - tolerance / 2,
                        y: Self.minY - 1,
                        z: Self.baseThickness
                    )

                Box([Self.beltThickness + tolerance, 1.0 + tolerance, Self.size.z])
                    .translated(
                        x: -Self.beltSpaceOuterWidth / 2 - tolerance / 2,
                        z: Self.baseThickness
                    )
                    .repeated(along: .y, in: Self.minY..<Self.maxY, step: Self.beltToothSpacing)

                // Cover mount
                ThreadedHole(thread: CarriageCover.bolt.thread, depth: Self.size.z, leadIns: .trailing)
                    .distributed(
                        at: [Self.minY + CarriageCover.boltOffset, Self.maxY - CarriageCover.boltOffset],
                        along: .y
                    )
                    .hidden()
            }
    }
}

/// The plate that closes the carriage's belt channel and traps the belt against the teeth.
struct CarriageCover: Geometry3D {
    static let thickness = 2.6
    static let bolt = Bolt.hexSocketCountersunk(.m5, length: 8)
    static let boltOffset = (Carriage.size.y - 9.43 / 2) / 3

    var body: any Geometry3D {
        Rectangle(Carriage.size.xy + [0, Self.thickness])
            .cuttingEdgeProfile(.fillet(radius: 3), on: .bottom)
            .aligned(at: .center)
            .translated(y: Self.thickness / 2)
            .extruded(height: Self.thickness, topEdge: .chamfer(depth: Self.thickness))
            .intersecting {
                Box(Carriage.size).aligned(at: .centerXY)
            }
            .subtracting {
                Self.bolt.clearanceHole(entry: .recessedHead)
                    .flipped(along: .z)
                    .translated(z: Self.thickness - 0.6)
                    .translated(y: Carriage.size.y / 2 - Self.boltOffset)
                    .symmetry(over: .y)
            }
    }
}
