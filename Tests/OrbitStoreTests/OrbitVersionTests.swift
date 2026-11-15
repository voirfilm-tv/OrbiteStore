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
    func testRepositoryIdentifiers() {
        XCTAssertNil(CatalogApp.fromRepositoryName("invalid-repo",name:"Invalid"))
        XCTAssertEqual(CatalogApp.fromRepositoryName("voirfilm-tv/OrbiteStore",name:"OrbitStore")?.repo,
                       "voirfilm-tv/OrbiteStore")
    }
}
