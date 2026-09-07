import Cadova

/// The shroud that encloses a tower between the base and the top. It hides the belt run and the
/// rail, and routes the tower's wiring up through an internal channel.
struct CornerCover: Geometry3D {
    /// Thickness of the outer shell where it follows the frame profile.
    static let shellThickness = 2.0
    /// Thickness of the internal channel walls.
    static let wallThickness = 2.0
    static let bottomThickness = 1.2

    /// The gap the tower leaves for the carriage and its arms to sweep through.
    static let carriageSpaceBackWidth = Motion.rodSpacing + 12

    /// Height of the cover as fitted: whatever the rail leaves exposed between base and top.
    static let standardHeight = LinearRail.size.z
        - (Base.height - Motion.railOffsetFromBottom)
        - Top.height
        - 1

    // MARK: - Cable channel and mounts

    static let cableChannelDiameter = 9.0
    static let holeOffset = Vector2D(Frame.outerPointDistance - 22, 32)
    static let mountSideHoleOffset = Vector2D(Frame.outerPointDistance - 28.2, 32)
    static let mountCenterHoleInset = 6.5
    static let mountCenterHoleYOffset = 10.5
    static let mountCenterHolePilotDepth = 10.0 - Base.topThickness
    static let mountHolePilotDiameter = 2.7
    static let mountHoleClearanceDiameter = 3.1
    static let mountHoleHeadDiameter = 6.0

    // MARK: - Profiles
    //
    // The cover is drawn as a set of 2D profiles, all derived from the frame's corner wedge, and
    // extruded at the end. `solidShape` is the footprint it occupies; `shape` is what actually
    // gets printed once the channel and the belt gap are taken out of it.

    /// The shell wall itself: the corner wedge minus everything inboard of the frame profile.
    static let wallShape = Frame.cornerShape
        .subtracting {
            Frame.shape.offset(amount: -shellThickness, style: .round)
        }

    /// The corner wedge with the carriage's sweep and the bed's footprint taken out, leaving the
    /// solid area the cover is allowed to occupy.
    static let solidShape = Frame.cornerShape
        .subtracting {
            Rectangle([Effector.armOffset + Kinematics.deltaRadius, carriageSpaceBackWidth + 3])
                .aligned(at: .centerY)
                .adding {
                    Circle(diameter: Bed.diameter + 2)
                }
                .convexHull()

            Rectangle([Effector.armOffset + Kinematics.deltaRadius + 6, carriageSpaceBackWidth + 2])
                .aligned(at: .centerY)

            Rectangle([Frame.circleDiameterEquivalent, Motion.rodSpacing - Carriage.armMountWidth + 2])
                .aligned(at: .centerY)
        }
        .whileMasked {
            // Round only the corner-side edges; the inboard ones stay sharp against the frame
            Rectangle([Frame.circleDiameterEquivalent, Frame.circleDiameterEquivalent])
                .aligned(at: .maxX, .centerY)
                .translated(x: Frame.outerPointDistance - 10)
        } do: {
            $0.rounded(radius: Frame.cornerRadius)
        }

    /// The hollow running up the inside of the cover that the tower's wiring passes through.
    static let innerChannelShape = solidShape
        .offset(amount: -wallThickness, style: .round)
        .subtracting {
            Circle(diameter: mountHolePilotDiameter + 3)
                .translated(mountSideHoleOffset)
                .symmetry(over: .y)
        }
        .rounded(radius: 1)

    /// The printed cross-section of the cover.
    static let shape = solidShape
        .adding {
            wallShape
        }
        .subtracting {
            innerChannelShape

            // Slot along the outer wall so the cover can spring over the frame
            let openSpaceWidth = 5.0
            Frame.cornerShape.offset(amount: -wallThickness, style: .round)
                .subtracting {
                    Frame.cornerShape.offset(amount: -openSpaceWidth - wallThickness, style: .round)
                }
                .intersecting {
                    Rectangle(x: 20, y: Motion.rodSpacing + 2 * wallThickness)
                        .aligned(at: .maxX, .centerY)
                        .translated(x: Frame.outerPointDistance)
                }
        }
        .rounded(radius: wallThickness / 2 - 0.01)
        .subtracting {
            Circle(diameter: mountHolePilotDiameter)
                .translated(mountSideHoleOffset)
                .symmetry(over: .y)
        }

    let height: Double

    var body: any Geometry3D {
        @Environment(\.tolerance) var tolerance

        Self.shape
            .extruded(height: height)
            .adding {
                Self.cornerMountBoss.hidden()
                Self.bottomPlate(tolerance: tolerance).hidden()
            }
            .subtracting {
                // Bottom shape
                Union {
                    // Open out the channel and mount holes through the bottom face
                    Self.shape.fillingHoles().subtracting { Self.shape }

                    // Rail
                    Rectangle(LinearRail.size.xy + tolerance)
                        .rotated(90°)
                        .aligned(at: .centerY, .maxX)
                        .translated(x: Frame.outerPointDistance - Motion.railInset + tolerance)

                    // Belts
                    let beltSlotDepth = Motion.railInset + LinearRail.size.y
                    Rectangle([beltSlotDepth, Carriage.beltThickness + 2])
                        .aligned(at: .maxX, .minY)
                        .adding {
                            Rectangle([beltSlotDepth, Carriage.beltThickness + tolerance])
                                .aligned(at: .maxX, .minY)
                        }
                        .translated(x: Carriage.beltWidth / 2 + 0.5)
                        .translated(x: Motion.beltCenterX, y: Motion.beltInnerYOffset - 1)
                        .symmetry(over: .y)
                }
                .rounded(radius: 1)
                .extruded(height: Self.mountCenterHolePilotDepth + 10)
                .translated(z: -1)
                .hidden()

                // Center mount holes
                Cylinder(diameter: Self.mountHolePilotDiameter, height: Self.mountCenterHolePilotDepth)
                    .translated(
                        x: Frame.outerPointDistance - Self.mountCenterHoleInset,
                        y: Self.mountCenterHoleYOffset,
                        z: -0.01
                    )
                    .symmetry(over: .y)
                    .hidden()
            }
    }

    /// A filleted boss at the corner point that takes the cover's center mount screws.
    private static var cornerMountBoss: any Geometry3D {
        let mountHoleMargin = 2.0
        let bossHeight = mountCenterHolePilotDepth + 0.8
        let innerRadius = Frame.cornerRoundingRadius - mountCenterHoleInset - mountHoleMargin

        return Circle(radius: Frame.cornerRoundingRadius)
            .subtracting {
                Circle(radius: innerRadius)
            }
            .intersecting { Arc(range: -50°..<50°, radius: Frame.cornerRoundingRadius - 1) }
            .translated(x: Frame.outerPointDistance - Frame.cornerRoundingRadius)
            .extruded(height: bossHeight)
            .subtracting {
                // TODO: 2025-08-02 — verify this still reads the profile the way it used to.
                // EdgeProfile.profile is the positive material, revolved here to cut a fillet
                // around the top of the boss.
                EdgeProfile.fillet(radius: 3.0).profile
                    .rotated(-90°)
                    .translated(x: innerRadius - 0.01)
                    .revolved()
                    .translated(
                        x: Frame.outerPointDistance - Frame.cornerRoundingRadius,
                        z: bossHeight + 0.01
                    )
            }
    }

    /// A floor closing the bottom of the cover, angled clear of the rail.
    private static func bottomPlate(tolerance: Double) -> any Geometry3D {
        Rectangle([Motion.railInset + LinearRail.size.y - tolerance, Frame.circleDiameterEquivalent])
            .aligned(at: .centerY, .maxX)
            .translated(x: Frame.outerPointDistance)
            .intersecting {
                Frame.cornerShape
            }
            .extruded(height: bottomThickness)
            .subtracting {
                // Rake the floor back out of the rail's way
                Box(Frame.circleDiameterEquivalent)
                    .aligned(at: .maxX, .centerY)
                    .rotated(y: 60°)
                    .translated(
                        x: Frame.outerPointDistance - Motion.railInset - LinearRail.size.y + tolerance
                    )
            }
    }
}
