import XCTest
@testable import OrbitStore

final class OrbitVersionTests: XCTestCase {
    func testExactVersion() {
        XCTAssertTrue(OrbitVersion.isAtLeast("1.5.2","1.5.2"))
    }
    func testNewerVersion() {
        XCTAssertTrue(OrbitVersion.isAtLeast("1.6.0","1.5.12"))
    }
    func testOlderVersion() {
        XCTAssertFalse(OrbitVersion.isAtLeast("1.4.99","1.5.0"))
    }
    func testMissingVersion() {
        XCTAssertFalse(OrbitVersion.isAtLeast("?","1.4.0"))
    }
    func testZipTraversalProtection() {
        XCTAssertTrue(OrbitArchivePolicy.isSafeEntry("OrbitStore.app/Contents/MacOS/OrbitStore"))
        XCTAssertFalse(OrbitArchivePolicy.isSafeEntry("../../Users/test/.ssh/id_rsa"))
        XCTAssertFalse(OrbitArchivePolicy.isSafeEntry("folder/../secret"))
        XCTAssertFalse(OrbitArchivePolicy.isSafeEntry("/absolute/path"))
        XCTAssertFalse(OrbitArchivePolicy.isSafeEntry("folder\\..\\secret"))
    }
    func testUnsignedApplicationCannotBeInstalledSilently() throws {
        let fm=FileManager.default
        let root=fm.temporaryDirectory.appendingPathComponent("OrbitTests-\(UUID().uuidString)",isDirectory:true)
        defer { try? fm.removeItem(at:root) }
        let contents=root.appendingPathComponent("Unsigned.app/Contents",isDirectory:true)
        let executable=contents.appendingPathComponent("MacOS",isDirectory:true)
        try fm.createDirectory(at:executable,withIntermediateDirectories:true)
        let metadata:[String:Any]=[
            "CFBundleIdentifier":"org.example.unsigned-test",
            "CFBundleExecutable":"Unsigned",
            "CFBundlePackageType":"APPL",
            "CFBundleVersion":"1"
        ]
        let data=try PropertyListSerialization.data(fromPropertyList:metadata,format:.xml,options:0)
        try data.write(to:contents.appendingPathComponent("Info.plist"))
        let script=executable.appendingPathComponent("Unsigned")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to:script)
        try fm.setAttributes([.posixPermissions:0o755],ofItemAtPath:script.path)
        let package=root.appendingPathComponent("Unsigned.zip")
        let proc=Process()
        proc.executableURL=URL(fileURLWithPath:"/usr/bin/ditto")
        proc.arguments=["-c","-k",root.appendingPathComponent("Unsigned.app").path,package.path]
        try proc.run()
        proc.waitUntilExit()
        XCTAssertEqual(proc.terminationStatus,0)
        let target=root.appendingPathComponent("Output",isDirectory:true)
        do {
            let result=try OrbitPackageInstaller.install(
                package:package,targetDirectory:target,
                expectedBundleID:"org.example.unsigned-test",runningBundleIDs:[])
            if case .installed = result {
                XCTFail("An unsigned application must never be installed automatically.")
            }
        } catch {
            // A hard verification failure is also a safe outcome.
        }
        XCTAssertFalse(fm.fileExists(atPath:target.appendingPathComponent("Unsigned.app").path))
    }

    func testOrbitStoreSelfUpdateVersionOrdering() {
        XCTAssertTrue(OrbitSelfUpdater.isNewer("v0.4.0",than:"0.3.1"))
        XCTAssertTrue(OrbitSelfUpdater.isNewer("0.4.1-beta.1",than:"0.4.0"))
        XCTAssertFalse(OrbitSelfUpdater.isNewer("v0.3.1",than:"0.3.1"))
        XCTAssertFalse(OrbitSelfUpdater.isNewer("v0.3.0",than:"0.3.1"))
        XCTAssertFalse(OrbitSelfUpdater.isNewer("bad",than:"0.3.1"))
    }
    func testRepositoryIdentifiers() {
        XCTAssertNil(CatalogApp.fromRepositoryName("invalid-repo",name:"Invalid"))
        XCTAssertEqual(CatalogApp.fromRepositoryName("voirfilm-tv/OrbiteStore",name:"OrbitStore")?.repo,
                       "voirfilm-tv/OrbiteStore")
    }
}
