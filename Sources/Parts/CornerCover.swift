import Foundation
import SwiftSCAD
import Helical

let cornerCoverThickness = 2.0
let cornerCoverHeight = rail.size.z - (baseHeight - railOffsetFromBottom) - topHeight - 1

let cornerCarriageSpaceBackWidth = rodSpacing + 12
let baseCornerInset = baseStepperWallInset + 28
let baseCornerShapeCircleDiameter = 96.0

let baseCornerShape = baseShape
    .intersection {
        Circle(diameter: baseCornerShapeCircleDiameter)
            .aligned(at: .left, .centerY)
            .translated(x: distanceToOuterPoint - baseCornerInset)
    }
/*
    .subtracting {
        Rectangle([baseCornerShapeCircleDiameter, baseCornerShapeCircleDiameter])
            .aligned(at: .maxX, .centerY)
            .translated(x: distanceToOuterPoint - 40)

    }
 */
    .rounded(amount: 4)

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
let cornerCoverMountSideHoleOffset = Vector2D(distanceToOuterPoint - 29, 32)
let cornerCoverMountCenterHoleInset = 6.5
let cornerCoverMountCenterHoleYOffset = 10.5
let cornerCoverMountCenterHolePilotDepth = 10.0 - baseTopThickness
let cornerCoverMountHolePilotDiameter = 2.7
let cornerCoverMountHoleClearanceDiameter = 3.1
let cornerCoverMountHoleHeadDiameter = 6.0

let cornerCoverShapeSolid = baseCornerShape
    .subtracting {
        Rectangle([Effector.armOffset + deltaRadius, cornerCarriageSpaceBackWidth + 2])
            .aligned(at: .centerY)
            .adding {
                Circle(diameter: Bed.diameter)
            }
            .convexHull()

        Rectangle([Effector.armOffset + deltaRadius + 6, cornerCarriageSpaceBackWidth + 2])
            .aligned(at: .centerY)

        Rectangle([baseCircleDiameterEquivalent, rodSpacing - armMountWidth + 2])
            .aligned(at: .centerY)

    }
    .rounded(amount: 4) {
        Rectangle([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
            .aligned(at: .maxX, .centerY)
            .translated(x: distanceToOuterPoint - 10)
    }

let cornerCoverInnerChannelShape = cornerCoverShapeSolid
    .offset(amount: -2, style: .round)
    .subtracting {
        Circle(diameter: cornerCoverMountHolePilotDiameter + 3)
            .translated(cornerCoverMountSideHoleOffset)
            .symmetry(over: .y)
    }
    .rounded(amount: 1)

let cornerCoverShape = cornerCoverShapeSolid
    .adding {
        cornerCoverWall
    }
    .subtracting {
        cornerCoverInnerChannelShape

        Circle(diameter: cornerCoverMountHolePilotDiameter)
            .translated(cornerCoverMountSideHoleOffset)
            .symmetry(over: .y)
    }

struct CornerCover: Shape3D {
    let height: Double

    static let bottomThickness = 1.2

    var body: Geometry3D {
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
                    .intersection { Arc(range: -50°..<50°, radius: outerShapeCornerRoundingRadius - 1) }
                    .translated(x: distanceToOuterPoint - outerShapeCornerRoundingRadius)
                    .extruded(height: height)
                    .subtracting {
                        EdgeProfile.fillet(radius: 3.0).shape()
                            .rotated(-90°)
                            .translated(x: circleRadius - 0.01)
                            .extruded()
                            .translated(x: distanceToOuterPoint - outerShapeCornerRoundingRadius, z: height + 0.01)
                    }

                // Bottom
                Rectangle([railInset + rail.size.y - tolerance, baseCircleDiameterEquivalent])
                    .aligned(at: .centerY, .maxX)
                    .translated(x: distanceToOuterPoint)
                    .intersection {
                        baseCornerShape
                    }
                    .extruded(height: Self.bottomThickness)
                    .subtracting {
                        Box([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
                            .aligned(at: .maxX, .centerY)
                            .rotated(y: 60°)
                            .translated(x: distanceToOuterPoint - railInset - rail.size.y + tolerance)
                    }
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
                    Rectangle([carriageBeltWidth, carriageBeltThickness + 2])
                        .aligned(at: .maxX, .minY)
                        .adding {
                            Rectangle([railInset + rail.size.y, carriageBeltThickness + tolerance])
                                .aligned(at: .maxX, .minY)
                        }
                        .translated(x: carriageBeltWidth / 2 + 0.5)
                        .translated(x: beltCenterX, y: beltInnerYOffset - 1)
                        .symmetry(over: .y)
                }
                .extruded(height: cornerCoverMountCenterHolePilotDepth + 10)
                .translated(z: -1)

                // Center mount holes
                Cylinder(diameter: cornerCoverMountHolePilotDiameter, height: cornerCoverMountCenterHolePilotDepth)
                    .translated(x: distanceToOuterPoint - cornerCoverMountCenterHoleInset, y: cornerCoverMountCenterHoleYOffset, z: -0.01)
                    .symmetry(over: .y)
            }
    }
}

let cornerCover = CornerCover(height: cornerCoverHeight)
