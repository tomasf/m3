import Foundation
import SwiftSCAD
import Helical

let tolerance = 0.3

let baseCircleDiameterEquivalent = 250.0
let outerShapeWidth = baseCircleDiameterEquivalent * 0.9251
let outerShapeCornerRoundingRadius = baseCircleDiameterEquivalent * 0.1688
let baseShape = ReuleauxTriangle(width: outerShapeWidth)
    .rounded(amount: outerShapeCornerRoundingRadius)

let distanceToOuterPoint = baseCircleDiameterEquivalent / 2
let distanceToEdgePivot = outerShapeWidth / 3.0.squareRoot()
let distanceToEdge = outerShapeWidth - outerShapeWidth / 3.0.squareRoot()

let rodSpacing = 40.0

let rail = LinearRail()
let railInset = baseStepperWallInset - rail.size.y + baseStepperWallThickness
let railOffsetFromBottom = 35.0

let railCarriage = LinearRailCarriage()

let stepper = StepperMotor()

let squareNutDimensions = Nut.standardDimensionsForSquaredNut(.m3, series: .thin)
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
        .background()
}

let baseContents = Duet()
    .disabled()
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
            .background()
        //.hidden()
    }

save(to: "~/Desktop/m3", environment: .defaultEnvironment.withTolerance(tolerance)) {
    let top = Top()

    top
        .forceRendered()
        .named("top")

    top.topCover
        .named("top-cover")

    top.topCoverWithCableOutlet
        .named("top-cover-with-outlet")

    top.handleCover
        .named("handle-cover")

    top.rollerHolderCover
        .named("top-roller-holder-cover")

    top
        .intersection {
            Box([150, 100, 100])
                .translated(
                    x: topRollerXOffset - topRollerLength / 2 - 22,
                    y: topRollerYOffset - 14,
                    z: -1
                )
        }
        .forceRendered()
        .named("top-roller-holder-prototype-large")

    top
        .intersection {
            Box([33, 33, 100])
                .translated(
                    x: topRollerXOffset + topRollerLength / 2 - 4,
                    y: topRollerYOffset - 16,
                    z: 0
                )
        }
        .named("top-roller-holder-prototype")

    top
        .intersection {
            Box([100, 79, 100])
                .aligned(at: .centerY)
                .translated(z: -1)
                .translated(x: 78)
        }
        .named("top-corner-prototype")

    carriageBody
        .named("carriage")

    carriageCover
        .named("carriage-cover")

    base
        .named("base")

    baseWithSides
        .adding {
            cornerCover
                .repeated(around: .z, count: 3)
                .translated(z: baseHeight)
            //.disabled()

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
                .forceRendered()
                .disabled()

            Cylinder(diameter: Bed.diameter, height: 1)
                .translated(z: baseHeight)

            Cylinder(radius: Effector.armOffset, height: 2)
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
    //.forceRendered()
        .named("printer")

    base
        .forceRendered()
        .rotated(x: 180°)
        .translated(z: baseHeight)
        .adding {
            baseContents
                .translated(z: baseTopThickness)
                .forceRendered()
            Bottom()
                .translated(z: baseHeight)
                .forceRendered()
                .colored(.beige, alpha: 0.5)
        }
    //.crossSectioned(axis: .y)
        .adding {
            Bottom().rotated(x: 180°).translated(x: 300)
        }
        .named("base-contents")

    base
        .intersection {
            Box([baseCircleDiameterEquivalent, baseCircleDiameterEquivalent, baseCircleDiameterEquivalent])
                .aligned(at: .centerY)
                .translated(x: distanceToOuterPoint - 35.5, z: -1)
        }
        .named("base-corner-test")

    baseWithSides
        .adding {
            CornerCover(height: 1)
                .translated(z: baseHeight)
                .colored(.lightBlue)
        }
        .named("base-with-sides")

    CornerCover(height: 10.0)
        .named("corner-cover-flat")
    /*
     base
     .intersection {
     Cylinder(diameter: 45, height: 100)
     .translated(z: -1)
     .translated(x: 52)
     }
     .aligned(at: .centerXY)
     .translated(z: -baseHeight)
     .rotated(x: 180°)
     .adding {
     Bed.sensorCover.translated(x: 40)
     }
     .save(to: "~/Desktop/m3/sensor-prototype")
     */

    Bed.sensorCover
        .named("sensor-cover")

    base
        .intersection {
            Box([10, 70, 37])
                .aligned(at: .centerY)
                .translated(x: -distanceToEdge - 2, z: 6)
        }
        .named("front-prototype")

    idler
        .named("idler")

    endstopBoard
        .named("endstop-board")

    cornerCover
        .named("corner-cover")

    railCover
        .named("rail-cover")

    RailCover(length: 50)
        .named("rail-cover-test-50")

    CornerCover(height: 50)
        .named("corner-cover-50")

    Roller(length: topRollerLength - 1.0)
        .named("roller")

    Bottom()
        .named("bottom")

    baseCornerShape
        .named("base-corner-shape")

    let effector = Effector()
    effector
        .forceRendered()
        .named("effector")

    effector.base
        .forceRendered()
        .named("effector-base")

    effector.base
        .adding {
            Box([8, 40, 0.2])
                .aligned(at: .minX, .centerY)
                .translated(x: Effector.armOffset + Effector.thickness / 2)
                .repeated(around: .z, count: 3)
        }
        .forceRendered()
        .named("effector-base-brim")

    effector.top
        .forceRendered()
        .named("effector-top")

    effector.fanDuct
        .forceRendered()
        .named("effector-fan-duct")

    ArmJig()
        .withTolerance(0.15)
        .named("arm-jig")
}

