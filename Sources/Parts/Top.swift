import Cadova
import Helical

/// The ring that caps the three towers. It carries the belt idlers and the rail's upper mounts,
/// houses the endstop boards and an LED strip, and holds the filament spool on a pair of rollers.
///
/// The top is modeled with z = 0 at its underside, so it can be dropped straight onto the towers.
struct Top: Geometry3D {
    static let height = 20.0
    static let outerWallThickness = 4.0
    static let coverThickness = 2.0
    static let filletRadius = 2.0

    static let innerShape = Frame.shape.offset(amount: -outerWallThickness, style: .round)

    // MARK: - Idler

    static let idlerHoleDiameter = 5.5
    static let idlerCenterZ = height / 2 - 2.2
    static let idlerHolderRingDiameter = idlerHoleDiameter + 2.0
    static let idlerHolderRingLength = 1.0
    static let idlerSpaceLength = Idler.width + 2 * idlerHolderRingLength + 0.5
    static let idlerSpaceWidth = Idler.outerDiameter + 4.0

    static let idlerBoltLength = 16.0
    static let idlerBolt = Bolt.phillipsCountersunk(.m5, length: idlerBoltLength)

    // MARK: - Rail

    static let railMountZ = height / 2
    static let railToNutTrapDistance = 1.0
    static let railBoltHeadDiameter = 6.2
    static let railBoltHeadLength = 3.5

    /// X of the rail's nut trap, just inboard of the rail's back face.
    static let railNutTrapX = Frame.outerPointDistance
        - Motion.railInset
        - LinearRail.size.y
        - railToNutTrapDistance

    // MARK: - Handle and LED strip

    static let handleDiameter = 22.0
    static let handleXOffset = -20.0
    static let handleBottomWidth = (handleDiameter / 2) * 2.squareRoot()
    static let handleCoverThickness = 0.6

    static let ledStripSize = Vector3D(152, 12.5, 4.6)
    /// The strip's channel widens slightly towards its opening so the strip can be pushed in.
    static let ledStripExpansion = 1.0

    // MARK: - Cover mounts

    static let coverMountPositions: [Vector2D] = [[-7, 14], [-32, 27]]
    static let coverMountBoltEquivalent = Bolt.phillipsCountersunk(.m3, length: 9)
    static let coverMountPilotHoleDiameter = 2.65
    static let coverMountPilotHoleDepth = 9.0
    static let coverMountBottomThickness = 4.0

    // MARK: - Spool rollers

    static let rollerLength = 75.0
    static let rollerYOffset = 58.0
    static let rollerXOffset = rollerLength / 2 - 9.0
    static let rollerHolderWallThickness = 2.0

    static var rollerBearingDiameter: Double {
        @Environment(\.tolerance) var tolerance
        return Roller.bearingDiameter + tolerance * 2
    }

    /// Height of the rollers' axis above the top's underside.
    static var rollerHolderAxisZ: Double {
        height - rollerBearingDiameter / 2
    }

    // The roller holder on the far side from the handle is tall enough to need a separate printed
    // cover, so the bearing pocket can be closed after assembly.
    static let farHolderCornerRadius = 4.0
    static let farHolderSize = Vector3D(
        x: Roller.bearingThickness + Roller.screwHeadThickness + Roller.washerThickness
            + rollerHolderWallThickness + 30,
        y: Roller.bearingDiameter + 2 * rollerHolderWallThickness + 17.5,
        z: Roller.bearingDiameter + rollerHolderWallThickness + 3
    )

    static var farHolderOffset: Vector3D {
        @Environment(\.tolerance) var tolerance
        return Vector3D(
            y: -(Roller.bearingDiameter + 2 * rollerHolderWallThickness + tolerance + 5) / 2 - 2
        )
    }

    /// The z at which the far holder's cover parts from the top.
    static var farHolderBaseHeight: Double {
        rollerHolderAxisZ + rollerBearingDiameter / 2
    }

    static let farHolderCoverMountPositions: [Vector2D] = [[4.5, 4.5], [4.5, 18.5], [20.8, 4.5]]
    static let farHolderCoverPilotHoleDiameter = 2.65
    static let farHolderCoverPilotHoleDepth = 8.0

    /// Footprint of the far roller holder, before it is trimmed to the frame.
    static var farHolderMask: any Geometry2D {
        Rectangle(farHolderSize.xy)
            .cuttingEdgeProfile(.fillet(radius: farHolderCornerRadius))
            .translated(farHolderOffset.xy)
            .translated(x: rollerXOffset + rollerLength / 2, y: rollerYOffset)
    }

    static var trimmedFarHolderMask: any Geometry2D {
        farHolderMask
            .intersecting { Frame.shape }
    }

    /// The volume the far holder's cover occupies, optionally shrunk by `inset`.
    static func farHolderCoverMask(inset: Double = 0) -> any Geometry3D {
        farHolderMask
            .offset(amount: -inset, style: .round)
            .extruded(height: height)
            .translated(z: farHolderBaseHeight)
    }

    // MARK: - Body

    var body: any Geometry3D {
        @Environment(\.tolerance) var tolerance

        Frame.shape
            .subtracting { Self.innerShape }
            .adding {
                Frame.cornerShape
                    .repeated(count: 3)

                Self.trimmedFarHolderMask
                    .symmetry(over: .y)
            }
            .extruded(height: Self.height + Self.coverThickness, topEdge: .fillet(radius: Self.filletRadius))
            .subtracting {
                Self.cornerBottomChamfer
                Self.farHolderUndercut
            }
            .adding {
                Self.handle
            }
            .subtracting {
                // The far holder's cover is printed separately, so leave its volume open
                Self.farHolderCoverMask(inset: -tolerance)
                    .symmetry(over: .y)

                Self.farHolderPockets(tolerance: tolerance)

                Self.coverRecesses(tolerance: tolerance)

                Self.towerCutouts(tolerance: tolerance)
                    .repeated(around: .z, count: 3)
            }
            .adding {
                Self.idlerHolderRings
                    .repeated(around: .z, count: 3)
            }
            .subtracting {
                Self.towerBoltCutouts
                    .repeated(around: .z, count: 3)

                Self.ledStripChannel
                Self.handleSideRollerPockets(tolerance: tolerance)
            }
            .adding {
                Self.assemblyPreview
            }
    }

    // MARK: - Shell details

    /// A rounded relief where the base's chamfer meets each corner, so the two meet flush.
    private static var cornerBottomChamfer: any Geometry3D {
        // TODO: 2025-08-02 — double-check this against the current EdgeProfile semantics.
        EdgeProfile.overhangFillet(radius: Base.topChamferSize).profile
            .flipped(along: .x)
            .translated(x: Frame.cornerCircleDiameter / 2 + 0.01)
            .revolved()
            .intersecting {
                Arc(range: -50°..<50°, diameter: Frame.cornerCircleDiameter + 1)
                    .rotated(180°)
                    .extruded(height: height)
            }
            .translated(
                x: Frame.outerPointDistance - Frame.cornerInset + Frame.cornerCircleDiameter / 2,
                z: -0.01
            )
            .subtracting {
                CornerCover.solidShape.extruded(height: height).translated(z: -1)
            }
            .repeated(around: .z, count: 3)
    }

    /// Blends the underside of the far roller holder into the shell so it prints without support.
    private static var farHolderUndercut: any Geometry3D {
        farHolderMask
            .extruded(height: height)
            .subtracting {
                farHolderMask.extruded(
                    height: height,
                    bottomEdge: .overhangFillet(radius: Base.topChamferSize * 4)
                )
            }
            .intersecting { innerShape.extruded(height: Base.topChamferSize * 4) }
            .symmetry(over: .y)
    }

    // MARK: - Handle and rollers

    /// The carrying handle, and the spool roller holders on the handle side.
    private static var handle: any Geometry3D {
        // Sitting the cylinder's axis this far up puts its widest point at the top surface
        let handleZOffset = handleDiameter / 2 / 2.squareRoot()
        let rollerHolderDiameter = Roller.bearingDiameter + 2 * rollerHolderWallThickness

        return Cylinder(diameter: handleDiameter, height: Frame.circleDiameterEquivalent)
            .aligned(at: .centerZ)
            .rotated(x: 90°)
            .translated(x: handleXOffset, z: handleZOffset)
            .intersecting {
                Frame.shape.extruded(height: height)
            }
            .adding {
                Circle(diameter: rollerHolderDiameter)
                    .extruded(
                        height: handleDiameter / 2,
                        topEdge: .fillet(radius: 1.5),
                        bottomEdge: .fillet(radius: rollerHolderDiameter / 2)
                    )
                    .rotated(y: 90°)
                    .aligned(at: .maxX)
                    .translated(x: -rollerLength / 2, y: rollerYOffset, z: rollerHolderAxisZ)
                    .symmetry(over: .y)
                    .translated(x: rollerXOffset)

                Roller(length: rollerLength - 2)
                    .rotated(y: 90°)
                    .translated(x: -8, y: rollerYOffset, z: rollerHolderAxisZ)
                    .symmetry(over: .y)
                    .inBackground()

                // A full spool, to check it clears the frame. Disabled by default.
                Cylinder(diameter: 200, height: 67)
                    .rotated(y: 90°)
                    .translated(x: -5, z: 97)
                    .inBackground()
                    .hidden()
            }
    }

    /// Bearing and screw-head pockets in the handle-side roller holders.
    private static func handleSideRollerPockets(tolerance: Double) -> any Geometry3D {
        Union {
            Circle(diameter: rollerBearingDiameter)
                .overhangSafe(.bridge)
                .rotated(90°)
                .extruded(height: Roller.bearingThickness + tolerance)
                .rotated(y: 90°)
                .translated(x: -0.01, z: rollerHolderAxisZ)

            Circle(diameter: Roller.screwHeadDiameter + tolerance)
                .overhangSafe(.bridge)
                .rotated(90°)
                .extruded(height: Roller.screwHeadThickness + tolerance)
                .rotated(y: 90°)
                .translated(x: Roller.bearingThickness - 0.01, z: rollerHolderAxisZ)
        }
        .translated(x: rollerLength / 2, y: rollerYOffset)
        .symmetry(over: .y)
        .flipped(along: .x)
        .translated(x: rollerXOffset)
    }

    /// Bearing and screw-head pockets in the far roller holder, plus its cover's pilot holes.
    /// The pockets are hulled upward so they open to the cover's parting plane.
    private static func farHolderPockets(tolerance: Double) -> any Geometry3D {
        Union {
            Cylinder(diameter: rollerBearingDiameter, height: Roller.bearingThickness + tolerance)
                .rotated(y: 90°)
                .translated(x: -0.01, z: rollerHolderAxisZ)
                .cloned {
                    $0.translated(z: farHolderSize.z)
                }
                .convexHull()

            Cylinder(
                diameter: Roller.screwHeadDiameter + tolerance,
                height: Roller.screwHeadThickness + tolerance
            )
            .rotated(y: 90°)
            .translated(x: Roller.bearingThickness - 0.01, z: rollerHolderAxisZ)
            .cloned {
                $0.translated(z: farHolderSize.z)
            }
            .convexHull()

            for offset in farHolderCoverMountPositions {
                Cylinder(
                    diameter: farHolderCoverPilotHoleDiameter,
                    height: farHolderCoverPilotHoleDepth
                )
                .translated(z: farHolderBaseHeight - farHolderCoverPilotHoleDepth + 0.01)
                .translated(farHolderOffset)
                .translated(.init(offset))
            }
        }
        .translated(x: rollerXOffset + rollerLength / 2, y: rollerYOffset)
        .symmetry(over: .y)
    }

    /// The recesses the three corner covers drop into, keeping the cable outlet solid.
    private static func coverRecesses(tolerance: Double) -> any Geometry3D {
        coverBaseCornerShape
            .offset(amount: tolerance, style: .round)
            .repeated(count: 3)
            .subtracting {
                cableOutletShape
                    .subtracting(innerShape)
                    .rotated(-120°)
                    .offset(amount: -tolerance, style: .round)
            }
            .extruded(height: coverThickness + 1)
            .translated(z: height)
    }

    /// The LED strip's channel, with a cable run out to the handle.
    private static var ledStripChannel: any Geometry3D {
        Box([3, 30, ledStripSize.z])
            .translated(x: -ledStripSize.y / 2, y: ledStripSize.x / 2 - 1)
            .adding {
                Rectangle(ledStripSize.xy)
                    .aligned(at: .center)
                    .lofted(height: ledStripSize.z) {
                        Rectangle([ledStripSize.x, ledStripSize.y + ledStripExpansion])
                            .aligned(at: .center)
                    }
                    .rotated(z: 90°)
            }
            .translated(x: handleXOffset, z: -0.01)
    }

    // MARK: - Tower features

    /// Everything one tower takes out of the top. Applied once, then repeated about z.
    @GeometryBuilder3D
    private static func towerCutouts(tolerance: Double) -> any Geometry3D {
        // Space for the idler
        Rectangle([idlerSpaceLength, idlerSpaceWidth])
            .cuttingEdgeProfile(.fillet(radius: 2), on: [.topRight, .bottomRight, .bottomLeft])
            .aligned(at: .center)
            .translated(x: Frame.outerPointDistance - Motion.beltCenterInset)
            .extruded(height: height + 2)
            .translated(z: -1)

        // Slot the rail passes through
        Box(
            x: LinearRail.size.y + tolerance,
            y: LinearRail.size.x + tolerance,
            z: height + 2
        )
        .aligned(at: .centerXY)
        .translated(x: Frame.outerPointDistance - Motion.railInset - LinearRail.size.y / 2, z: -1)

        endstopBoardPocket(tolerance: tolerance)

        // Cable channel up from the corner cover
        CornerCover.innerChannelShape
            .extruded(height: height + 1)

        // Corner cover's side mount screws
        Cylinder(diameter: CornerCover.mountHoleClearanceDiameter, height: height + 1)
            .translated(z: -0.01)
            .adding {
                Cylinder(diameter: CornerCover.mountHoleHeadDiameter, height: height)
                    .translated(z: coverMountBottomThickness)
            }
            .translated(.init(CornerCover.mountSideHoleOffset))
            .symmetry(over: .y)

        // Pilot holes for the top cover
        for offset in coverMountPositions {
            Cylinder(diameter: coverMountPilotHoleDiameter, height: coverMountPilotHoleDepth + 1)
                .translated(x: Frame.outerPointDistance, z: height - coverMountPilotHoleDepth)
                .translated(.init(offset))
                .symmetry(over: .y)
        }
    }

    /// The recess the endstop board slides into, with its switch protruding below.
    private static func endstopBoardPocket(tolerance: Double) -> any Geometry3D {
        let boardOffset = Vector2D(-1, -0.01)
        let boardHoleDiameter = 2.8

        return Rectangle(EndstopBoard.size.xy + tolerance + 0.2)
            .cuttingEdgeProfile(.fillet(radius: EndstopBoard.holeInset), on: .topRight)
            .rotated(180°)
            .aligned(at: .centerX, .minY)
            .extruded(height: height)
            .adding {
                Box(EndstopBoard.endstopSize + [0, 0, 1])
                    .aligned(at: .centerX, .minY, .maxZ)
                    .translated(z: 0.01)

                Cylinder(diameter: boardHoleDiameter, height: height)
                    .translated(
                        x: EndstopBoard.size.x / 2 - EndstopBoard.holeInset,
                        y: EndstopBoard.holeInset,
                        z: -EndstopBoard.endstopSize.z + 0.4
                    )
                    .symmetry(over: .x)
            }
            .aligned(at: .maxX)
            .translated(
                x: Frame.outerPointDistance - Motion.beltCenterInset + boardOffset.x,
                y: idlerSpaceWidth / 2 + boardOffset.y,
                z: EndstopBoard.endstopSize.z
            )
    }

    /// Collars that centre the idler on its bolt, hulled downward so they print unsupported.
    private static var idlerHolderRings: any Geometry3D {
        Cylinder(diameter: idlerHolderRingDiameter, height: idlerHolderRingLength)
            .rotated(y: 90°)
            .cloned {
                $0.translated(x: -idlerHolderRingLength, z: -idlerHolderRingLength)
            }
            .convexHull()
            .translated(x: -idlerSpaceLength / 2)
            .symmetry(over: .x)
            .translated(x: Frame.outerPointDistance - Motion.beltCenterInset)
            .translated(z: idlerCenterZ)
    }

    /// The bolt holes serving one tower: the idler axle and the rail's upper fixing.
    @GeometryBuilder3D
    private static var towerBoltCutouts: any Geometry3D {
        let boltEnd = Frame.outerPointDistance - Motion.beltCenterInset + idlerSpaceLength / 2 + 1.0
        let boltStart = boltEnd - idlerBoltLength - 0.1

        // Idler bolt, hulled up so it can be dropped in from above
        Cylinder(diameter: idlerHoleDiameter, height: boltEnd - boltStart)
            .rotated(y: 90°)
            .cloned {
                $0.translated(z: height)
            }
            .convexHull()
            .translated(x: boltStart, z: idlerCenterZ)

        Idler()
            .aligned(at: .centerZ)
            .rotated(y: 90°)
            .translated(x: Frame.outerPointDistance - Motion.beltCenterInset, z: idlerCenterZ)
            .inBackground()

        // Rail nut trap, and the screw's access hole
        Box([Motion.railNutTrapThickness, Motion.railNutTrapWidth, height])
            .aligned(at: .centerY, .maxX)
            .translated(z: -Motion.railNutTrapWidth / 2)
            .translated(x: railNutTrapX, z: railMountZ)

        Circle(diameter: LinearRail.holeDiameter)
            .overhangSafe(.bridge)
            .rotated(90°)
            .extruded(height: 10)
            .rotated(y: 90°)
            .translated(x: railNutTrapX - 5, z: railMountZ)

        // Rail bolt head, hulled up and outward for driver access
        Cylinder(diameter: railBoltHeadDiameter, height: railBoltHeadLength)
            .rotated(y: 90°)
            .cloned { $0.translated(z: height) }
            .convexHull()
            .cloned {
                $0.translated(x: railBoltHeadLength - 1, z: railBoltHeadDiameter / 2)
            }
            .translated(x: Frame.outerPointDistance - Motion.railInset - 0.1, z: railMountZ)

        idlerBolt.headShape
            .scaled(1.2)
            .rotated(y: 90°)
            .cloned { $0.translated(z: height) }
            .convexHull()
            .translated(x: boltEnd - idlerBoltLength - 0.2, z: idlerCenterZ)
            .hidden()
    }

    /// Mating parts shown in place, to check fit.
    @GeometryBuilder3D
    private static var assemblyPreview: any Geometry3D {
        topCover
            .translated(z: height + 0.01)
            .inBackground()
            .colored(.green, alpha: 0.4)
            .hidden()

        topCoverWithCableOutlet
            .translated(z: height + 0.01)
            .rotated(z: -120°)
            .inBackground()
            .colored(.green, alpha: 0.4)
            .hidden()

        handleCover
            .rotated(x: 180°)
            .translated(x: handleXOffset)
            .inBackground()

        farHolderCover
            .translated(x: 0.01, y: 0.01, z: 0.01)
            .translated(z: farHolderBaseHeight)
            .inBackground()
            .hidden()
    }

    // MARK: - Covers
    //
    // Three separate prints close the top: one over each corner, one over the handle's LED
    // channel, and one over the far roller holder.

    /// The footprint of one corner cover plate: the frame's corner wedge, splayed sideways so the
    /// plate overlaps the shell it sits on.
    static let coverBaseCornerShape = Frame.cornerShape
        .cloned {
            let angle = -53°
            let offset = 5.0
            $0.translated(x: -sin(angle) * offset, y: cos(angle) * offset)
            $0.translated(x: -sin(angle) * offset, y: cos(angle) * -offset)
        }
        .convexHull()
        .intersecting { Frame.shape }

    /// The plate covering one corner of the top.
    static var topCover: any Geometry3D {
        Frame.shape
            .subtracting { innerShape }
            .adding {
                coverBaseCornerShape
                    .repeated(count: 3)
            }
            .extruded(height: height + coverThickness, topEdge: .fillet(radius: filletRadius))
            // Keep only the corner in question, at the height the cover occupies
            .intersecting {
                coverBaseCornerShape
                    .extruded(height: coverThickness + 1)
                    .translated(z: height)
            }
            .translated(z: -height)
            .subtracting {
                for offset in coverMountPositions {
                    coverMountBoltEquivalent.clearanceHole(entry: .recessedHead)
                        .flipped(along: .z)
                        .translated(x: Frame.outerPointDistance, z: coverThickness)
                        .translated(.init(offset))
                        .symmetry(over: .y)
                }
            }
    }

    // MARK: - Cable outlet

    static let cableOutletAngle = -40°
    static let cableOutletHoleDiameter = 8.5
    static let cableOutletHolePosition = Vector2D(Frame.outerPointDistance - 15, -23.2)

    /// A slot for the wiring loom leaving the top, elongated along `cableOutletAngle`.
    static var cableOutletShape: any Geometry2D {
        Circle(diameter: cableOutletHoleDiameter)
            .cloned { $0.translated(x: 20).rotated(cableOutletAngle) }
            .convexHull()
            .translated(cableOutletHolePosition)
    }

    /// The one corner cover that the wiring passes through, with a post to zip-tie it to.
    static var topCoverWithCableOutlet: any Geometry3D {
        let zipTiePostDiameter = cableOutletHoleDiameter
        let zipTiePostHeight = 6.0
        let zipTiePostTopHeight = 1.0
        let zipTiePostOffset = 4.0
        let zipTiePostAngle = 140°

        return topCover
            .adding {
                Cylinder(diameter: zipTiePostDiameter, height: coverThickness + zipTiePostHeight)
                    .adding {
                        // A lip at the top stops the tie sliding off
                        Cylinder(diameter: zipTiePostDiameter, height: zipTiePostTopHeight)
                            .adding {
                                Cylinder(diameter: zipTiePostDiameter, height: 0.01)
                                    .translated(x: zipTiePostTopHeight, z: zipTiePostTopHeight)
                            }
                            .convexHull()
                            .translated(z: coverThickness + zipTiePostHeight)
                    }
                    .translated(x: zipTiePostOffset)
                    .rotated(z: zipTiePostAngle)
                    .translated(x: cableOutletHolePosition.x, y: cableOutletHolePosition.y)
            }
            .subtracting {
                CornerCover.innerChannelShape
                    .extruded(height: coverThickness + 2)
                    .translated(z: -1)
                    .highlighted()
                    .hidden()

                cableOutletShape
                    .extruded(height: coverThickness + zipTiePostHeight + zipTiePostTopHeight + 2)
                    .translated(z: -1)
            }
    }

    /// A thin lid that clips over the LED strip channel in the handle.
    static var handleCover: any Geometry3D {
        let clipWidth = 10.0
        let clipThickness = 1.0
        let clipSpacing = 23.0

        return Rectangle([handleBottomWidth, ledStripSize.x + 2 * handleCoverThickness])
            .aligned(at: .center)
            .extruded(height: handleCoverThickness, topEdge: .chamfer(depth: handleCoverThickness))
            .adding {
                // Barbs along both edges that spring into the channel's widened walls
                Box([clipThickness, clipWidth, 0.01])
                    .aligned(at: .maxX, .centerY, .minZ)
                    .cloned {
                        $0.translated(x: ledStripExpansion / 2 / 2, z: -ledStripSize.z / 2)
                    }
                    .convexHull()
                    .translated(x: ledStripSize.y / 2 - 0.1)
                    .repeated(along: .y, in: 0..<ledStripSize.x / 2, step: clipSpacing)
                    .symmetry(over: .xy)
            }
    }

    /// The lid that closes the far roller holder's bearing pocket after assembly.
    static var farHolderCover: any Geometry3D {
        let coverHeight = height + coverThickness - farHolderBaseHeight

        return Frame.shape
            .subtracting { innerShape }
            .adding {
                trimmedFarHolderMask
            }
            .extruded(height: height + coverThickness, topEdge: .fillet(radius: filletRadius))
            .intersecting {
                farHolderCoverMask()
            }
            .translated(z: -farHolderBaseHeight)
            .subtracting {
                for offset in farHolderCoverMountPositions {
                    coverMountBoltEquivalent.clearanceHole(entry: .recessedHead)
                        .flipped(along: .z)
                        .translated(
                            x: rollerXOffset + rollerLength / 2,
                            y: rollerYOffset,
                            z: coverHeight - 0.4
                        )
                        .translated(farHolderOffset)
                        .translated(.init(offset))
                }
            }
    }
}
