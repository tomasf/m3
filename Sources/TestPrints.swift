import Cadova

/// Partial prints used to check a fit before committing to a full part. Each crops one part down
/// to the region actually being tested, so a corner or a mount can be printed in minutes.
enum TestPrint {
    /// The top's far roller holder, with enough of the surrounding shell to judge the blend.
    static var largeTopRollerHolder: any Geometry3D {
        Top()
            .intersecting {
                Box([150, 100, 100])
                    .translated(
                        x: Top.rollerXOffset - Top.rollerLength / 2 - 22,
                        y: Top.rollerYOffset - 14,
                        z: -1
                    )
            }
    }

    /// Just the bearing pocket of the top's far roller holder.
    static var topRollerHolder: any Geometry3D {
        Top()
            .intersecting {
                Box([33, 33, 100])
                    .translated(
                        x: Top.rollerXOffset + Top.rollerLength / 2 - 4,
                        y: Top.rollerYOffset - 16,
                        z: 0
                    )
            }
    }

    /// One corner of the top, to check the cover recess and the tower cutouts.
    static var topCorner: any Geometry3D {
        Top()
            .intersecting {
                Box([100, 79, 100])
                    .aligned(at: .centerY)
                    .translated(x: 78, z: -1)
            }
    }

    /// The very tip of a top corner, for checking the corner cover's mount alone.
    static var smallTopCorner: any Geometry3D {
        Top()
            .intersecting {
                Box([29.5, 25, 100])
                    .aligned(at: .maxX, .centerY)
                    .translated(x: Frame.outerPointDistance, z: -1)
            }
    }

    /// One corner of the base, to check the rail slot and the stepper wall.
    static var baseCorner: any Geometry3D {
        Base()
            .intersecting {
                Box([
                    Frame.circleDiameterEquivalent,
                    Frame.circleDiameterEquivalent,
                    Frame.circleDiameterEquivalent
                ])
                .aligned(at: .centerY)
                .translated(x: Frame.outerPointDistance - 35.5, z: -1)
            }
    }

    /// A slice of the base's front panel, to check the button and LED openings.
    static var baseFront: any Geometry3D {
        Base()
            .intersecting {
                Box([10, 70, 37])
                    .aligned(at: .centerY)
                    .translated(x: -Frame.edgeDistance - 2, z: 6)
            }
    }
}
