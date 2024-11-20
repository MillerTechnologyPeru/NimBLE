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
        ),
        .executable(
            name: "NimBLEDemo",
            targets: ["NimBLEDemo"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
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
                ),
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothHCI",
                    package: "Bluetooth"
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                )
            ],
            swiftSettings: [
                .enableUpcomingFeature("Embedded")
            ]
        ),
        .target(
            name: "CNimBLE"
        ),
        .executableTarget(
            name: "NimBLEDemo",
            dependencies: [
                "NimBLE"
            ]
        ),
        .testTarget(
            name: "NimBLETests",
            dependencies: ["NimBLE"]
        )
    ]
)
