import Cadova

await Project(packageRelative: "Models") {
    Metadata(
        title: "m3",
        description: "A small delta printer.",
        author: "Tomas Wincent Franzén",
        license: "MIT"
    )

    Environment {
        $0.tolerance = 0.3
    }

    await Model("printer") { Printer() }

    await Model("base") {
        Base()
            .rotated(x: 180°)
            .aligned(at: .centerXY, .bottom)
    }

    await Model("base-with-sides") {
        Printer.baseWithSides
            .adding {
                CornerCover(height: 1)
                    .translated(z: Base.height)
                    .colored(.lightBlue)
            }
    }

    await Model("base-contents") {
        Base()
            .rotated(x: 180°)
            .translated(z: Base.height)
            .adding {
                Printer.baseContents
                    .translated(z: Base.topThickness)

                Bottom()
                    .translated(z: Base.height)
                    .colored(.beige, alpha: 0.5)

                Bottom()
                    .rotated(x: 180°)
                    .translated(x: 300)
            }
    }

    await Model("top") { Top() }
    await Model("top-cover") { Top.topCover }
    await Model("top-cover-with-outlet") { Top.topCoverWithCableOutlet }
    await Model("handle-cover") { Top.handleCover }
    await Model("top-roller-holder-cover") { Top.farHolderCover }

    await Model("carriage") {
        Carriage()
            .aligned(at: .centerXY, .bottom)
            .colored(.aquamarine)
    }

    await Model("carriage-cover") { CarriageCover() }
    await Model("corner-cover-flat") { CornerCover(height: 10.0) }
    await Model("sensor-cover") { Bed.sensorCover }
    await Model("effector") { Effector() }

    await Group("Test prints") {
        await Model("base-corner-test") { TestPrint.baseCorner }
        await Model("front-prototype") { TestPrint.baseFront }
        await Model("top-corner-prototype") { TestPrint.topCorner }
        await Model("top-corner-prototype-small") { TestPrint.smallTopCorner }
        await Model("top-roller-holder-prototype") { TestPrint.topRollerHolder }
        await Model("top-roller-holder-prototype-large") { TestPrint.largeTopRollerHolder }
    }
}
