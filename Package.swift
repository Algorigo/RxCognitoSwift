// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxCognito",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "RxCognito",
            targets: ["RxCognito"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.1.0"),
        .package(url: "https://github.com/adam-fowler/big-num", from: "2.0.1"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RxCognito",
            dependencies: [.product(name: "SotoCognitoIdentityProvider", package: "soto"), .product(name: "SotoS3", package: "soto"), .product(name:"BigNum", package: "big-num"), "RxSwift"]),
        .testTarget(
            name: "RxCognitoTests",
            dependencies: ["RxCognito"]),
    ]
)
