import Cadova

/// The printer's outer profile: a rounded Reuleaux triangle shared by the base, the top, the
/// bottom plate and the corner covers.
///
/// The whole machine is laid out from `circleDiameterEquivalent`, the diameter of the circle the
/// triangle is derived from. Every other frame dimension is a fixed proportion of it, so the
/// printer can be scaled from this single number.
enum Frame {
    static let circleDiameterEquivalent = 250.0
    static let width = circleDiameterEquivalent * 0.9251
    static let cornerRoundingRadius = circleDiameterEquivalent * 0.1688

    /// From the center out to a corner, where the towers sit.
    static let outerPointDistance = circleDiameterEquivalent / 2
    /// From the center out to the center of curvature of an edge.
    static let edgePivotDistance = width / 3.0.squareRoot()
    /// From the center out to the midpoint of an edge, the closest point on the shell.
    static let edgeDistance = width - edgePivotDistance

    static let shape = ReuleauxTriangle(width: width)
        .rounded(radius: cornerRoundingRadius)

    // MARK: - Corners

    static let cornerInset = Base.stepperWallInset + 28
    static let cornerCircleDiameter = 94.0
    static let cornerRadius = 4.0

    /// The wedge of the footprint taken up by one corner assembly: the tower, its cover and the
    /// stepper behind it.
    static let cornerShape = shape
        .intersecting {
            Circle(diameter: cornerCircleDiameter)
                .aligned(at: .left, .centerY)
                .translated(x: outerPointDistance - cornerInset)
        }
        .rounded(radius: cornerRadius)
}
