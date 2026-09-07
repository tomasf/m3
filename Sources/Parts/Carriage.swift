import Foundation
import Cadova
import Helical

let carriageBaseThickness = 3.0 // Behind belts
let carriageBeltWidth = 7.0
let carriageBeltThickness = 1.38
let carriageBeltBackThickness = 0.63

let carriageSize = Vector3D(
    x: railCarriage.size.y + 6,
    y: railCarriage.size.x + 5,
    z: carriageBaseThickness + carriageBeltWidth
)
let carriageBolt = Bolt.hexSocketCountersunk(.m3, length: 8)
let carriageMinY = -carriageSize.y / 2
let carriageMaxY = carriageSize.y / 2

let carriageCoverBolt = Bolt.hexSocketCountersunk(.m5, length: 8)
let carriageCoverBoltOffset = (carriageSize.y - 9.43 / 2) / 3

let carriageArmHoleDiameter = 3.2
let carriageArmNut = Nut.square(.m3, series: .thin)
let carriageArmMountBaseDiameter = 5.4
let carriageArmOffset = 6.0
let carriageArmMountDepthOffset = 15.0

let armMountWidth = 7.0
let carriageBeltSpaceWidth = carriageBeltThickness * 3
let carriageBeltSpaceOuterWidth = 13.3

let railCarriageCoverThickness = 9.0

let carriageBody = Box(carriageSize + .z(railCarriageCoverThickness))
    .cuttingEdgeProfile(.fillet(radius: 3), on: .bottom, along: .z)
    .translated(z: -railCarriageCoverThickness)
    .aligned(at: .centerXY)
    .adding {
        Box([rodSpacing - armMountWidth, carriageArmOffset + carriageArmMountBaseDiameter / 2, carriageSize.z])
            .aligned(at: .maxY, .centerX)
            .translated(y: carriageMaxY)
    }
    .convexHull()
    .adding {
        // Arm mount
        Box([
            rodSpacing - armMountWidth,
            carriageArmOffset + carriageArmMountBaseDiameter / 2,
            carriageSize.z + carriageArmMountDepthOffset
        ])
        .cuttingEdgeProfile(.fillet(radius: 2), on: .bottom, along: .x)
        .aligned(at: .maxY, .centerX)
        .translated(y: carriageMaxY, z: -carriageArmMountDepthOffset)
    }
    .subtracting {
        // Rail carriage
        Box([railCarriage.size.y + tolerance, railCarriage.size.x + 2, carriageArmMountDepthOffset + 1])
            .aligned(at: .centerXY, .top)
            .cloned {
                $0.translated(y: 10, z: -railCarriage.size.z + 0.2)
                $0.translated(y: -10, z: -railCarriage.size.z + 0.2)
            }

        Box([railCarriage.size.y + tolerance + 1.0, railCarriage.size.x + 2, carriageArmMountDepthOffset + 1])
            .aligned(at: .maxZ, .maxY, .centerX)
            .translated(y: carriageSize.y / 2 + 1, z: -railCarriageCoverThickness)
            //.highlighted()

        // Rail
        Box([rail.size.x + tolerance * 2, carriageSize.y + 2, rail.size.y + 10])
            .aligned(at: .centerXY)
            .translated(z: -railCarriage.size.z - railCarriage.offsetFromRail + 0.2 - 10)

        // Back chamfer
        Box([20, carriageSize.y + 2, 20])
            .aligned(at: .centerY)
            .rotated(y: 45°)
            .translated(x: carriageSize.x / 2, z: carriageSize.z)
            .symmetry(over: .x)

        // Arm mount
        Circle(diameter: carriageArmHoleDiameter)
            .overhangSafe(.bridge)
            .rotated(-90°)
            .extruded(height: rodSpacing)
            .aligned(at: .centerZ)
            .adding {
                carriageArmNut.nutTrap(depthClearance: 0.8 + 0.6)
                    .translated(z: railCarriage.size.y / 2)
                    .symmetry(over: .z)

                carriageArmNut.nutTrap()
                    .translated(z: railCarriage.size.y / 2 + 0.8 + 0.6)
                    .symmetry(over: .z)
                    .colored(.gray, alpha: 0.6)
                    .inBackground()
            }
            .rotated(y: 90°)
            .translated(
                y: carriageMaxY - carriageArmOffset,
                z: -carriageArmMountDepthOffset + carriageArmMountBaseDiameter / 2
            )

        // Mount holes
        carriageBolt.clearanceHole(entry: .recessedHead)
            .flipped(along: .z)
            .translated(z: carriageBaseThickness - 0.6)
            .translated(x: railCarriage.holeDistance.y / 2, y: railCarriage.holeDistance.x / 2)
            .symmetry(over: .xy)
            .withTolerance(tolerance + 0.1)

        // Belt space
        Box([carriageBeltSpaceWidth, carriageSize.y + 2, carriageSize.z])
            .translated(
                x: carriageBeltSpaceOuterWidth / 2 - carriageBeltSpaceWidth / 2 - carriageBeltThickness / 2,
                y: carriageMinY - 1,
                z: carriageBaseThickness - 0.2
            )

        // Belt holder
        Box([carriageBeltBackThickness + tolerance, carriageSize.y + 2, carriageSize.z])
            .translated(
                x: -carriageBeltSpaceOuterWidth / 2 - tolerance / 2,
                y: carriageMinY - 1,
                z: carriageBaseThickness
            )

        Box([carriageBeltThickness + tolerance, 1.0 + tolerance, carriageSize.z])
            .translated(
                x: -carriageBeltSpaceOuterWidth / 2 - tolerance / 2,
                z: carriageBaseThickness
            )
            .repeated(along: .y, in: carriageMinY..<carriageMaxY, step: 2.0)

        // Cover mount
        ThreadedHole(thread: carriageCoverBolt.thread, depth: carriageSize.z, leadIns: .trailing)
            .distributed(at: [carriageMinY + carriageCoverBoltOffset, carriageMaxY - carriageCoverBoltOffset], along: .y)
            .hidden()
    }
    .withTolerance(tolerance)

let carriageCoverThickness = 2.6
let carriageCover = Rectangle(carriageSize.xy + [0, carriageCoverThickness])
    .cuttingEdgeProfile(.fillet(radius: 3), on: .bottom)
    .aligned(at: .center)
    .translated(y: carriageCoverThickness / 2)
    .extruded(height: carriageCoverThickness, topEdge: .chamfer(depth: carriageCoverThickness))
    .intersecting {
        Box(carriageSize).aligned(at: .centerXY)
    }
    .subtracting {
        carriageCoverBolt.clearanceHole(entry: .recessedHead)
            .flipped(along: .z)
            .translated(z: carriageCoverThickness - 0.6)
            .translated(y: carriageSize.y / 2 - carriageCoverBoltOffset)
            .symmetry(over: .y)
    }
    .withTolerance(tolerance)
