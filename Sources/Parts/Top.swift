import Foundation
import Cadova
import Helical

let topOuterWallThickness = 4.0
let topHeight = 20.0

let topCoverThickness = 2.0
let topFilletRadius = 2.0

//let topCornerAreaRadius = 40.0

let beltCenterInset = railInset + rail.size.y - railCarriage.offsetFromRail - railCarriage.size.z - carriageBaseThickness - carriageBeltWidth / 2

let topIdlerHoleDiameter = 5.5
let topIdlerCenterZ = topHeight / 2 - 2.2
let topIdlerHolderRingDiameter = topIdlerHoleDiameter + 2.0
let topIdlerHolderRingLength = 1.0

let topRailMountZ = topHeight / 2

let topIdlerSpaceLength = idler.width + 2 * topIdlerHolderRingLength + 0.5
let topIdlerSpaceWidth = idler.outerDiameter + 4.0

let topIdlerBoltLength = 16.0
let topIdlerBolt = Bolt.phillipsCountersunk(.m5, length: topIdlerBoltLength)

let topRailToNutTrapDistance = 1.0

let topHandleDiameter = 22.0
let topHandleXOffset = -20.0
let topLEDStripSize = Vector3D(152, 12.5, 4.6)
let topLEDStripExpansion = 1.0

let topCoverMountPositions: [Vector2D] = [[-7, 14], [-32, 27]]
let topCoverMountBoltEquivalent = Bolt.phillipsCountersunk(.m3, length: 9)
let topCoverMountPilotHoleDiameter = 2.65
let topCoverMountPilotHoleDepth = 9.0

let topCoverMountBottomThickness = 4.0

let topRollerLength = 75.0
let topRollerYOffset = 58.0
let topRollerXOffset = topRollerLength / 2 - 9.0

let holderWallThickness = 2.0

struct Top: Shape3D {
    static let rollerHolderAxisZ = topHeight - rollerBearingDiameter / 2

    let topFarSideRollerHolderCornerRadius = 4.0
    let topFarSideRollerHolderSize = Vector3D(
        x: Roller.bearingThickness + Roller.screwHeadThickness + Roller.washerThickness + holderWallThickness + 30,
        y: Roller.bearingDiameter + 2 * holderWallThickness + 17.5,
        z: Roller.bearingDiameter + holderWallThickness + 3
    )
    let topFarSideRollerHolderOffset = Vector3D(y: -(Roller.bearingDiameter + 2 * holderWallThickness + tolerance + 5) / 2 - 2)

    static let innerShape = baseShape.offset(amount: -topOuterWallThickness, style: .round)

    var unconstrainedRollerHolderMask: any Geometry2D {
        Rectangle(topFarSideRollerHolderSize.xy)
            .cuttingEdgeProfile(.fillet(radius: topFarSideRollerHolderCornerRadius))
            .translated(topFarSideRollerHolderOffset.xy)
            .translated(x: topRollerXOffset + topRollerLength / 2, y: topRollerYOffset)
    }

    var farSideRollerHolderMask: any Geometry2D {
        unconstrainedRollerHolderMask
            .intersecting { baseShape }
    }

    func farSideRollerHolderCoverMask(inset: Double = 0) -> any Geometry3D {
        unconstrainedRollerHolderMask
            .offset(amount: -inset, style: .round)
            .extruded(height: topHeight)
            .translated(z: Self.farSideRollerHolderBaseHeight)
    }

    static let rollerBearingDiameter = Roller.bearingDiameter + tolerance * 2
    static let farSideRollerHolderBaseHeight = rollerHolderAxisZ + rollerBearingDiameter / 2

    var body: any Geometry3D {
        baseShape.subtracting { Self.innerShape }
            .adding {
                baseCornerShape
                    .repeated(count: 3)

                farSideRollerHolderMask
                    .symmetry(over: .y)
            }
            .extruded(height: topHeight + topCoverThickness, topEdge: .fillet(radius: topFilletRadius))
            .subtracting {
                // Corner bottom chamfer
                #warning("2025-08-02 double-check this")
                EdgeProfile.overhangFillet(radius: baseTopChamferSize).profile
                    .flipped(along: .x)
                    .translated(x: baseCornerShapeCircleDiameter / 2 + 0.01)
                    .revolved()
                    .intersecting {
                        Arc(range: -50°..<50°, diameter: baseCornerShapeCircleDiameter + 1)
                            .rotated(180°)
                            .extruded(height: topHeight)
                    }
                    .translated(x: distanceToOuterPoint - baseCornerInset + baseCornerShapeCircleDiameter / 2, z: -0.01)
                    .subtracting { cornerCoverShapeSolid.extruded(height: topHeight).translated(z: -1) }
                    .repeated(around: .z, count: 3)

                unconstrainedRollerHolderMask
                    .extruded(height: topHeight)
                    .subtracting {
                        unconstrainedRollerHolderMask.extruded(
                            height: topHeight,
                            bottomEdge: .overhangFillet(radius: baseTopChamferSize * 4)
                        )
                    }
                    .intersecting { Self.innerShape.extruded(height: baseTopChamferSize * 4) }
                    .symmetry(over: .y)
            }
            .adding {
                // Handle
                let handleZOffset = topHandleDiameter / 2 / 2.squareRoot()
                Cylinder(diameter: topHandleDiameter, height: baseCircleDiameterEquivalent)
                    .aligned(at: .centerZ)
                    .rotated(x: 90°)
                    .translated(x: topHandleXOffset, z: handleZOffset)
                    .intersecting {
                        baseShape.extruded(height: topHeight)
                    }

                    .adding {
                        // Roller holders, handle side
                        let rollerHolderDiameter = Roller.bearingDiameter + 2 * holderWallThickness
                        Circle(diameter: rollerHolderDiameter)
                            .extruded(
                                height: topHandleDiameter / 2,
                                topEdge: .fillet(radius: 1.5),
                                bottomEdge: .fillet(radius: rollerHolderDiameter / 2)
                            )
                            .rotated(y: 90°)
                            .aligned(at: .maxX)
                            .translated(x: -topRollerLength / 2, y: topRollerYOffset, z: Self.rollerHolderAxisZ)
                            .symmetry(over: .y)
                            .translated(x: topRollerXOffset)

                        Roller(length: topRollerLength - 2)
                            .rotated(y: 90°)
                            .translated(x: -8, y: topRollerYOffset, z: Self.rollerHolderAxisZ)
                            .symmetry(over: .y)
                            .inBackground()
                    }

                // Filament roll
                Cylinder(diameter: 200, height: 67)
                    .rotated(y: 90°)
                    .translated(x: -5, z: 97)
                    .inBackground()
                    .hidden()
            }
            .subtracting {
                // Subtract far side roller holder covers
                farSideRollerHolderCoverMask(inset: -tolerance)
                    .symmetry(over: .y)

                Union {
                    Cylinder(diameter: Self.rollerBearingDiameter, height: Roller.bearingThickness + tolerance)
                        .rotated(y: 90°)
                        .translated(x: -0.01, z: Self.rollerHolderAxisZ)
                        .cloned {
                            $0.translated(z: topFarSideRollerHolderSize.z)
                        }
                        .convexHull()

                    Cylinder(diameter: Roller.screwHeadDiameter + tolerance, height: Roller.screwHeadThickness + tolerance)
                        .rotated(y: 90°)
                        .translated(x: Roller.bearingThickness - 0.01, z: Self.rollerHolderAxisZ)
                        .cloned {
                            $0.translated(z: topFarSideRollerHolderSize.z)
                        }
                        .convexHull()

                    // Mount holes
                    for offset in rollerHolderCoverMountPositions {
                        Cylinder(diameter: rollerHolderCoverPilotHoleDiameter, height: rollerHolderCoverPilotHoleDepth)
                            .translated(z: Self.farSideRollerHolderBaseHeight - rollerHolderCoverPilotHoleDepth + 0.01)
                            .translated(topFarSideRollerHolderOffset)
                            .translated(.init(offset))
                    }
                }
                .translated(x: topRollerXOffset + topRollerLength / 2, y: topRollerYOffset)
                .symmetry(over: .y)

                // Subtract corner covers
                topCoverBaseCornerShape
                    .offset(amount: tolerance, style: .round)
                    .repeated(count: 3)
                    .subtracting {
                        cableOutletShape
                            .subtracting(Self.innerShape)
                            .rotated(-120°)
                            .offset(amount: -tolerance, style: .round)
                    }
                    .extruded(height: topCoverThickness + 1)
                    .translated(z: topHeight)

                Union {
                    // Idler space
                    Rectangle([topIdlerSpaceLength, topIdlerSpaceWidth])
                        .cuttingEdgeProfile(.fillet(radius: 2), on: [.topRight, .bottomRight, .bottomLeft])
                        .aligned(at: .center)
                        .translated(x: distanceToOuterPoint - beltCenterInset)
                    //.intersecting { topInnerShape }
                        .extruded(height: topHeight + 2)
                        .translated(z: -1)

                    // Rail
                    Box(x: rail.size.y + tolerance, y: rail.size.x + tolerance, z: topHeight
                        + 2)
                    .aligned(at: .centerXY)
                    .translated(x: distanceToOuterPoint - railInset - rail.size.y / 2, z: -1)

                    let endstopBoardOffset = Vector2D(-1, -0.01)
                    let endstopBoardHoleDiameter = 2.8

                    // Endstop board
                    Rectangle(endstopBoard.size.xy + tolerance + 0.2)
                        .cuttingEdgeProfile(.fillet(radius: endstopBoard.holeInset), on: .topRight)
                        .rotated(180°)
                        .aligned(at: .centerX, .minY)
                        .extruded(height: topHeight)
                        .adding {
                            Box(endstopBoard.endstopSize + [0,0,1])
                                .aligned(at: .centerX, .minY, .maxZ)
                                .translated(z: 0.01)

                            Cylinder(diameter: endstopBoardHoleDiameter, height: topHeight)
                                .translated(
                                    x: endstopBoard.size.x / 2 - endstopBoard.holeInset,
                                    y: endstopBoard.holeInset,
                                    z: -endstopBoard.endstopSize.z + 0.4
                                )
                                .symmetry(over: .x)
                        }
                        .aligned(at: .maxX)
                        .translated(
                            x: distanceToOuterPoint - beltCenterInset + endstopBoardOffset.x,
                            y: topIdlerSpaceWidth / 2 + endstopBoardOffset.y,
                            z: endstopBoard.endstopSize.z
                        )

                    // Corner cover cable channel
                    cornerCoverInnerChannelShape
                        .extruded(height: topHeight + 1)

                    Cylinder(diameter: cornerCoverMountHoleClearanceDiameter, height: topHeight + 1)
                        .translated(z: -0.01)
                        .adding {
                            Cylinder(diameter: cornerCoverMountHoleHeadDiameter, height: topHeight)
                                .translated(z: topCoverMountBottomThickness)
                        }
                        .translated(.init(cornerCoverMountSideHoleOffset))
                        .symmetry(over: .y)

                    for offset in topCoverMountPositions {
                        Cylinder(diameter: topCoverMountPilotHoleDiameter, height: topCoverMountPilotHoleDepth + 1)
                            .translated(x: distanceToOuterPoint, z: topHeight - topCoverMountPilotHoleDepth)
                            .translated(.init(offset))
                            .symmetry(over: .y)
                            //.highlighted()
                    }
                }
                .repeated(around: .z, count: 3)
            }
            .adding {
                Cylinder(diameter: topIdlerHolderRingDiameter, height: topIdlerHolderRingLength)
                    .rotated(y: 90°)
                    .cloned {
                        $0.translated(x: -topIdlerHolderRingLength, z: -topIdlerHolderRingLength)
                    }
                    .convexHull()
                    .translated(x: -topIdlerSpaceLength / 2)
                    .symmetry(over: .x)
                    .translated(x: distanceToOuterPoint - beltCenterInset)
                    .translated(z: topIdlerCenterZ)
                    .repeated(around: .z, count: 3)
            }
            .subtracting {
                // For each corner:
                Union {
                    // Idler bolt and rail bolt
                    let end = distanceToOuterPoint - beltCenterInset + topIdlerSpaceLength / 2 + 1.0
                    let start = end - topIdlerBoltLength - 0.1

                    Cylinder(diameter: topIdlerHoleDiameter, height: end-start)
                        .rotated(y: 90°)
                        .cloned {
                            $0.translated(z: topHeight)
                        }
                        .convexHull()
                        .translated(x: start, z: topIdlerCenterZ)

                    /*
                    // Idler bolt visualization
                    topIdlerBolt
                        .rotated(y: 90°)
                        .aligned(at: .right)
                        .translated(x: end - 0.1, z: topIdlerCenterZ)
                        .inBackground()
                        .hidden()
*/
                    // Idler visualization
                    idler
                        .aligned(at: .centerZ)
                        .rotated(y: 90°)
                        .translated(x: distanceToOuterPoint - beltCenterInset, z: topIdlerCenterZ)
                        .inBackground()

                    // Rail nut trap
                    let nutTrapX = distanceToOuterPoint - railInset - rail.size.y - topRailToNutTrapDistance

                    Box([railNutTrapThickness, railNutTrapWidth, topHeight])
                        .aligned(at: .centerY, .maxX)
                        .translated(z: -railNutTrapWidth / 2)
                        .translated(x: nutTrapX, z: topRailMountZ)

                    Circle(diameter: rail.holeDiameter)
                        .overhangSafe(.bridge)
                        .rotated(90°)
                        .extruded(height: 10)
                        .rotated(y: 90°)
                        .translated(x: nutTrapX - 5, z: topRailMountZ)
                        //.highlighted()

                    // Rail bolt head
                    let railBoltHeadDiameter = 6.2
                    let railBoltHeadLength = 3.5
                    Cylinder(diameter: railBoltHeadDiameter, height: railBoltHeadLength)
                        .rotated(y: 90°)
                        .cloned { $0.translated(z: topHeight) }
                        .convexHull()
                        .cloned {
                            $0.translated(x: railBoltHeadLength - 1, z: railBoltHeadDiameter / 2)
                        }
                        .translated(x: distanceToOuterPoint - railInset - 0.1, z: topRailMountZ)

                    // Idler bolt head
                    //Cylinder(diameter: idlerBoltHeadDiameter, height: topIdlerBolt.headShape.height + 0.4)
                    topIdlerBolt.headShape
                        .scaled(1.2)
                        .rotated(y: 90°)
                        .cloned { $0.translated(z: topHeight) }
                        .convexHull()
                        .translated(x: end - topIdlerBoltLength - 0.2, z: topIdlerCenterZ)
                        .hidden()
                }
                .repeated(around: .z, count: 3)

                // LED strip cable channel
                Box([3, 30, topLEDStripSize.z])
                    .translated(x: -topLEDStripSize.y / 2, y: topLEDStripSize.x / 2 - 1)
                    .adding {
                        Rectangle(topLEDStripSize.xy)
                            .aligned(at: .center)
                            .lofted(height: topLEDStripSize.z) {
                                Rectangle([topLEDStripSize.x, topLEDStripSize.y + topLEDStripExpansion])
                                    .aligned(at: .center)
                            }
                            .rotated(z: 90°)
                    }
                    .translated(x: topHandleXOffset, z: -0.01)

                // Roll holder negative, handle side
                Union {
                    Circle(diameter: Self.rollerBearingDiameter)
                        .overhangSafe(.bridge)
                        .rotated(90°)
                        .extruded(height: Roller.bearingThickness + tolerance)
                        .rotated(y: 90°)
                        .translated(x: -0.01, z: Self.rollerHolderAxisZ)

                    Circle(diameter: Roller.screwHeadDiameter + tolerance)
                        .overhangSafe(.bridge)
                        .rotated(90°)
                        .extruded(height: Roller.screwHeadThickness + tolerance)
                        .rotated(y: 90°)
                        .translated(x: Roller.bearingThickness-0.01, z: Self.rollerHolderAxisZ)
                }
                .translated(x: topRollerLength / 2, y: topRollerYOffset)
                .symmetry(over: .y)
                .flipped(along: .x)
                .translated(x: topRollerXOffset)
            }
            .adding {
                topCover
                    .translated(z: topHeight + 0.01)
                    //.repeated(around: .z, count: 3)
                    .inBackground()
                    .colored(.green, alpha: 0.4)
                    .hidden()

                topCoverWithCableOutlet
                    .translated(z: topHeight + 0.01)
                    .rotated(z: -120°)
                    .inBackground()
                    .colored(.green, alpha: 0.4)
                    .hidden()

                handleCover
                    .rotated(x: 180°)
                    .translated(x: topHandleXOffset)
                    .inBackground()

                rollerHolderCover
                    .translated(x: 0.01, y: 0.01, z: 0.01)
                    .translated(z: Self.farSideRollerHolderBaseHeight)
                    .inBackground()
                    .hidden()
                    //.disabled()
            }
    }

    let topCoverBaseCornerShape = baseCornerShape.cloned {
        let angle = -53°
        let offset = 5.0
        $0.translated(x: -sin(angle) * offset, y: cos(angle) * offset)
        $0.translated(x: -sin(angle) * offset, y: cos(angle) * -offset)
    }
        .convexHull()
        .intersecting { baseShape }

    var topCover: any Geometry3D {
        baseShape.subtracting { Self.innerShape }
            .adding {
                topCoverBaseCornerShape
                    .repeated(count: 3)
            }
            .extruded(height: topHeight + topCoverThickness, topEdge: .fillet(radius: topFilletRadius))
            //.highlighted()
            .intersecting {
                topCoverBaseCornerShape
                    .extruded(height: topCoverThickness + 1)
                    .translated(z: topHeight)
            }
            .translated(z: -topHeight)
            .subtracting {
                for offset in topCoverMountPositions {
                    topCoverMountBoltEquivalent.clearanceHole(recessedHead: true)
                        .flipped(along: .z)
                        .translated(x: distanceToOuterPoint, z: topCoverThickness)
                        .translated(.init(offset))
                        .symmetry(over: .y)
                }
            }
    }

    let cableOutletAngle = -40°
    let cableOutletHoleDiameter = 8.5
    let cableOutletHolePosition = Vector2D(distanceToOuterPoint - 15, -23.2)

    var cableOutletShape: any Geometry2D {
        Circle(diameter: cableOutletHoleDiameter)
            .cloned { $0.translated(x: 20).rotated(cableOutletAngle) }
            .convexHull()
            .translated(x: cableOutletHolePosition.x, y: cableOutletHolePosition.y)
    }

    @GeometryBuilder3D
    var topCoverWithCableOutlet: any Geometry3D {
        let holeDiameter = cableOutletHoleDiameter
        let holePosition = cableOutletHolePosition
        let zipTiePostDiameter = holeDiameter
        let zipTiePostHeight = 6.0
        let zipTiePostTopHeight = 1.0
        let zipTiePostOffset = 4.0
        let zipTiePostAngle = 140°

        topCover
            .adding {
                Cylinder(diameter: zipTiePostDiameter, height: topCoverThickness + zipTiePostHeight)
                    .adding {
                        Cylinder(diameter: zipTiePostDiameter, height: zipTiePostTopHeight)
                            .adding {
                                Cylinder(diameter: zipTiePostDiameter, height: 0.01)
                                    .translated(x: zipTiePostTopHeight, z: zipTiePostTopHeight)
                            }
                            .convexHull()
                            .translated(z: topCoverThickness + zipTiePostHeight)

                    }
                    .translated(x: zipTiePostOffset)
                    .rotated(z: zipTiePostAngle)
                    .translated(x: holePosition.x, y: holePosition.y)
            }
            .subtracting {
                cornerCoverInnerChannelShape
                    .extruded(height: topCoverThickness + 2)
                    .translated(z: -1)
                    .highlighted()
                    .hidden()

                cableOutletShape
                    .extruded(height: topCoverThickness + zipTiePostHeight + zipTiePostTopHeight + 2)
                    .translated(z: -1)
            }
    }

    var handleCover: any Geometry3D {
        Rectangle([handleBottomWidth, topLEDStripSize.x + 2 * handleCoverThickness])
            .aligned(at: .center)
            .extruded(height: handleCoverThickness, topEdge: .chamfer(depth: handleCoverThickness))
            .adding {
                let clipWidth = 10.0
                let clipThickness = 1.0
                let clipSpacing = 23.0

                Box([clipThickness, clipWidth, 0.01])
                    .aligned(at: .maxX, .centerY, .minZ)
                    .cloned {
                        $0.translated(x: topLEDStripExpansion / 2 / 2, z: -topLEDStripSize.z / 2)
                    }
                    .convexHull()
                    .translated(x: topLEDStripSize.y / 2 - 0.1)
                    .repeated(along: .y, in: 0..<topLEDStripSize.x / 2, step: clipSpacing)
                    .symmetry(over: .xy)
            }
    }

    let rollerHolderCoverMountPositions: [Vector2D] = [
        [4.5, 4.5],
        [4.5, 18.5],
        [20.8, 4.5]
    ]

    @GeometryBuilder3D
    var rollerHolderCover: any Geometry3D {
        let coverHeight = topHeight + topCoverThickness - Self.farSideRollerHolderBaseHeight
        //print("coverHeight: \(coverHeight)")

        baseShape.subtracting { Self.innerShape }
            .adding {
                farSideRollerHolderMask
            }
            .extruded(height: topHeight + topCoverThickness, topEdge: .fillet(radius: topFilletRadius))
            .intersecting {
                farSideRollerHolderCoverMask()
            }
            .translated(z: -Self.farSideRollerHolderBaseHeight)
            .subtracting {
                for offset in rollerHolderCoverMountPositions {
                    topCoverMountBoltEquivalent.clearanceHole(recessedHead: true)
                        .flipped(along: .z)
                        .translated(x: topRollerXOffset + topRollerLength / 2, y: topRollerYOffset, z: coverHeight - 0.4)
                        .translated(topFarSideRollerHolderOffset)
                        .translated(.init(offset))
                }
            }
    }
}

let handleBottomWidth = (topHandleDiameter / 2) * 2.squareRoot()
let handleCoverThickness = 0.6

let rollerHolderCoverPilotHoleDiameter = 2.65
let rollerHolderCoverPilotHoleDepth = 8.0
