import Foundation
import Cadova
import Helical

/// The moving platform at the meeting point of the three arm pairs. It carries the hotend, the
/// extruder above it, and the part-cooling fan, and splits into a printed `base` and `top` so both
/// halves print without support.
struct Effector: Geometry3D {
    static let thickness = 7.0
    static let armOffset = 29.0
    static let armWidth = Carriage.armMountWidth

    // MARK: - Arm mounts

    static let mountBoltLength = 16.0
    static let mountHoleDiameter = 3.3
    static let mountNut = Nut.square(.m3, series: .thin)
    static let mountZ = thickness / 2

    // MARK: - Hotend
    //
    // An E3D Revo Micro, clamped by its M12 thread into the top half. Measured from the bottom of
    // the heater block; nozzle tip sits 21-22 mm below the effector's underside.

    static let hotendZOffset = 1.0
    static let hotendSpringDiameter = 9.0
    static let hotendHeatsinkDiameter = 20.0
    static let hotendFanDuctWidth = 25.0
    static let hotendFanDuctLength = 30.5
    static let hotendFanDuctOffset = -5.5

    /// Bottom of the hotend to its mounting face.
    static let hotendBodyHeight = 24.0
    static let hotendMountFullHeight = 25.0
    static let hotendMountThread = ScrewThread.isoMetric(.m12, pitch: 1.5)
    static let hotendMountThreadedLength = 8.0

    /// Where the base half ends and the top half begins.
    static let baseHeight = hotendZOffset + hotendBodyHeight
    static let topDiameter = hotendHeatsinkDiameter + 20

    // MARK: - Extruder

    // An LGX Lite, tipped back so the filament path stays straight into the hotend.
    static let hotendMountExtruderZOffset = 15.0
    static let hotendMountExtruderXOffset = 1.0
    static let hotendMountExtruderAngle = 25°
    static let hotendMountExtruderMountHoleOffsets: [Vector3D] = [
        [-12.2, 9.5, -2.2], [-12.2, -9.5, -2.2], [-2.2, 9.5, -8], [-2.2, -9.5, -8]
    ]
    static let extruderBolt = Bolt.hexSocketCountersunk(.m3, length: 8)
    /// The extruder mount bolts are driven at an angle, so their clearance needs extra room.
    static let extruderBoltTolerance = 0.4

    /// Screws holding the two halves together. Each is driven along its own skewed axis so the
    /// heads land on the top half's sloping outer surface.
    static let hotendMountTopScrewHoles: [MountBolt] = [
        .init(top: [6, 15, 2], direction: [-0.46, 0.2, -1]),
        .init(top: [-9, 16, 2], direction: [0.5, -0.17, -1])
    ]
    static let hotendMountTopScrewHoleDiameter = 2.6
    static let hotendMountTopScrewHoleDepth = 12.0
    static let hotendMountTopScrewPrototype = Bolt.hexSocketCountersunk(.m3, length: 13)

    /// A screw whose axis is neither vertical nor radial, given by the point its head sits at and
    /// the direction it is driven in.
    struct MountBolt {
        let top: Vector3D
        let direction: Vector3D
    }

    // MARK: - Part cooling

    static let cableSlitWidth = 3.5
    static let cableSlitDepth = 10.0

    static let fanSize = Vector3D(40.05, 40, 10.1)
    static let fanXOffset = -14.0
    /// Measured down from the effector's top surface.
    static let fanZOffset = -0.8
    static let fanHoleInset = 2.5
    static let fanMountHoleDiameter = 1.9
    static let fanMountHoleDepth = 10.0
    static let fanOutletSize = Vector2D(x: 27.8, y: 8.4)

    static let fanDuctMountHoleOffset = 18.0
    static let fanDuctMountHoleDiameter = 2.7
    static let fanDuctMountHoleDepth = thickness

    @Environment(\.tolerance) var tolerance

    var body: any Geometry3D {
        base

        fanDuct
            .rotated(y: 180°, z: -90°)
            .translated(x: Self.fanXOffset - Self.fanSize.z / 2)

        top
            .translated(z: Self.baseHeight + 0.01)

        // Arms, shown to check the sweep
        Cylinder(diameter: 6, height: 140)
            .rotated(y: 3°)
            .translated(x: Self.armOffset, y: Motion.rodSpacing / 2, z: Self.thickness / 2)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
            .inBackground()
            .hidden()
    }

    // MARK: - Outline

    /// The plan view of the effector: a triangle of arm mounts, filleted together, with a slit
    /// for the hotend's wiring.
    var footprint: any Geometry2D {
        Rectangle(x: Self.armOffset + Self.thickness / 2, y: Motion.rodSpacing - Self.armWidth)
            .aligned(at: .centerY)
            .adding {
                Rectangle(x: Self.armOffset - 4, y: 20)
                    .aligned(at: .centerY)
                    .rotated(60°)
            }
            .repeated(count: 3)
            .rounded(insideRadius: 16)
            .subtracting {
                Circle(diameter: Self.cableSlitWidth)
                    .cloned {
                        $0.translated(x: 30)
                    }
                    .convexHull()
                    .translated(
                        x: Self.armOffset + Self.thickness / 2 + Self.cableSlitWidth / 2 - Self.cableSlitDepth
                    )
                    .rotated(-120°)
            }
    }

    /// The effector's whole outer solid, before it is split into base and top. The revolved
    /// profile gives the tapered tower; the footprint trims it back to the arm triangle.
    var shape: any Geometry3D {
        let baseTop = Self.hotendZOffset + Self.hotendBodyHeight
        let top = baseTop + Self.hotendMountFullHeight

        let profile = BezierPath2D(startPoint: .zero)
            .addingLine(to: [0, top])
            .addingLine(to: [Self.topDiameter / 2, top])
            .addingCurve(
                [Self.topDiameter / 2, Self.thickness + 16],
                [Self.armOffset - 6, Self.thickness],
                [Self.armOffset, Self.thickness]
            )
            .addingLine(to: [Self.armOffset, 0])

        return Polygon(profile)
            .revolved()
            .intersecting { footprint.extruded(height: top) }
            .adding {
                footprint.extruded(height: Self.thickness)

                // Envelope the fan needs kept clear. Disabled by default.
                Box([
                    -Self.fanXOffset,
                    Self.fanSize.x,
                    Self.hotendZOffset + Self.hotendBodyHeight + Self.hotendMountFullHeight
                ])
                .aligned(at: .minX, .centerY)
                .translated(x: Self.fanXOffset)
                .hidden()
            }
            .subtracting {
                // Fan, and the pilot holes that hold it
                Box(Self.fanSize + .y(100) + tolerance)
                    .translated(-Self.fanSize.with(.z, as: 0) / 2)
                    .adding {
                        Cylinder(diameter: Self.fanMountHoleDiameter, height: Self.fanMountHoleDepth)
                            .aligned(at: .maxZ)
                            .translated(
                                x: -Self.fanSize.x / 2 + Self.fanHoleInset,
                                y: Self.fanSize.y / 2 - Self.fanHoleInset,
                                z: 0.01
                            )
                            .symmetry(over: .x)
                            .flipped(along: .y)
                    }
                    .rotated(x: 90°, z: -90°)
                    .aligned(at: .minZ)
                    .translated(x: Self.fanXOffset, z: Self.thickness + Self.fanZOffset)
            }
    }

    // MARK: - Base half

    @GeometryBuilder3D
    var base: any Geometry3D {
        shape
            .intersecting { Cylinder(diameter: 100, height: Self.baseHeight) }
            .subtracting {
                armMounts
                    .repeated(around: .z, count: 3)

                // Hotend bore, its retaining spring, and the duct around the heatsink
                Cylinder(bottomDiameter: 20, topDiameter: 12, height: 4)
                    .translated(z: -0.01)

                Cylinder(diameter: Self.hotendSpringDiameter, height: Self.thickness)
                    .translated(z: -1)

                Rectangle(x: Self.hotendFanDuctLength + tolerance, y: Self.hotendFanDuctWidth + tolerance)
                    .aligned(at: .centerY)
                    .translated(x: Self.hotendFanDuctOffset)
                    .adding {
                        Circle(diameter: Self.hotendHeatsinkDiameter + 2 + tolerance)
                    }
                    .rounded(radius: 1)
                    .extruded(height: Self.thickness + Self.hotendBodyHeight)
                    .translated(z: Self.hotendZOffset)

                // Part-cooling outlet and the duct's mounting holes
                Box([Self.fanOutletSize.y, Self.fanOutletSize.x, Self.thickness])
                    .aligned(at: .centerXY)
                    .translated(x: Self.fanXOffset - Self.fanSize.z / 2, z: -0.01)

                Cylinder(diameter: Self.fanDuctMountHoleDiameter, height: Self.fanDuctMountHoleDepth)
                    .translated(
                        x: Self.fanXOffset - Self.fanSize.z / 2,
                        y: Self.fanDuctMountHoleOffset,
                        z: -0.01
                    )
                    .symmetry(over: .y)

                // Keep the air paths in front of both fans clear
                Box(Self.fanSize + tolerance)
                    .rotated(x: 90°, z: -90°)
                    .aligned(at: .maxX, .centerY)
                    .translated(x: Self.fanXOffset - 5, z: Self.thickness)

                Box([20, 25 + tolerance, 20])
                    .aligned(at: .minX, .centerY)
                    .translated(x: Self.hotendFanDuctLength + Self.hotendFanDuctOffset - 1, z: Self.thickness)

                // Vents letting the hotend's own fan exhaust
                Box([50, 3, 10])
                    .aligned(at: .centerY)
                    .rotated(z: 180° - 55°)
                    .translated(z: Self.thickness + 5)
                    .symmetry(over: .y)

                Cylinder(diameter: 3, height: 50)
                    .rotated(y: -90° - 48°)
                    .repeated(around: .z, in: -50°...50°, count: 5)
                    .translated(z: 14.0)

                // Pilot holes for the screws coming down from the top half
                for mountPoint in Self.hotendMountTopScrewHoles {
                    Cylinder(
                        diameter: Self.hotendMountTopScrewHoleDiameter,
                        height: Self.hotendMountTopScrewHoleDepth
                    )
                    .transformed(.rotation(from: .up, to: Direction3D(mountPoint.direction)))
                    .translated(mountPoint.top)
                    .translated(z: Self.baseHeight)
                    .symmetry(over: .y)
                }
            }
            .adding {
                revoMicro
                    .inBackground()
            }
    }

    /// One arm pair's mount: a through bolt with a captive nut at each end, and a fillet blending
    /// the mount into the platform.
    @GeometryBuilder3D
    private var armMounts: any Geometry3D {
        // TODO: 2025-08-02 — double-check this against the current EdgeProfile semantics.
        EdgeProfile.fillet(radius: Self.thickness / 2).profile
            .extruded(height: Motion.rodSpacing)
            .rotated(x: 90°)
            .rotated(y: 180°)
            .aligned(at: .centerY)
            .translated(x: Self.armOffset + Self.thickness / 2 + 0.01, z: Self.thickness + 0.01)

        Circle(diameter: Self.mountHoleDiameter)
            .overhangSafe(.bridge)
            .extruded(height: Motion.rodSpacing)
            .rotated(x: 90°)
            .aligned(at: .centerY)
            .translated(x: Self.armOffset, z: Self.mountZ)

        Self.mountNut.nutTrap(depthClearance: 0.8)
            .rotated(x: -90°)
            .translated(
                x: Self.armOffset,
                y: (Motion.rodSpacing + Self.armWidth - 2 * Self.mountBoltLength) / 2 - 0.01,
                z: Self.mountZ
            )
            .cloned {
                $0.translated(z: 10)
            }
            .convexHull()
            .symmetry(over: .y)
    }

    // MARK: - Top half

    @GeometryBuilder3D
    var top: any Geometry3D {
        Union {
            shape
                .intersecting {
                    Cylinder(diameter: 100, height: 100)
                        .translated(z: Self.baseHeight)
                }
                .translated(z: -Self.baseHeight)
                .subtracting {
                    for mountPoint in Self.hotendMountTopScrewHoles {
                        Self.hotendMountTopScrewPrototype.clearanceHole(entry: .recessedHead)
                            .transformed(.rotation(from: .up, to: Direction3D(mountPoint.direction)))
                            .translated(mountPoint.top)
                            .symmetry(over: .y)
                    }

                    // The hotend's M12 thread, opening into the filament path above it
                    ThreadedHole(
                        thread: Self.hotendMountThread,
                        depth: Self.hotendMountThreadedLength,
                        leadIns: .leading
                    )

                    Cylinder(diameter: Self.hotendMountThread.majorDiameter, height: 2)
                        .translated(z: Self.hotendMountThreadedLength)
                        .adding {
                            Cylinder(diameter: 4 + tolerance, height: 0.01)
                                .rotated(y: Self.hotendMountExtruderAngle)
                                .translated(
                                    x: Self.hotendMountExtruderXOffset,
                                    z: Self.hotendMountExtruderZOffset
                                )
                        }
                        .convexHull()

                    // Everything above the extruder's mounting face is cut away flat
                    Box([100, 100, 100])
                        .aligned(at: .centerXY)
                        .adding {
                            Self.extruderBolt.clearanceHole(entry: .recessedHead)
                                .withTolerance(Self.extruderBoltTolerance)
                                .distributed(at: Self.hotendMountExtruderMountHoleOffsets)
                        }
                        .rotated(y: Self.hotendMountExtruderAngle)
                        .translated(
                            x: Self.hotendMountExtruderXOffset,
                            z: Self.hotendMountExtruderZOffset
                        )
                }

            // Marks the extruder's own mounting holes for alignment. Disabled by default.
            Circle(diameter: 3)
                .distributed(at: [[2.2, 9.5], [12.2, 9.5], [2.2, -9.5], [12.2, -9.5]])
                .extruded(height: 10)
                .rotated(z: 60° + 120°)
                .highlighted()
                .hidden()

            lgxLite
                .rotated(y: Self.hotendMountExtruderAngle)
                .translated(x: Self.hotendMountExtruderXOffset, z: Self.hotendMountExtruderZOffset)
                .inBackground()
        }
    }

    // MARK: - Fan duct

    /// The duct that turns the part-cooling fan's outlet down onto the print.
    var fanDuct: any Geometry3D {
        let wallThickness = 1.0
        let baseHeight = 8.6
        let angle = 65°
        let length = 7.0
        let outletSize = Vector2D(x: 10, y: 1.5)
        let outletAngle = 0°
        let mountThickness = 2.0
        let screwPrototype = Bolt.hexSocketCountersunk(.m3, length: 10)

        /// The duct's cross-section, as a wall of `wallThickness` around the fan's outlet.
        let throat = Rectangle(Self.fanOutletSize + wallThickness * 2)
            .aligned(at: .center)
            .subtracting {
                Rectangle(Self.fanOutletSize)
                    .aligned(at: .center)
            }

        return Circle(diameter: Self.fanOutletSize.y + 2 * wallThickness)
            .translated(x: Self.fanDuctMountHoleOffset)
            .symmetry(over: .x)
            .convexHull()
            .subtracting {
                Rectangle(Self.fanOutletSize)
                    .aligned(at: .center)
            }
            .extruded(height: mountThickness, topEdge: .fillet(radius: 1))
            .subtracting {
                screwPrototype.clearanceHole(entry: .recessedHead)
                    .flipped(along: .z)
                    .translated(x: Self.fanDuctMountHoleOffset, z: mountThickness - 0.4)
                    .symmetry(over: .x)
            }
            .adding {
                // Straight section off the fan
                throat.extruded(height: baseHeight)

                // Elbow turning the flow towards the nozzle
                throat
                    .rotated(90°)
                    .aligned(at: .centerY, .minX)
                    .revolved(in: 0°..<angle)
                    .rotated(x: 90°, z: -90°)
                    .aligned(at: .centerXY)
                    .translated(z: baseHeight)

                // Nozzle, tapering the throat down to a slot
                Rectangle(Self.fanOutletSize + wallThickness * 2)
                    .aligned(at: .centerX)
                    .lofted(height: length) {
                        Rectangle(outletSize + wallThickness * 2)
                            .aligned(at: .centerX)
                    }
                    .subtracting {
                        Rectangle(Self.fanOutletSize)
                            .aligned(at: .centerX)
                            .translated(y: wallThickness)
                            .lofted(height: length + 0.002) {
                                Rectangle(outletSize)
                                    .aligned(at: .centerX)
                                    .translated(y: wallThickness)
                            }
                            .translated(z: -0.001)

                        Box(100)
                            .aligned(at: .centerX)
                            .rotated(x: -outletAngle)
                            .translated(z: length)
                            .translated(y: -outletSize.y / 2 - wallThickness)
                    }
                    .aligned(at: .maxY)
                    .rotated(x: -angle)
                    .translated(y: Self.fanOutletSize.y / 2 + wallThickness, z: baseHeight)
            }
    }

    // MARK: - Reference models

    /// Vendor STLs for the hardware the effector is built around, kept alongside the sources.
    private static let mockModelsDirectory: URL = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()   // Parts
            .deletingLastPathComponent()   // Sources
            .deletingLastPathComponent()   // package root
            .appending(component: "Mock")
    }()

    var revoMicro: any Geometry3D {
        Import(model: Self.mockModelsDirectory.appending(component: "E3D_Revo_Micro.stl"))
            .translated(x: 0.51, z: -20)
            .rotated(z: 90°)
    }

    var lgxLite: any Geometry3D {
        Import(model: Self.mockModelsDirectory.appending(component: "EXT-LGX-LITE-V2-DUMMY.stl"))
            .rotated(x: 90°, z: -90°)
            .translated(x: 44.0 / 2)
            .rotated(z: 180°)
            .translated(x: 6.1)
    }
}
