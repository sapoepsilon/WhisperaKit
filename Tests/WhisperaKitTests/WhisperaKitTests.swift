import XCTest
@testable import WhisperaKit

final class WhisperaKitTests: XCTestCase {
    func testCommandParserInit() {
        let parser = CommandParser()
        XCTAssertNotNil(parser)
    }

    func testParseValidJSON() throws {
        let parser = CommandParser()
        let json = #"{"category": "apps", "operation": "open", "app": "chrome"}"#
        let result = try parser.parse(jsonString: json)
        XCTAssertEqual(result, #"open -a "Google Chrome""#)
    }

    func testParseVolumeSet() throws {
        let parser = CommandParser()
        let json = #"{"category": "volume", "operation": "set", "level": "70"}"#
        let result = try parser.parse(jsonString: json)
        XCTAssertEqual(result, "osascript -e 'set volume output volume 70'")
    }

    func testWhisperaInit() {
        let whispera = Whispera()
        XCTAssertFalse(whispera.isReady)
    }
}
