import Foundation
import SwiftSCAD

struct ReuleauxTriangle: Shape2D {
    let width: Double

    var body: Geometry2D {
        (0..<3).mapIntersection { i in
            Circle(radius: width)
                .translated(x: width / 3.0.squareRoot())
                .rotated(Double(i) * 360° / 3)
        }
    }
}

protocol Part3D {
    @UnionBuilder3D func body(_ parent: any Geometry3D) -> any Geometry3D
}

extension Geometry3D {
    func adding(_ part: any Part3D) -> any Geometry3D {
        part.body(self)
    }
}

extension Vector3D {
    static func x(_ value: Double) -> Vector3D { .init(x: value) }
    static func y(_ value: Double) -> Vector3D { .init(y: value) }
    static func z(_ value: Double) -> Vector3D { .init(z: value) }
}

extension Geometry2D {
    func rounded(amount: Double, side: RoundingSide = .both, @UnionBuilder2D in mask: () -> any Geometry2D) -> any Geometry2D {
        self
            .subtracting { mask() }
            .adding {
                self.rounded(amount: amount, side: side)
                    .intersection { mask() }
            }
    }
}

let logo = Polygon([[33.196, 56.192], [33.196, 140], [55.804, 140], [55.804, 97.52], [91.404, 97.52], [99.404, 79.952], [55.804, 79.952], [55.804, 56.192], [98.028, 56.192], [106.028, 37.184], [10.38, 37.184], [2.38, 56.192]])
    .scaled([1, -1])
    .translated([-(106.028 + 2.38) / 2, (140 + 37.184) / 2])
    .scaled(1 / (106.028 - 2.38))
