import XCTest
@testable import Cafeine

final class LocalizationTests: XCTestCase {
    private let resources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Resources")

    private func keys(_ language: String) throws -> Set<String> {
        let url = resources.appendingPathComponent("\(language).lproj/Localizable.strings")
        let table = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String], "\(language) is unreadable")
        return Set(table.keys)
    }

    /// Every language carries exactly the keys of English, the development region.
    func testEveryLanguageHasEveryKey() throws {
        let english = try keys("en")
        XCTAssertFalse(english.isEmpty)
        for language in ["fr", "de", "es", "it"] {
            XCTAssertEqual(try keys(language), english, language)
        }
    }

    /// Menu durations come from FormatStyle, so they follow the locale instead of a hand-built string.
    func testDurationsAreFormattedNotAssembled() {
        let oneHour = AppDelegate.format(3600, width: .wide)
        XCTAssertFalse(oneHour.isEmpty)
        XCTAssertTrue(oneHour.contains("1"))
        XCTAssertFalse(AppDelegate.format(90 * 60, width: .abbreviated).contains("."),
                       "minutes are rounded down, never fractional")
    }
}
