import Foundation
import XCTest
@testable import NammaMeter

final class ECBXMLParserTests: XCTestCase {

  func testParseValidXML() throws {
    let xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01"
                     xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
      <gesmes:subject>Reference rates</gesmes:subject>
      <gesmes:Sender><gesmes:name>European Central Bank</gesmes:name></gesmes:Sender>
      <Cube>
        <Cube time="2026-02-12">
          <Cube currency="USD" rate="1.0827"/>
          <Cube currency="GBP" rate="0.8640"/>
          <Cube currency="INR" rate="94.5000"/>
        </Cube>
      </Cube>
    </gesmes:Envelope>
    """

    let data = xml.data(using: .utf8)!
    let rates = try ECBXMLParser.parse(data: data)

    XCTAssertEqual(rates.count, 3)
    XCTAssertEqual(rates["USD"]!, 1.0827, accuracy: 0.0001)
    XCTAssertEqual(rates["GBP"]!, 0.8640, accuracy: 0.0001)
    XCTAssertEqual(rates["INR"]!, 94.5000, accuracy: 0.001)
  }

  func testParseEmptyRatesThrows() {
    let xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01">
      <Cube><Cube time="2026-02-12"></Cube></Cube>
    </gesmes:Envelope>
    """

    let data = xml.data(using: .utf8)!
    XCTAssertThrowsError(try ECBXMLParser.parse(data: data)) { error in
      XCTAssertTrue(error is ECBXMLParserError)
    }
  }

  func testParseMalformedXML() {
    let data = "not xml at all".data(using: .utf8)!
    XCTAssertThrowsError(try ECBXMLParser.parse(data: data))
  }

  func testParseIgnoresNonCubeElements() throws {
    let xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <root>
      <other currency="JPY" rate="999"/>
      <Cube currency="USD" rate="1.08"/>
    </root>
    """

    let data = xml.data(using: .utf8)!
    let rates = try ECBXMLParser.parse(data: data)
    XCTAssertEqual(rates.count, 1)
    XCTAssertEqual(rates["USD"]!, 1.08, accuracy: 0.01)
  }
}
