// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OrbitStore",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "OrbitStore", targets: ["OrbitStore"])],
    targets: [.executableTarget(name: "OrbitStore")]
)
