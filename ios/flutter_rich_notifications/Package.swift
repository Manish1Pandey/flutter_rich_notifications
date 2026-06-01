// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_rich_notifications",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "flutter-rich-notifications", targets: ["flutter_rich_notifications"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_rich_notifications",
            dependencies: [],
            resources: [],
            cSettings: [
                .headerSearchPath("include/flutter_rich_notifications"),
            ]
        ),
    ]
)
