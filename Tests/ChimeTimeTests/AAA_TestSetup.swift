import XCTest

/// Resets ChimeTime UserDefaults keys before each test to ensure isolation.
/// Named AAA_ to ensure this test suite runs first and registers the observer
/// before any other test suites that depend on clean UserDefaults state.
final class AAA_TestSetup: XCTestCase {
    private static let observer = ChimeTimeTestObserver()

    override class func setUp() {
        super.setUp()
        XCTestObservationCenter.shared.addTestObserver(observer)
    }

    func test_aaa_environment_ready() {
        // Exists to trigger class setUp which registers the observer
    }
}

final class ChimeTimeTestObserver: NSObject, XCTestObservation {
    func testCaseWillStart(_ testCase: XCTestCase) {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("chimetime.") {
            defaults.removeObject(forKey: key)
        }
    }
}
