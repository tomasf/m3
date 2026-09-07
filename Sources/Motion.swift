import Cadova
import Helical

/// The linear motion system: one vertical rail per tower, the carriage that rides it, and the
/// belt loop that drives it.
enum Motion {
    /// Spacing between the two parallel arm rods of a tower.
    static let rodSpacing = 40.0

    static let railInset = Base.stepperWallInset - LinearRail.size.y + Base.stepperWallThickness
    static let railOffsetFromBottom = 35.0

    /// How far the carriage's outward-facing mounting surface sits in from the corner point.
    /// Both the belt line and the delta radius are measured from here.
    static let carriageFaceInset = railInset + LinearRail.size.y
        - LinearRailCarriage.offsetFromRail
        - LinearRailCarriage.size.z

    // MARK: - Rail nut trap

    // The rail is clamped by thin M3 square nuts captured in the base and the top.
    private static let railNut = Nut.standardDimensionsForSquareNut(.m3, series: .thin)
    static let railNutTrapWidth = railNut.width + 0.5
    static let railNutTrapThickness = railNut.thickness + 0.5

    // MARK: - Belts

    static let beltPairSpacing = 12.0

    /// Distance in from the corner point to the center of the belt run.
    static let beltCenterInset = carriageFaceInset - Carriage.baseThickness - Carriage.beltWidth / 2
    /// The same line expressed as an absolute X coordinate, for placing belts in assemblies.
    static let beltCenterX = Frame.outerPointDistance - carriageFaceInset
        + Carriage.size.z
        - Carriage.beltWidth / 2
    /// Offset from the belt pair's center line to the inner belt's center.
    static let beltInnerYOffset = beltPairSpacing / 2 - (Carriage.beltThickness - Carriage.beltBackThickness)
}

/// Delta kinematics: how far the towers stand from the center, and how long the arms have to be
/// to cover the bed.
enum Kinematics {
    /// Horizontal distance from the machine's center line to a carriage's arm pivot.
    static let deltaRadius = Frame.outerPointDistance - Motion.carriageFaceInset
        + Carriage.armMountBaseDiameter / 2
        - Carriage.armMountDepthOffset
        - Effector.armOffset

    /// The bed radius actually reachable by the nozzle, inside the physical bed edge.
    static let usableBedRadius = Bed.diameter / 2 - 20

    static let armLength = 140.0

    /// Steepest angle an arm may make with horizontal before the joints bind.
    static let maxArmAngle = 70°
    /// The shortest arm that still reaches the edge of the usable bed at `maxArmAngle`.
    static let minArmLength = (deltaRadius + usableBedRadius) / sin(maxArmAngle)
}
