import Foundation
import Cadova
import Helical

struct Effector: Shape3D {
    static let thickness = 7.0
    static let armOffset = 29.0
    static let armWidth = armMountWidth

    static let mountBoltLength = 16.0
    static let mountBolt = Bolt.hexSocketHeadCap(.m3, length: mountBoltLength)
    static let mountHoleDiameter = 3.3
    static let mountNut = Nut.square(.m3, series: .thin)
    static let mountZ = thickness / 2 + 0

    static let hotendZOffset = 1.0 // From bottom of heating, relative to effector bottom
    static let hotendSpringDiameter = 9.0
    static let hotendHeatsinkDiameter = 20.0
    static let hotendFanDuctWidth = 25.0
    static let hotendFanDuctLength = 30.5
    static let hotendFanDuctOffset = -5.5

    static let hotendBodyHeight = 24.0 // Bottom to mount
    static let hotendMountFullHeight = 25.0
    static let hotendMountExtruderZOffset = 15.0
    static let hotendMountExtruderXOffset = 1.0
    static let hotendMountExtruderAngle = 25°//13°
    static let hotendMountExtruderMountHoleOffsets: [Vector3D] = [[-12.2, 9.5, -2.2], [-12.2, -9.5, -2.2], [-2.2, 9.5, -8], [-2.2, -9.5, -8]]
    // Bolts nearest motor: Use 8 mm screws
    // Back bolts: Use 12 mm screws

    static let hotendMountThread = ScrewThread.isoMetric(.m12, pitch: 1.5)
    static let hotendMountThreadedLength = 8.0

    static let hotendMountWallThickness = 7.0
    static let hotendMountWidth = hotendFanDuctWidth + 2 * hotendMountWallThickness
    static let hotendMountLength = hotendHeatsinkDiameter + 2

    static let hotendMountTopScrewHoles: [MountBolt] = [
        .init(top: [6, 15, 2], direction: [-0.46, 0.2, -1]),
        .init(top: [-9, 16, 2], direction: [0.5, -0.17, -1])
    ]
    static let hotendMountTopScrewHoleDiameter = 2.6
    static let hotendMountTopScrewHoleDepth = 12.0
    static let hotendMountTopScrewPrototype = Bolt.hexSocketCountersunk(.m3, length: 13)

    static let cableSlitWidth = 3.5
    static let cableSlitDepth = 10.0

    static let fanSize = Vector3D(40.05, 40, 10.1)
    static let fanXOffset = -14.0
    static let fanZOffset = -0.8 // From top surface
    static let fanHoleInset = 2.5
    static let fanMountHoleDiameter = 1.9
    static let fanMountHoleDepth = 10.0
    static let fanOutletSize = Vector2D(x: 27.8, y: 8.4)

    static let fanDuctMountHoleOffset = 18.0
    static let fanDuctMountHoleDiameter = 2.7
    static let fanDuctMountHoleDepth = Self.thickness

    static let topDiameter = Self.hotendHeatsinkDiameter + 20

    @Environment(\.tolerance) var tolerance

    // Length from bottom to nozzle tip: 21-22 mm

    var footprint: any Geometry2D {
        return Rectangle(x: Self.armOffset + Self.thickness / 2, y: rodSpacing - Self.armWidth)
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
                    .translated(x: Self.armOffset + Self.thickness / 2 + Self.cableSlitWidth / 2 - Self.cableSlitDepth)
                    .rotated(-120°)
            }
    }

    var shape: any Geometry3D {
        let baseTop = Self.hotendZOffset + Self.hotendBodyHeight
        let top = baseTop + Self.hotendMountFullHeight

        let path = BezierPath2D(startPoint: .zero)
            .addingLine(to: [0, top])
            .addingLine(to: [Self.topDiameter / 2, top])
            .addingCurve([Self.topDiameter / 2, Self.thickness + 16], [Self.armOffset - 6, Self.thickness], [Self.armOffset, Self.thickness])
            .addingLine(to: [Self.armOffset, 0])

        return Polygon(path)
            .revolved()
            .intersecting { footprint.extruded(height: top) }
            .adding {
                footprint.extruded(height: Self.thickness)
                Box([-Self.fanXOffset, Self.fanSize.x, Self.hotendZOffset + Self.hotendBodyHeight + Self.hotendMountFullHeight])
                    .aligned(at: .minX, .centerY)
                    .translated(x: Self.fanXOffset)
                    .hidden()
            }
            .subtracting {
                // Fan
                Box(Self.fanSize + .y(100) + tolerance)
                    //.highlighted()
                    .translated(-Self.fanSize.with(.z, as: 0) / 2)
                    .adding {
                        Cylinder(diameter: Self.fanMountHoleDiameter, height: Self.fanMountHoleDepth)
                            .aligned(at: .maxZ)
                            .translated(x: -Self.fanSize.x / 2 + Self.fanHoleInset, y: Self.fanSize.y / 2 - Self.fanHoleInset, z: 0.01)
                            .symmetry(over: .x)
                            .flipped(along: .y)
                    }
                    .rotated(x: 90°, z: -90°)
                    .aligned(at: .minZ)
                    .translated(x: Self.fanXOffset, z: Self.thickness + Self.fanZOffset)
            }
    }

    static let baseHeight = Self.hotendZOffset + Self.hotendBodyHeight

    @GeometryBuilder3D
    var base: any Geometry3D {
        shape
            .intersecting { Cylinder(diameter: 100, height: Self.baseHeight) }
            .subtracting {
                Union {
                    // Fillet the ends
                    #warning("2025-08-02 double-check this")
                    EdgeProfile.fillet(radius: Self.thickness / 2).profile
                        .extruded(height: rodSpacing)
                        .rotated(x: 90°)
                        .rotated(y: 180°)
                        .aligned(at: .centerY)
                        .translated(x: Self.armOffset + Self.thickness / 2 + 0.01, z: Self.thickness + 0.01)

                    // Arm mounts
                    Circle(diameter: Self.mountHoleDiameter)
                        .overhangSafe(.bridge)
                        .extruded(height: rodSpacing)
                        .rotated(x: 90°)
                        .aligned(at: .centerY)
                        .translated(x: Self.armOffset, z: Self.mountZ)

                    Self.mountNut.nutTrap(depthClearance: 0.8)
                        .rotated(x: -90°)
                        .translated(x: Self.armOffset, y: (rodSpacing + Self.armWidth - 2 * Self.mountBoltLength) / 2 - 0.01, z: Self.mountZ)
                        .cloned {
                            $0.translated(z: 10)
                        }
                        .convexHull()
                        .symmetry(over: .y)
                }
                .repeated(around: .z, count: 3)

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

                // Fan outlet
                Box([Self.fanOutletSize.y, Self.fanOutletSize.x, Self.thickness])
                    .aligned(at: .centerXY)
                    .translated(x: Self.fanXOffset - Self.fanSize.z / 2, z: -0.01)

                Cylinder(diameter: Self.fanDuctMountHoleDiameter, height: Self.fanDuctMountHoleDepth)
                    .translated(x: Self.fanXOffset - Self.fanSize.z / 2, y: Self.fanDuctMountHoleOffset, z: -0.01)
                    .symmetry(over: .y)

                // Clear space in front of fan
                Box(Self.fanSize + tolerance)
                    .rotated(x: 90°, z: -90°)
                    .aligned(at: .maxX, .centerY)
                    .translated(x: Self.fanXOffset - 5, z: Self.thickness)

                // Clear space in front of hotend fan
                Box([20, 25 + tolerance, 20])
                    .aligned(at: .minX, .centerY)
                    .translated(x: Self.hotendFanDuctLength + Self.hotendFanDuctOffset - 1, z: Self.thickness)

                // Hotend vents
                Box([50, 3, 10])
                    .aligned(at: .centerY)
                    .rotated(z: 180° - 55°)
                    .translated(z: Self.thickness + 5)
                    .symmetry(over: .y)

                Cylinder(diameter: 3, height: 50)
                    .rotated(y: -90° - 48°)
                    .repeated(around: .z, in: -50°...50°, count: 5)
                    .translated(z: 14.0)

                for mountPoint in Self.hotendMountTopScrewHoles {
                    Cylinder(diameter: Self.hotendMountTopScrewHoleDiameter, height: Self.hotendMountTopScrewHoleDepth)
                        .transformed(.rotation(from: .up, to: Direction3D(mountPoint.direction)))
                        .translated(mountPoint.top)
                        .translated(z: Self.baseHeight)
                        .symmetry(over: .y)
                    //.highlighted()
                }
            }
            .adding {
                revoMicro
                    .inBackground()
                //.disabled()
            }
    }

    var body: any Geometry3D {
        base
        fanDuct
            .rotated(y: 180°, z: -90°)
            .translated(x: Self.fanXOffset - Self.fanSize.z / 2)

        top.translated(z: Self.baseHeight + 0.01)
            //.inBackground()
        //shape.translated(x: 80)

        // Visualized arms
        Cylinder(diameter: 6, height: 140)
            .rotated(y: 3°)
            .translated(x: Self.armOffset, y: rodSpacing / 2, z: Self.thickness / 2)
            .symmetry(over: .y)
            .repeated(around: .z, count: 3)
            .inBackground()
            .hidden()
    }

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
                        //.highlighted()
                    }
                    
                    ThreadedHole(thread: Self.hotendMountThread, depth: Self.hotendMountThreadedLength, leadIns: .leading)
                    Cylinder(diameter: Self.hotendMountThread.majorDiameter, height: 2)
                        .translated(z: Self.hotendMountThreadedLength)
                        .adding {
                            Cylinder(diameter: 4 + tolerance, height: 0.01)
                                .rotated(y: Self.hotendMountExtruderAngle)
                                .translated(x: Self.hotendMountExtruderXOffset, z: Self.hotendMountExtruderZOffset)
                        }
                        .convexHull()
                    
                    Box([100, 100, 100])
                        .aligned(at: .centerXY)
                        .adding {
                            Bolt.hexSocketCountersunk(.m3, length: 8)
                                .clearanceHole(entry: .recessedHead)
                                .withTolerance(0.4)
                                .distributed(at: Self.hotendMountExtruderMountHoleOffsets)
                        }
                        .rotated(y: Self.hotendMountExtruderAngle)
                        .translated(x: Self.hotendMountExtruderXOffset, z: Self.hotendMountExtruderZOffset)
                }
            
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
            //.disabled()
        }
        .withTolerance(0.3)
        //.crossSectioned(axis: .y)
    }

    struct MountBolt {
        let top: Vector3D
        let direction: Vector3D
    }

    var mockModelsDirectory: URL {
        let sourceURL = URL(filePath: #filePath)
        let packageRoot = sourceURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return packageRoot.appendingPathComponent("Mock")
    }

    var revoMicro: any Geometry3D {
        Import(model: mockModelsDirectory.appendingPathComponent("E3D_Revo_Micro.stl"))
            .translated(x: 0.51, z: -20)
            .rotated(z: 90°)
    }

    var lgxLite: any Geometry3D {
        Import(model: mockModelsDirectory.appendingPathComponent("EXT-LGX-LITE-V2-DUMMY.stl"))
            .rotated(x: 90°, z: -90°)
            .translated(x: 44.0 / 2)
            .rotated(z: 180°)
            .translated(x: 6.1)
    }

    var nutTest: any Geometry3D {
        Nut.hex(thread: .isoMetric(.m12, pitch: 1.5), width: 17, height: 8)
    }

    var fanDuct: any Geometry3D {
        let wallThickness = 1.0
        let baseHeight = 8.6
        let angle = 65°
        let length = 7.0
        let outletSize = Vector2D(x: 10, y: 1.5)
        let outletAngle = 0°
        let mountThickness = 2.0
        let screwPrototype = Bolt.hexSocketCountersunk(.m3, length: 10)

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
                Rectangle(Self.fanOutletSize + wallThickness * 2)
                    .aligned(at: .center)
                    .subtracting {
                        Rectangle(Self.fanOutletSize)
                            .aligned(at: .center)
                    }
                    .extruded(height: baseHeight)

                Rectangle(Self.fanOutletSize + wallThickness * 2)
                    .aligned(at: .center)
                    .subtracting {
                        Rectangle(Self.fanOutletSize)
                            .aligned(at: .center)
                    }
                    .rotated(90°)
                    .aligned(at: .centerY, .minX)
                    .revolved(in: 0°..<angle)
                    .rotated(x: 90°, z: -90°)
                    .aligned(at: .centerXY)
                    .translated(z: baseHeight)

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
}
