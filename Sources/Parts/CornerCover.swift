import Foundation
import Cadova
import Helical

let cornerCoverThickness = 2.0
let cornerCoverHeight = rail.size.z - (baseHeight - railOffsetFromBottom) - topHeight - 1

let cornerCarriageSpaceBackWidth = rodSpacing + 12
let baseCornerInset = baseStepperWallInset + 28
let baseCornerShapeCircleDiameter = 94.0

let baseCornerShape = baseShape
    .intersecting {
        Circle(diameter: baseCornerShapeCircleDiameter)
            .aligned(at: .left, .centerY)
            .translated(x: distanceToOuterPoint - baseCornerInset)
    }
    .rounded(radius: 4)

let cornerCoverWall = baseCornerShape
    .subtracting {
        baseShape.offset(amount: -cornerCoverThickness, style: .round)
    }

/*
 let cornerCoverHoleOffset = Vector2D(distanceToOuterPoint - 23.5, 32)
 let cornerCoverCableChannelDiameter = 10.0
 let cornerCoverMountSideHoleOffset = cornerCoverHoleOffset + [-6, 0]

 */

let cornerCoverHoleOffset = Vector2D(distanceToOuterPoint - 22, 32)
let cornerCoverCableChannelDiameter = 9.0
let cornerCoverMountSideHoleOffset = Vector2D(distanceToOuterPoint - 28.2, 32)
let cornerCoverMountCenterHoleInset = 6.5
let cornerCoverMountCenterHoleYOffset = 10.5
let cornerCoverMountCenterHolePilotDepth = 10.0 - baseTopThickness
let cornerCoverMountHolePilotDiameter = 2.7
let cornerCoverMountHoleClearanceDiameter = 3.1
let cornerCoverMountHoleHeadDiameter = 6.0

let cornerCoverShapeSolid = baseCornerShape
    .subtracting {
        Rectangle([Effector.armOffset + deltaRadius, cornerCarriageSpaceBackWidth + 3])
            .aligned(at: .centerY)
            .adding {
                Circle(diameter: Bed.diameter + 2)
            }
            .convexHull()

        Rectangle([Effector.armOffset + deltaRadius + 6, cornerCarriageSpaceBackWidth + 2])
            .aligned(at: .centerY)

        Rectangle([baseCircleDiameterEquivalent, rodSpacing - armMountWidth + 2])
            .aligned(at: .centerY)

    }
    .whileMasked {
        Rectangle([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
            .aligned(at: .maxX, .centerY)
            .translated(x: distanceToOuterPoint - 10)
    } do: {
        $0.rounded(radius: 4)
    }

let cornerCoverWallThickness = 2.0
let cornerCoverInnerChannelShape = cornerCoverShapeSolid
    .offset(amount: -cornerCoverWallThickness, style: .round)
    .subtracting {
        Circle(diameter: cornerCoverMountHolePilotDiameter + 3)
            .translated(cornerCoverMountSideHoleOffset)
            .symmetry(over: .y)
    }
    .rounded(radius: 1)

let cornerCoverShape = cornerCoverShapeSolid
    .adding {
        cornerCoverWall
    }
    .subtracting {
        cornerCoverInnerChannelShape

        let openSpaceWidth = 5.0
        baseCornerShape.offset(amount: -cornerCoverWallThickness, style: .round)
            .subtracting {
                baseCornerShape.offset(amount: -openSpaceWidth - cornerCoverWallThickness, style: .round)
            }
            .intersecting {
                Rectangle(x: 20, y: rodSpacing + 2*cornerCoverWallThickness)
                    .aligned(at: .maxX, .centerY)
                    .translated(x: distanceToOuterPoint)
            }
    }
    .rounded(radius: cornerCoverWallThickness / 2 - 0.01)
    .subtracting {
        Circle(diameter: cornerCoverMountHolePilotDiameter)
            .translated(cornerCoverMountSideHoleOffset)
            .symmetry(over: .y)
    }

struct CornerCover: Shape3D {
    let height: Double

    static let bottomThickness = 1.2

    var body: any Geometry3D {
        cornerCoverShape
            .extruded(height: height)
            .adding {
                let mountHoleMargin = 2.0
                let height = cornerCoverMountCenterHolePilotDepth + 0.8
                let circleRadius = outerShapeCornerRoundingRadius - cornerCoverMountCenterHoleInset - mountHoleMargin
                Circle(radius: outerShapeCornerRoundingRadius)
                    .subtracting {
                        Circle(radius: circleRadius)
                    }
                    .intersecting { Arc(range: -50°..<50°, radius: outerShapeCornerRoundingRadius - 1) }
                    .translated(x: distanceToOuterPoint - outerShapeCornerRoundingRadius)
                    .extruded(height: height)
                    .subtracting {
                        #warning("2025-08-02 double-check this")
                        EdgeProfile.fillet(radius: 3.0).profile
                            .rotated(-90°)
                            .translated(x: circleRadius - 0.01)
                            .revolved()
                            .translated(x: distanceToOuterPoint - outerShapeCornerRoundingRadius, z: height + 0.01)
                    }
                    .hidden()

                // Bottom
                Rectangle([railInset + rail.size.y - tolerance, baseCircleDiameterEquivalent])
                    .aligned(at: .centerY, .maxX)
                    .translated(x: distanceToOuterPoint)
                    .intersecting {
                        baseCornerShape
                    }
                    .extruded(height: Self.bottomThickness)
                    .subtracting {
                        Box([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
                            .aligned(at: .maxX, .centerY)
                            .rotated(y: 60°)
                            .translated(x: distanceToOuterPoint - railInset - rail.size.y + tolerance)
                    }
                    .hidden()
            }
            .subtracting {
                // Bottom shape
                Union {
                    // Subtract cover holes
                    cornerCoverShape.filled().subtracting { cornerCoverShape }

                    // Rail
                    Rectangle(rail.size.xy + tolerance)
                        .rotated(90°)
                        .aligned(at: .centerY, .maxX)
                        .translated(x: distanceToOuterPoint - railInset + tolerance)

                    // Belts
                    Rectangle([railInset + rail.size.y, carriageBeltThickness + 2])
                        .aligned(at: .maxX, .minY)
                        .adding {
                            Rectangle([railInset + rail.size.y, carriageBeltThickness + tolerance])
                                .aligned(at: .maxX, .minY)
                        }
                        .translated(x: carriageBeltWidth / 2 + 0.5)
                        .translated(x: beltCenterX, y: beltInnerYOffset - 1)
                        .symmetry(over: .y)
                }
                .rounded(radius: 1)
                .extruded(height: cornerCoverMountCenterHolePilotDepth + 10)
                .translated(z: -1)
                .hidden()

                // Center mount holes
                Cylinder(diameter: cornerCoverMountHolePilotDiameter, height: cornerCoverMountCenterHolePilotDepth)
                    .translated(x: distanceToOuterPoint - cornerCoverMountCenterHoleInset, y: cornerCoverMountCenterHoleYOffset, z: -0.01)
                    .symmetry(over: .y)
                    .hidden()
            }
    }
}

let cornerCover = CornerCover(height: cornerCoverHeight)
