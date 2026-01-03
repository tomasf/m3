import Foundation
import Cadova
import Helical

let baseWallThickness = 2.0
let baseTopThickness = 2.0
let baseHeight = 50.0
let baseTopChamferSize = 2.0

let stepperZCenter = 19.6
let stepperZFromTop = baseHeight - stepperZCenter - baseTopThickness - stepper.size.y / 2

let baseStepperWallThickness = 7.0
let baseStepperWallInset = 18.0


let baseInnerShape = baseShape.offset(amount: -baseWallThickness, style: .round)

let sideCoversShape = cornerCoverShape.repeated(count: 3)

let baseRailNutTrapBarSize = railNutTrapWidth + 1.0
let baseSensorBoardMountXOffset = -50.0

let baseFlippedTransform = Transform3D.rotation(x: 180°).translated(z: baseHeight - baseTopThickness)

let ledBoardSize = Vector3D(19.05, 15.05, 1.5)
let ledBoardHoleDiameter = 2.2
let ledBoardHolePilotDiameter = 2.0
let ledBoardHoleInset = 2.5
let ledBoardLEDSize = 5.0
let ledBoardLEDSpaceSize = 6.0
let ledBoardLEDXOffset = 6.5
let ledBoardLEDXCenter = 9.0
let ledBoardLEDThickness = 1.6
let ledBoardConnectorInset = 4.0
let ledBoardConnectorThickness = 5.5

let ledBoardCenterZ = 33.5
let baseFrontLEDDiameter = 3.0
let baseFrontLEDThickness = 0.4

let basePowerConnectorHoleDiameter = 7.8 + tolerance


let base = baseShape
    .extruded(height: baseHeight, topEdge: .chamfer(depth: baseTopChamferSize))
    .adding {
        // Don't chamfer corners
        sideCoversShape
            .extruded(height: baseHeight)
    }
    .subtracting {
        baseInnerShape.extruded(height: baseHeight - baseTopThickness + 1)
            .translated(z: -1)

        // Expose pulley area
        baseInnerShape
            .intersecting {
                Rectangle([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
                    .aligned(at: .left, .centerY)
                    .translated(x: distanceToOuterPoint - baseStepperWallInset)
                    .repeated(count: 3)
            }
            .extruded(height: baseTopThickness + 2)
            .translated(z: baseHeight - baseTopThickness - 1)
    }
    .adding {
        // Corner cover center mount holes
        let mountThickness = 3.0

        Circle(diameter: cornerCoverMountHoleClearanceDiameter + 2.5)
            .cloned {
                $0.translated(x: 100)
                $0.translated(y: 100)
            }
            .convexHull()
            .subtracting {
                Circle(diameter: cornerCoverMountHoleClearanceDiameter)
            }
            .translated(
                x: distanceToOuterPoint - cornerCoverMountCenterHoleInset,
                y: cornerCoverMountCenterHoleYOffset
            )
            .intersecting { baseShape }
            .extruded(height: mountThickness)
            .adding {
                Cylinder(diameter: 5.5, height: 2.2)
                    .translated(x: distanceToOuterPoint - cornerCoverMountCenterHoleInset,
                                y: cornerCoverMountCenterHoleYOffset,
                                z: -2.2)
                    .inBackground()
            }
            .translated(z: baseHeight - mountThickness)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
            .hidden()

        // Stepper motor wall
        Rectangle([baseStepperWallThickness, baseCircleDiameterEquivalent])
            .aligned(at: .centerY)
            .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness)
            .intersecting {
                baseShape
            }
            .extruded(height: baseHeight - baseTopThickness)
            .adding {
                Box(x: 1.0, y: 13, z: baseHeight / 2)
                    .aligned(at: .centerY)
                    .translated(x: distanceToOuterPoint - baseStepperWallInset, z: baseHeight / 2)

                // Rail nut trap bar
                Box([baseRailNutTrapBarSize, baseCircleDiameterEquivalent, baseRailNutTrapBarSize])
                    .aligned(at: .centerY, .maxX)
                    .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness)
                    .translated(z: baseHeight - baseTopThickness - baseRailNutTrapBarSize)
                    .intersecting {
                        baseShape.extruded(height: baseHeight)
                    }
            }
            .repeated(around: .z, count: 3)

        // Sensor board mount
        Box(BedSensorBoard.mountBarSize)
            .aligned(at: .centerXY)
            .subtracting {
                Cylinder(diameter: BedSensorBoard.mountBarHoleDiameter, height: BedSensorBoard.mountBarSize.z + 1)
                    .translated(x: BedSensorBoard.mountBarHoleDistance / 2, z: -1)
                    .symmetry(over: .x)
            }
            .rotated(z: 90°)
            .translated(x: baseSensorBoardMountXOffset)
            .transformed(baseFlippedTransform)

        // Duet mount
        let topHoleBarAngle = 30°
        let bottomHoleBarAngle = 180°
        let mountBarHeight = BedSensorBoard.fullHeight + 3.0
        let duetXOffset = -10.0

        Circle(diameter: Duet.screwPostDiameter)
            .cloned {
                $0.translated(x: baseCircleDiameterEquivalent).rotated(topHoleBarAngle)
            }
            .convexHull()
            .subtracting {
                Circle(diameter: Duet.screwPilotHoleDiameter)
            }
            .translated(Duet.size.xy / 2 - Duet.holeInset)
            .adding {
                Circle(diameter: Duet.screwPostDiameter)
                    .cloned {
                        $0.translated(x: baseCircleDiameterEquivalent).rotated(bottomHoleBarAngle)
                    }
                    .convexHull()
                    .subtracting {
                        Circle(diameter: Duet.screwPilotHoleDiameter)
                    }
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
            .transformed(baseFlippedTransform)
            .intersecting {
                baseInnerShape.extruded(height: baseHeight)
            }

        // Side rail
        let sideRailWidth = 7.0
        let sideRailHeight = 7.0
        let bottomShape = baseInnerShape
            .subtracting {
                Rectangle([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
                    .aligned(at: .centerY)
                    .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness)
                    .repeated(count: 3)
            }

        bottomShape
            .subtracting {
                bottomShape.offset(amount: -sideRailWidth, style: .round)
            }
            .extruded(height: sideRailHeight)
            .transformed(baseFlippedTransform)

        // Buttons
        let buttonHolePanelThickness = 2.5
        let buttonMaxDiameter = 16.5 + 1.0

        Cylinder(diameter: buttonMaxDiameter, height: buttonHolePanelThickness)
            .aligned(at: .centerZ)
            .adding {
                Cylinder(diameter: buttonMaxDiameter, height: 0.01)
                    .translated(x: buttonHolePanelThickness / 2)
            }
            .convexHull()
            .rotated(y: -90°)
            .translated(x: outerShapeWidth - baseWallThickness / 2)
            .repeated(around: .z, in:-12°...12°, count: 5)
            .rotated(z: 180°)
            .translated(x: distanceToEdgePivot, z: 17)

        // LED board
        Rectangle(x: ledBoardSize.x, y: ledBoardSize.y)
            .adding {
                Rectangle(x: ledBoardSize.x, y: 3)
                    .translated(y: ledBoardSize.y)
            }
            .translated(x: -ledBoardSize.x / 2, y: -ledBoardSize.y / 2)
            .subtracting {
                Circle(diameter: ledBoardHolePilotDiameter)
                    .translated(x: -ledBoardSize.x / 2 + ledBoardHoleInset, y: -ledBoardSize.y / 2 + ledBoardHoleInset)
                    .symmetry(over: .y)

                Rectangle([ledBoardLEDSpaceSize, ledBoardLEDSpaceSize])
                    .aligned(at: .center)
                    .hidden()

                Rectangle([ledBoardConnectorInset + 1, ledBoardSize.y + 2])
                    .aligned(at: .centerY)
                    .translated(x: ledBoardSize.x / 2 - ledBoardConnectorInset)
            }
            .translated(x: ledBoardSize.x / 2 - ledBoardLEDXCenter)
            .extruded(height: ledBoardConnectorThickness + baseWallThickness)
            .rotated(z: 90°)
            .rotated(y: 90°)
            .translated(x: -distanceToEdge, z: ledBoardCenterZ)
            .intersecting {
                baseShape.extruded(height: baseHeight)
            }

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
            .translated(x: outerShapeWidth - Bottom.mountSideInset)
            .rotated(z: 180° + Bottom.mountSideAnglularOffset)
            .translated(x: distanceToEdgePivot)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
            .intersecting {
                baseShape.extruded(height: baseHeight)
            }

        // Zip tie handles
        let zipTieHandleWidth = 4.0
        let zipTieHandleThickness = 6.0
        let zipTieHandleLength = 7.0
        let zipTieSupportThickness = 2.0
        let topZ = 37.0

        Box([zipTieHandleLength, zipTieHandleWidth, zipTieHandleThickness - zipTieHandleWidth / 2])
            .aligned(at: .centerY, .maxX, .maxZ)
            .adding {
                Cylinder(diameter: zipTieHandleWidth, height: zipTieHandleLength)
                    .rotated(y: -90°)

                Box([zipTieSupportThickness, zipTieHandleWidth, baseHeight - topZ])
                    .aligned(at: .minX, .centerY, .minZ)
                    .translated(x: -zipTieHandleLength)
            }
            .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness + 0.01, y: 25, z: topZ)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)

        // Steppers and pulleys
        let pulley = Pulley()
        stepper
            .colored(.darkGray, alpha: 0.3)
            .adding {
                pulley
                    .translated(z: stepper.size.z + stepper.shaftLength - pulley.length)
            }
            .rotated(y: 90°)
            .aligned(at: .top)
            .translated(x: -stepper.size.z)
            .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness)
            .translated(z: baseHeight - stepperZFromTop)
            .repeated(around: .z, count: 3)
            .colored(.gray, alpha: 0.2)
            .inBackground()
    }
    .subtracting {
        Union {
            // Holes in stepper motor wall
            Circle(diameter: stepper.circleDiameter + 1)
                .overhangSafe(.bridge)
                .rotated(-90°)
                .adding {
                    Circle(diameter: stepper.holeDiameter + 0.5)
                        .overhangSafe(.bridge)
                        .rotated(-90°)
                        .distributed(at: [-stepper.holeDistance / 2, stepper.holeDistance / 2], along: .x)
                        .translated(y: stepper.holeDistance / 2)
                        .symmetry(over: .y)
                }
                .extruded(height: baseStepperWallThickness + 2)
                .adding {
                    Cylinder(diameter: 5.5, height: 3)
                        .translated(x: stepper.holeDistance / 2, y: stepper.holeDistance / 2, z: 1 + baseStepperWallThickness)
                        .symmetry(over: .xy)
                        .inBackground()
                }
                .rotated(y: 90°)
                .translated(
                    x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness - 1,
                    z: stepperZCenter
                )

            // Cutout for rail
            Box(rail.size + tolerance)
                .rotated(z: 90°)
                .aligned(at: .maxX, .centerY)
                .translated(x: distanceToOuterPoint - railInset + tolerance - 0.001, z: stepperZCenter)

            // Nut trap for rail
            let depth = baseRailNutTrapBarSize + 2
            Box([railNutTrapThickness, railNutTrapWidth, depth])
                .aligned(at: .centerX, .centerY)
                .translated(z: -depth + railNutTrapWidth / 2)
                .adding {
                    Circle(diameter: 3.5)
                        .overhangSafe(.bridge)
                        .extruded(height: baseRailNutTrapBarSize + 10)
                        .translated(z: -10)
                        .rotated(y: 90°)
                        .rotated(x: -90°)
                }
                .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness - baseRailNutTrapBarSize / 2, z: railOffsetFromBottom + rail.holeDistance / 2)

            Circle(diameter: rail.holeHeadDiameter + 0.5)
                .overhangSafe(.bridge)
                .extruded(height: 10)
                .rotated(z: -90°)
                .rotated(y: 90°)
                .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness, z: railOffsetFromBottom + rail.holeDistance / 2)

            // Cable channel holes
            Cylinder(diameter: cornerCoverCableChannelDiameter, height: baseHeight + 1)
                .sheared(.x, along: .z, angle: -15°)
                .translated(z: -baseTopThickness - 0.01)
                .translated(.init(cornerCoverHoleOffset))
                .symmetry(over: .y)
                .transformed(baseFlippedTransform)

            Box([baseStepperWallThickness + 0.2, 12, 12])
                .aligned(at: .centerY, .maxX, .centerZ)
                .translated(x: 0.1)
                .translated(x: distanceToOuterPoint - baseStepperWallInset, y: 27, z: 27)
                .symmetry(over: .y)

            Cylinder(diameter: cornerCoverMountHoleClearanceDiameter, height: baseHeight + 1)
                .translated(z: -baseTopThickness - 0.01)
                .adding {
                    Cylinder(diameter: cornerCoverMountHoleHeadDiameter, height: baseHeight)
                }
                .translated(.init(cornerCoverMountSideHoleOffset))
                .symmetry(over: .y)
                .transformed(baseFlippedTransform)
        }
        .repeated(around: .z, count: 3)

        // Buttons
        let buttonHoleDiameter = 15 + tolerance - 0.1
        Circle(diameter: buttonHoleDiameter)
            .overhangSafe(.bridge)
            .subtracting {
                Rectangle([1.5 - tolerance, 1.0 - tolerance])
                    .aligned(at: .centerX)
                    .translated(y: -buttonHoleDiameter / 2)
            }
            .rotated(90°)
            .extruded(height: baseWallThickness + 2)
            .rotated(y: -90°)
            .translated(x: outerShapeWidth + 1)
            .repeated(around: .z, in:-12°...12°, count: 5)
            .rotated(z: 180°)
            .translated(x: distanceToEdgePivot, z: 17)

        // LED
        Circle(diameter: 3.0)
            .extruded(height: baseWallThickness)
            .adding {
                Box([ledBoardLEDSpaceSize, ledBoardLEDSpaceSize, ledBoardLEDThickness])
                    .aligned(at: .centerXY, .maxZ)
                    .translated(z: ledBoardConnectorThickness + baseWallThickness + 0.01)
            }
            .convexHull()
            .rotated(y: 90°)
            .translated(x: -distanceToEdge, z: ledBoardCenterZ)
            .intersecting {
                baseShape.offset(amount: -baseFrontLEDThickness, style: .round).extruded(height: baseHeight)
            }

        // Power connector
        Circle(diameter: basePowerConnectorHoleDiameter)
            .overhangSafe(.bridge)
            .rotated(-90°)
            .extruded(height: baseWallThickness + 2)
            .rotated(y: 90°)
            .translated(x: outerShapeWidth - baseWallThickness - 1)
            .rotated(z: 180° + 14°)
            .translated(x: distanceToEdgePivot, z: 15)
            .rotated(z: 120°)

        // Bottom mount
        Cylinder(diameter: Bottom.mountPilotHoleDiameter, height: Bottom.mountPilotHoleDepth + 1)
            .translated(
                x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness / 2,
                y: Bottom.mountStepperWallYOffset,
                z: -1
            )
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
    }
    .adding(Bed())

