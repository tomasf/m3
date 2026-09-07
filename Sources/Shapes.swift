import Cadova

/// A Reuleaux triangle: the constant-width curve formed by intersecting three circles, each
/// centered on the opposite corner. It gives the printer its rounded triangular footprint.
struct ReuleauxTriangle: Geometry2D {
    let width: Double

    var body: any Geometry2D {
        (0..<3).mapIntersection { index in
            Circle(radius: width)
                .translated(x: width / 3.0.squareRoot())
                .rotated(Double(index) * 360° / 3)
        }
    }
}

/// The maker's mark recessed into the underside of the bottom plate.
///
/// The outline is traced in the source artwork's coordinate space; `body` recenters it on the
/// origin and normalizes it to a width of 1, so callers scale it to whatever size they need.
struct Logo: Geometry2D {
    private static let outline: [Vector2D] = [
        [33.196, 56.192], [33.196, 140], [55.804, 140], [55.804, 97.52], [91.404, 97.52],
        [99.404, 79.952], [55.804, 79.952], [55.804, 56.192], [98.028, 56.192],
        [106.028, 37.184], [10.38, 37.184], [2.38, 56.192]
    ]

    private static let artworkMinimum = Vector2D(2.38, 37.184)
    private static let artworkMaximum = Vector2D(106.028, 140)

    var body: any Geometry2D {
        Polygon(Self.outline)
            .scaled([1, -1])
            .translated([
                -(Self.artworkMaximum.x + Self.artworkMinimum.x) / 2,
                (Self.artworkMaximum.y + Self.artworkMinimum.y) / 2
            ])
            .scaled(1 / (Self.artworkMaximum.x - Self.artworkMinimum.x))
    }
}
