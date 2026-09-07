import Foundation
import Cadova
import Helical

let tolerance = 0.3

let baseCircleDiameterEquivalent = 250.0
let outerShapeWidth = baseCircleDiameterEquivalent * 0.9251
let outerShapeCornerRoundingRadius = baseCircleDiameterEquivalent * 0.1688
let baseShape = ReuleauxTriangle(width: outerShapeWidth)
    .rounded(radius: outerShapeCornerRoundingRadius)

let distanceToOuterPoint = baseCircleDiameterEquivalent / 2
let distanceToEdgePivot = outerShapeWidth / 3.0.squareRoot()
let distanceToEdge = outerShapeWidth - outerShapeWidth / 3.0.squareRoot()

let rodSpacing = 40.0

let rail = LinearRail()
let railInset = baseStepperWallInset - rail.size.y + baseStepperWallThickness
let railOffsetFromBottom = 35.0

let railCarriage = LinearRailCarriage()

let stepper = StepperMotor()

let squareNutDimensions = Nut.standardDimensionsForSquareNut(.m3, series: .thin)
let railNutTrapWidth = squareNutDimensions.width + 0.5
let railNutTrapThickness = squareNutDimensions.thickness + 0.5

let idler = Idler()
let endstopBoard = EndstopBoard()

let deltaRadius = distanceToOuterPoint - railInset - rail.size.y + railCarriage.offsetFromRail + railCarriage.size.z + carriageArmMountBaseDiameter / 2 - carriageArmMountDepthOffset - Effector.armOffset

let usableBedRadius = Bed.diameter / 2 - 20

let armLength = 140.0
let minArmLength = (deltaRadius + usableBedRadius) / sin(70°)
print("minArmLength: \(minArmLength)")
print("deltaRadius: \(deltaRadius)")
print("usableBedRadius: \(usableBedRadius)")
print("cornerCoverHeight: \(cornerCoverHeight)")


let beltCenterX = distanceToOuterPoint - railInset - rail.size.y + railCarriage.offsetFromRail + railCarriage.size.z + carriageSize.z - carriageBeltWidth / 2

let beltInnerYOffset = 12.0 / 2 - (carriageBeltThickness - carriageBeltBackThickness)

print(Bundle.main.bundlePath)

let baseWithSides = base.adding {
    rail
        .colored(.gray)
        .adding {
            railCarriage
                .colored(.red)
                .adding {
                    carriageBody
                        .colored(.orange)
                        .rotated(z: -90°)
                        .translated(z: railCarriage.size.z)
                }
                .translated(z: railCarriage.offsetFromRail)
                .rotated(y: -90°, z: 90°)
                .translated(y: rail.size.y, z: 145) //65// 240
        }
        .rotated(z: 90°)
        .translated(
            x: distanceToOuterPoint - railInset,
            z: railOffsetFromBottom
        )
        .adding {
            // Belts
            Box([6.0, carriageBeltThickness, 300])
                .aligned(at: .centerX)
                .translated(y: beltInnerYOffset)
                .symmetry(over: .y)
                .translated(x: beltCenterX, z: stepperZCenter)
                .colored(.black)
        }
        .repeated(around: .z, count: 3)
        .inBackground()
}

let baseContents = Duet()
    .rotated(z: 0°)
    .translated(x: -26)
    .adding {
        let pulley = Pulley()
        stepper
            .colored(.darkGray, alpha: 0.3)
            .adding {
                pulley
                    .translated(z: stepper.size.z + stepper.shaftLength - pulley.length)
            }
            .rotated(y: 90°)
            .aligned(at: .bottom)
            .translated(x: -stepper.size.z)
            .translated(x: distanceToOuterPoint - baseStepperWallInset - baseStepperWallThickness)
            .translated(z: stepperZFromTop)
            .repeated(around: .z, count: 3)
            .inBackground()
    }


await Project(packageRelative: "Models") {
    Metadata(
        title: "m3",
        description: "A small delta printer.",
        author: "Tomas Wincent Franzén",
        license: "MIT"
    )

    Environment {
        $0.tolerance = tolerance
    }

    let top = Top()

    await Model("top") {
        top
    }

    await Model("top-cover") {
        top.topCover
    }

    await Model("top-cover-with-outlet") {
        top.topCoverWithCableOutlet
    }

    await Model("handle-cover") {
        top.handleCover
    }

    await Model("top-roller-holder-cover") {
        top.rollerHolderCover
    }

    await Model("top-roller-holder-prototype-large") {
        top
            .intersecting {
                Box([150, 100, 100])
                    .translated(
                        x: topRollerXOffset - topRollerLength / 2 - 22,
                        y: topRollerYOffset - 14,
                        z: -1
                    )
            }
    }

    await Model("top-roller-holder-prototype") {
        top
            .intersecting {
                Box([33, 33, 100])
                    .translated(
                        x: topRollerXOffset + topRollerLength / 2 - 4,
                        y: topRollerYOffset - 16,
                        z: 0
                    )
            }
    }

    await Model("top-corner-prototype") {
        top
            .intersecting {
                Box([100, 79, 100])
                    .aligned(at: .centerY)
                    .translated(z: -1)
                    .translated(x: 78)
            }
    }

    await Model("top-corner-prototype-small") {
        top
            .intersecting {
                Box([29.5, 25, 100])
                    .aligned(at: .maxX, .centerY)
                    .translated(x: distanceToOuterPoint, z: -1)
            }
    }

    await Model("carriage") {
        carriageBody
            .aligned(at: .centerXY, .bottom)
            .colored(.aquamarine)
    }

    await Model("carriage-cover") {
        carriageCover
    }

    await Model("base") {
        base
            .rotated(x: 180°)
            .aligned(at: .centerXY, .bottom)
    }

    await Model("printer") {
        baseWithSides
            .adding {
                cornerCover
                    .repeated(around: .z, count: 3)
                    .translated(z: baseHeight)

                railCover
                    .rotated(z: -90°)
                    .translated(x: distanceToOuterPoint - railInset - rail.size.y - RailCover.centerThickness, z: baseHeight)
            }
            .rotated(x: 180°)
            .translated(z: baseHeight - baseTopThickness)
            .adding {
                baseContents
            }
            .translated(z: -baseHeight + baseTopThickness)
            .rotated(x: 180°)
            .adding {
                top
                    .translated(z: railOffsetFromBottom + rail.size.z - topHeight)

                Cylinder(diameter: Bed.diameter, height: 1)
                    .translated(z: baseHeight)

                Effector()
                    .rotated(z: 60°)
                    .adding {
                        Cylinder(diameter: 6, height: minArmLength)
                            .rotated(y: 90° - 20°)
                            .translated(x: Effector.armOffset, y: rodSpacing / 2)
                            .symmetry(over: .y)
                            .rotated(z: 180°)

                        Cylinder(diameter: 6, height: minArmLength)
                            .rotated(y: 90° - 62°)
                            .rotated(z: -57°)
                            .translated(x: Effector.armOffset)
                            .distributed(at: [rodSpacing / 2, -rodSpacing / 2], along: .y)
                            .rotated(z: 180° + 120°)
                    }
                    .colored(.lightBlue)
                    .translated(x: usableBedRadius, z: baseHeight + 3 + 20)
                    .rotated(z: 180°)
            }
        //.crossSectioned(axis: .y, cuttingAway: .negative)
    }

    await Model("base-contents") {
        base
            .rotated(x: 180°)
            .translated(z: baseHeight)
            .adding {
                baseContents
                    .translated(z: baseTopThickness)
                Bottom()
                    .translated(z: baseHeight)
                    .colored(.beige, alpha: 0.5)
            }
        //.crossSectioned(axis: .y)
            .adding {
                Bottom().rotated(x: 180°).translated(x: 300)
            }
    }

    await Model("base-corner-test") {
        base
            .intersecting {
                Box([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
                    .aligned(at: .centerY)
                    .translated(x: distanceToOuterPoint - 35.5, z: -1)
            }
    }

    await Model("base-with-sides") {
        baseWithSides
            .adding {
                CornerCover(height: 1)
                    .translated(z: baseHeight)
                    .colored(.lightBlue)
            }
    }

    await Model("corner-cover-flat") {
        CornerCover(height: 10.0)
    }

    await Model("sensor-cover") {
        Bed.sensorCover
    }

    await Model("front-prototype") {
        base
            .intersecting {
                Box([10, 70, 37])
                    .aligned(at: .centerY)
                    .translated(x: -distanceToEdge - 2, z: 6)
            }
    }

    await Model("effector") {
        Effector()
    }
}
