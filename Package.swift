// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NimBLE",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "NimBLE",
            targets: ["NimBLE"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "NimBLE",
            dependencies: [
                "CNimBLE",
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                )
            ],
            swiftSettings: [
                .enableUpcomingFeature("Embedded")
            ]
        ),
        .target(
            name: "CNimBLE"
        ),
        .testTarget(
            name: "NimBLETests",
            dependencies: ["NimBLE"]
        )
    ]
)
