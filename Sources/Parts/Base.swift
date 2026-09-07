import Cadova
import Helical

/// The main body of the printer: the chamber that holds the three steppers, the control board
/// and the wiring, with the print bed forming its top surface.
///
/// The base is modeled the right way up, with z = 0 at the underside and `height` at the bed. A
/// few features are easier to place from the other end; `flippedTransform` puts them there.
struct Base: Geometry3D {
    static let wallThickness = 2.0
    static let topThickness = 2.0
    static let height = 50.0
    static let topChamferSize = 2.0

    static let stepperWallThickness = 7.0
    static let stepperWallInset = 18.0
    static let stepperZCenter = 19.6
    static let stepperZFromTop = height - stepperZCenter - topThickness - StepperMotor.size.y / 2

    static let railNutTrapBarSize = Motion.railNutTrapWidth + 1.0
    static let sensorBoardMountXOffset = -50.0

    static let ledBoardCenterZ = 33.5
    static let frontLEDDiameter = 3.0
    static let frontLEDThickness = 0.4

    static var powerConnectorHoleDiameter: Double {
        @Environment(\.tolerance) var tolerance
        return 7.8 + tolerance
    }

    static let innerShape = Frame.shape.offset(amount: -wallThickness, style: .round)

    /// Turns the base upside down and back, for features measured from the top surface.
    static let flippedTransform = Transform3D.rotation(x: 180°).translated(z: height - topThickness)

    /// Distance from the center out to the inboard face of a stepper wall.
    static let stepperWallX = Frame.outerPointDistance - stepperWallInset - stepperWallThickness

    var body: any Geometry3D {
        @Environment(\.tolerance) var tolerance

        Frame.shape
            .extruded(height: Self.height, topEdge: .chamfer(depth: Self.topChamferSize))
            .adding {
                // The corners carry the covers, so they stay square rather than chamfered
                CornerCover.shape
                    .repeated(count: 3)
                    .extruded(height: Self.height)
            }
            .subtracting {
                // Hollow out the chamber
                Self.innerShape
                    .extruded(height: Self.height - Self.topThickness + 1)
                    .translated(z: -1)

                // Open the top over each pulley so the belt can pass
                Self.innerShape
                    .intersecting {
                        Rectangle([Frame.circleDiameterEquivalent, Frame.circleDiameterEquivalent])
                            .aligned(at: .left, .centerY)
                            .translated(x: Frame.outerPointDistance - Self.stepperWallInset)
                            .repeated(count: 3)
                    }
                    .extruded(height: Self.topThickness + 2)
                    .translated(z: Self.height - Self.topThickness - 1)
            }
            .adding {
                Self.cornerCoverMounts.hidden()
                Self.stepperWalls
                Self.sensorBoardMount
                Self.duetMount
                Self.sideRail
                Self.buttonPanel
                Self.ledBoardHousing
                Self.bottomMountPosts
                Self.zipTieHandles
                Self.steppers
            }
            .subtracting {
                Self.towerCutouts(tolerance: tolerance)
                    .repeated(around: .z, count: 3)

                Self.buttonHoles(tolerance: tolerance)
                Self.frontLEDWindow
                Self.powerConnectorHole

                // Pilot holes for the bottom plate's stepper-wall screws
                Cylinder(diameter: Bottom.mountPilotHoleDiameter, height: Bottom.mountPilotHoleDepth + 1)
                    .translated(
                        x: Frame.outerPointDistance - Self.stepperWallInset - Self.stepperWallThickness / 2,
                        y: Bottom.mountStepperWallYOffset,
                        z: -1
                    )
                    .symmetry(over: .y)
                    .repeated(around: .z, count: 3)
            }
            // The bed's sprung probe flaps are cut from the finished top surface
            .adding { Bed.mounts }
            .subtracting { Bed.flapCutouts }
            .adding { Bed.probeClearances }
    }

    // MARK: - Chamber structure

    /// The wall behind each stepper, which also carries the rail's nut trap bar.
    @GeometryBuilder3D
    private static var stepperWalls: any Geometry3D {
        Rectangle([stepperWallThickness, Frame.circleDiameterEquivalent])
            .aligned(at: .centerY)
            .translated(x: stepperWallX)
            .intersecting {
                Frame.shape
            }
            .extruded(height: height - topThickness)
            .adding {
                // Thin rib stiffening the wall against the belt tension
                Box(x: 1.0, y: 13, z: height / 2)
                    .aligned(at: .centerY)
                    .translated(x: Frame.outerPointDistance - stepperWallInset, z: height / 2)

                // Rail nut trap bar
                Box([railNutTrapBarSize, Frame.circleDiameterEquivalent, railNutTrapBarSize])
                    .aligned(at: .centerY, .maxX)
                    .translated(x: stepperWallX)
                    .translated(z: height - topThickness - railNutTrapBarSize)
                    .intersecting {
                        Frame.shape.extruded(height: height)
                    }
            }
            .repeated(around: .z, count: 3)
    }

    /// A rail running around the inside of the chamber floor, stiffening the walls and giving the
    /// bottom plate something to seat against.
    private static var sideRail: any Geometry3D {
        let sideRailWidth = 7.0
        let sideRailHeight = 7.0

        let floorShape = innerShape
            .subtracting {
                Rectangle([Frame.circleDiameterEquivalent, Frame.circleDiameterEquivalent])
                    .aligned(at: .centerY)
                    .translated(x: stepperWallX)
                    .repeated(count: 3)
            }

        return floorShape
            .subtracting {
                floorShape.offset(amount: -sideRailWidth, style: .round)
            }
            .extruded(height: sideRailHeight)
            .transformed(flippedTransform)
    }

    /// Ring bosses at each corner point that take the corner covers' center screws.
    private static var cornerCoverMounts: any Geometry3D {
        let mountThickness = 3.0

        return Circle(diameter: CornerCover.mountHoleClearanceDiameter + 2.5)
            .cloned {
                $0.translated(x: 100)
                $0.translated(y: 100)
            }
            .convexHull()
            .subtracting {
                Circle(diameter: CornerCover.mountHoleClearanceDiameter)
            }
            .translated(
                x: Frame.outerPointDistance - CornerCover.mountCenterHoleInset,
                y: CornerCover.mountCenterHoleYOffset
            )
            .intersecting { Frame.shape }
            .extruded(height: mountThickness)
            .adding {
                Cylinder(diameter: 5.5, height: 2.2)
                    .translated(
                        x: Frame.outerPointDistance - CornerCover.mountCenterHoleInset,
                        y: CornerCover.mountCenterHoleYOffset,
                        z: -2.2
                    )
                    .inBackground()
            }
            .translated(z: height - mountThickness)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
    }

    // MARK: - Electronics

    /// The bar the bed sensor board screws onto, under the base's top surface.
    private static var sensorBoardMount: any Geometry3D {
        Box(BedSensorBoard.mountBarSize)
            .aligned(at: .centerXY)
            .subtracting {
                Cylinder(
                    diameter: BedSensorBoard.mountBarHoleDiameter,
                    height: BedSensorBoard.mountBarSize.z + 1
                )
                .translated(x: BedSensorBoard.mountBarHoleDistance / 2, z: -1)
                .symmetry(over: .x)
            }
            .rotated(z: 90°)
            .translated(x: sensorBoardMountXOffset)
            .transformed(flippedTransform)
    }

    /// Four standoffs for the Duet board, each braced back to the chamber floor by a rib.
    private static var duetMount: any Geometry3D {
        let topHoleBarAngle = 30°
        let bottomHoleBarAngle = 180°
        let mountBarHeight = BedSensorBoard.fullHeight + 3.0
        let duetXOffset = -10.0

        /// One standoff, with its bracing rib swept off at `angle`.
        @Sendable func post(at angle: Angle) -> any Geometry2D {
            Circle(diameter: Duet.screwPostDiameter)
                .cloned {
                    $0.translated(x: Frame.circleDiameterEquivalent).rotated(angle)
                }
                .convexHull()
                .subtracting {
                    Circle(diameter: Duet.screwPilotHoleDiameter)
                }
        }

        return post(at: topHoleBarAngle)
            .translated(Duet.size.xy / 2 - Duet.holeInset)
            .adding {
                post(at: bottomHoleBarAngle)
                    .translated(-Duet.size.xy / 2 + Duet.holeInset)
            }
            .symmetry(over: .y)
            .extruded(height: mountBarHeight)
            .adding {
                Duet()
                    .translated(z: mountBarHeight + 0.01)
                    .colored(.darkGreen, alpha: 0.4)
                    .inBackground()
            }
            .translated(x: duetXOffset)
            .transformed(flippedTransform)
            .intersecting {
                innerShape.extruded(height: height)
            }
    }

    /// The recess and surrounding housing for the indicator LED board in the front edge.
    private static var ledBoardHousing: any Geometry3D {
        Rectangle(x: LEDBoard.size.x, y: LEDBoard.size.y)
            .adding {
                Rectangle(x: LEDBoard.size.x, y: 3)
                    .translated(y: LEDBoard.size.y)
            }
            .translated(x: -LEDBoard.size.x / 2, y: -LEDBoard.size.y / 2)
            .subtracting {
                Circle(diameter: LEDBoard.holePilotDiameter)
                    .translated(
                        x: -LEDBoard.size.x / 2 + LEDBoard.holeInset,
                        y: -LEDBoard.size.y / 2 + LEDBoard.holeInset
                    )
                    .symmetry(over: .y)

                Rectangle([LEDBoard.ledSpaceSize, LEDBoard.ledSpaceSize])
                    .aligned(at: .center)
                    .hidden()

                // Leave the connector end open
                Rectangle([LEDBoard.connectorInset + 1, LEDBoard.size.y + 2])
                    .aligned(at: .centerY)
                    .translated(x: LEDBoard.size.x / 2 - LEDBoard.connectorInset)
            }
            .translated(x: LEDBoard.size.x / 2 - LEDBoard.ledXCenter)
            .extruded(height: LEDBoard.connectorThickness + wallThickness)
            .rotated(z: 90°)
            .rotated(y: 90°)
            .translated(x: -Frame.edgeDistance, z: ledBoardCenterZ)
            .intersecting {
                Frame.shape.extruded(height: height)
            }
    }

    // MARK: - Front panel

    private static let buttonAngularSpread = -12°...12°
    private static let buttonCount = 5
    private static let buttonZ = 17.0

    /// The thickened panel the front buttons snap into.
    private static var buttonPanel: any Geometry3D {
        let panelThickness = 2.5
        let maxDiameter = 16.5 + 1.0

        return Cylinder(diameter: maxDiameter, height: panelThickness)
            .aligned(at: .centerZ)
            .adding {
                Cylinder(diameter: maxDiameter, height: 0.01)
                    .translated(x: panelThickness / 2)
            }
            .convexHull()
            .rotated(y: -90°)
            .translated(x: Frame.width - wallThickness / 2)
            .repeated(around: .z, in: buttonAngularSpread, count: buttonCount)
            .rotated(z: 180°)
            .translated(x: Frame.edgePivotDistance, z: buttonZ)
    }

    /// Holes through the front panel, each with a flat that keys the button against rotating.
    private static func buttonHoles(tolerance: Double) -> any Geometry3D {
        let holeDiameter = 15 + tolerance - 0.1

        return Circle(diameter: holeDiameter)
            .overhangSafe(.bridge)
            .subtracting {
                Rectangle([1.5 - tolerance, 1.0 - tolerance])
                    .aligned(at: .centerX)
                    .translated(y: -holeDiameter / 2)
            }
            .rotated(90°)
            .extruded(height: wallThickness + 2)
            .rotated(y: -90°)
            .translated(x: Frame.width + 1)
            .repeated(around: .z, in: buttonAngularSpread, count: buttonCount)
            .rotated(z: 180°)
            .translated(x: Frame.edgePivotDistance, z: buttonZ)
    }

    /// A thin window over the indicator LED, left just proud of the outer surface so it glows
    /// through the wall.
    private static var frontLEDWindow: any Geometry3D {
        Circle(diameter: frontLEDDiameter)
            .extruded(height: wallThickness)
            .adding {
                Box([LEDBoard.ledSpaceSize, LEDBoard.ledSpaceSize, LEDBoard.ledThickness])
                    .aligned(at: .centerXY, .maxZ)
                    .translated(z: LEDBoard.connectorThickness + wallThickness + 0.01)
            }
            .convexHull()
            .rotated(y: 90°)
            .translated(x: -Frame.edgeDistance, z: ledBoardCenterZ)
            .intersecting {
                Frame.shape
                    .offset(amount: -frontLEDThickness, style: .round)
                    .extruded(height: height)
            }
    }

    private static var powerConnectorHole: any Geometry3D {
        Circle(diameter: powerConnectorHoleDiameter)
            .overhangSafe(.bridge)
            .rotated(-90°)
            .extruded(height: wallThickness + 2)
            .rotated(y: 90°)
            .translated(x: Frame.width - wallThickness - 1)
            .rotated(z: 180° + 14°)
            .translated(x: Frame.edgePivotDistance, z: 15)
            .rotated(z: 120°)
    }

    // MARK: - Assembly features

    /// Posts for the bottom plate's side screws, braced back into the wall.
    private static var bottomMountPosts: any Geometry3D {
        Cylinder(diameter: Bottom.mountPilotHoleDiameter + 3, height: Bottom.mountPilotHoleDepth)
            .cloned {
                $0.translated(x: 10)
                $0.translated(x: 10, z: 10)
            }
            .convexHull()
            .subtracting {
                Cylinder(diameter: Bottom.mountPilotHoleDiameter, height: Bottom.mountPilotHoleDepth + 1)
                    .translated(z: -1)
            }
            .translated(x: Frame.width - Bottom.mountSideInset)
            .rotated(z: 180° + Bottom.mountSideAngularOffset)
            .translated(x: Frame.edgePivotDistance)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
            .intersecting {
                Frame.shape.extruded(height: height)
            }
    }

    /// Anchors on each stepper wall for zip-tying the tower's wiring loom.
    private static var zipTieHandles: any Geometry3D {
        let handleWidth = 4.0
        let handleThickness = 6.0
        let handleLength = 7.0
        let supportThickness = 2.0
        let topZ = 37.0

        return Box([handleLength, handleWidth, handleThickness - handleWidth / 2])
            .aligned(at: .centerY, .maxX, .maxZ)
            .adding {
                Cylinder(diameter: handleWidth, height: handleLength)
                    .rotated(y: -90°)

                Box([supportThickness, handleWidth, height - topZ])
                    .aligned(at: .minX, .centerY, .minZ)
                    .translated(x: -handleLength)
            }
            .translated(x: stepperWallX + 0.01, y: 25, z: topZ)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
    }

    /// The three steppers and their pulleys, shown for reference.
    private static var steppers: any Geometry3D {
        StepperMotor()
            .colored(.darkGray, alpha: 0.3)
            .adding {
                Pulley()
                    .translated(z: StepperMotor.size.z + StepperMotor.shaftLength - Pulley.length)
            }
            .rotated(y: 90°)
            .aligned(at: .top)
            .translated(x: -StepperMotor.size.z)
            .translated(x: stepperWallX)
            .translated(z: height - stepperZFromTop)
            .repeated(around: .z, count: 3)
            .colored(.gray, alpha: 0.2)
            .inBackground()
    }

    // MARK: - Tower cutouts
    //
    // Everything one tower takes out of the base. Applied once and repeated about z.

    @GeometryBuilder3D
    private static func towerCutouts(tolerance: Double) -> any Geometry3D {
        // Shaft and screw holes through the stepper wall
        Circle(diameter: StepperMotor.circleDiameter + 1)
            .overhangSafe(.bridge)
            .rotated(-90°)
            .adding {
                Circle(diameter: StepperMotor.holeDiameter + 0.5)
                    .overhangSafe(.bridge)
                    .rotated(-90°)
                    .distributed(
                        at: [-StepperMotor.holeDistance / 2, StepperMotor.holeDistance / 2],
                        along: .x
                    )
                    .translated(y: StepperMotor.holeDistance / 2)
                    .symmetry(over: .y)
            }
            .extruded(height: stepperWallThickness + 2)
            .adding {
                Cylinder(diameter: 5.5, height: 3)
                    .translated(
                        x: StepperMotor.holeDistance / 2,
                        y: StepperMotor.holeDistance / 2,
                        z: 1 + stepperWallThickness
                    )
                    .symmetry(over: .xy)
                    .inBackground()
            }
            .rotated(y: 90°)
            .translated(x: stepperWallX - 1, z: stepperZCenter)

        // Slot the rail passes through
        Box(LinearRail.size + tolerance)
            .rotated(z: 90°)
            .aligned(at: .maxX, .centerY)
            .translated(
                x: Frame.outerPointDistance - Motion.railInset + tolerance - 0.001,
                z: stepperZCenter
            )

        // Nut trap and access hole for the rail's lower mounting screw
        let nutTrapDepth = railNutTrapBarSize + 2
        Box([Motion.railNutTrapThickness, Motion.railNutTrapWidth, nutTrapDepth])
            .aligned(at: .centerX, .centerY)
            .translated(z: -nutTrapDepth + Motion.railNutTrapWidth / 2)
            .adding {
                Circle(diameter: 3.5)
                    .overhangSafe(.bridge)
                    .extruded(height: railNutTrapBarSize + 10)
                    .translated(z: -10)
                    .rotated(y: 90°)
                    .rotated(x: -90°)
            }
            .translated(
                x: stepperWallX - railNutTrapBarSize / 2,
                z: Motion.railOffsetFromBottom + LinearRail.holeDistance / 2
            )

        Circle(diameter: LinearRail.holeHeadDiameter + 0.5)
            .overhangSafe(.bridge)
            .extruded(height: 10)
            .rotated(z: -90°)
            .rotated(y: 90°)
            .translated(
                x: stepperWallX,
                z: Motion.railOffsetFromBottom + LinearRail.holeDistance / 2
            )

        // Cable channel up into the corner cover, raked back so it prints without support
        Cylinder(diameter: CornerCover.cableChannelDiameter, height: height + 1)
            .sheared(.x, along: .z, angle: -15°)
            .translated(z: -topThickness - 0.01)
            .translated(.init(CornerCover.holeOffset))
            .symmetry(over: .y)
            .transformed(flippedTransform)

        // Wiring pass-through in the stepper wall
        Box([stepperWallThickness + 0.2, 12, 12])
            .aligned(at: .centerY, .maxX, .centerZ)
            .translated(x: 0.1)
            .translated(x: Frame.outerPointDistance - stepperWallInset, y: 27, z: 27)
            .symmetry(over: .y)

        // Corner cover's side mount screws
        Cylinder(diameter: CornerCover.mountHoleClearanceDiameter, height: height + 1)
            .translated(z: -topThickness - 0.01)
            .adding {
                Cylinder(diameter: CornerCover.mountHoleHeadDiameter, height: height)
            }
            .translated(.init(CornerCover.mountSideHoleOffset))
            .symmetry(over: .y)
            .transformed(flippedTransform)
    }
}
