import SwiftUI
import XCTest
@testable import NammaMeter

@MainActor
final class SuperMechanicalMeterViewTests: XCTestCase {

  // MARK: - formattedDigits 3R+1P layout

  func testFormattedDigitsTypicalFare() {
    let window = MeterDisplayWindow(
      tripState: .inProgress, fare: 126.50,
      displayEdge: .clear, pulse: false, digitStyle: .disk
    )
    let result = window.formattedDigits()
    XCTAssertEqual(result.digits, ["1", "2", "6", "5"])
    XCTAssertEqual(result.paiseStartIndex, 3)
  }

  func testFormattedDigitsZeroFare() {
    let window = MeterDisplayWindow(
      tripState: .inProgress, fare: 0,
      displayEdge: .clear, pulse: false, digitStyle: .disk
    )
    let result = window.formattedDigits()
    XCTAssertEqual(result.digits, ["0", "0", "0", "0"])
    XCTAssertEqual(result.paiseStartIndex, 3)
  }

  func testFormattedDigitsMaxThreeDigitRupees() {
    let window = MeterDisplayWindow(
      tripState: .inProgress, fare: 999.90,
      displayEdge: .clear, pulse: false, digitStyle: .disk
    )
    let result = window.formattedDigits()
    XCTAssertEqual(result.digits, ["9", "9", "9", "9"])
    XCTAssertEqual(result.paiseStartIndex, 3)
  }

  func testFormattedDigitsWrapsAbove999() {
    let window = MeterDisplayWindow(
      tripState: .inProgress, fare: 1234.50,
      displayEdge: .clear, pulse: false, digitStyle: .disk
    )
    let result = window.formattedDigits()
    // 1234 % 1000 = 234, paise 50 / 10 = 5
    XCTAssertEqual(result.digits, ["2", "3", "4", "5"])
    XCTAssertEqual(result.paiseStartIndex, 3)
  }

  func testFormattedDigitsPaiseRoundsDown() {
    let window = MeterDisplayWindow(
      tripState: .inProgress, fare: 25.99,
      displayEdge: .clear, pulse: false, digitStyle: .disk
    )
    let result = window.formattedDigits()
    // 25 rupees, 99 paise → tens digit = 9
    XCTAssertEqual(result.digits, ["0", "2", "5", "9"])
    XCTAssertEqual(result.paiseStartIndex, 3)
  }

  func testFormattedDigitsSmallFare() {
    let window = MeterDisplayWindow(
      tripState: .inProgress, fare: 3.10,
      displayEdge: .clear, pulse: false, digitStyle: .disk
    )
    let result = window.formattedDigits()
    // 3 rupees, 10 paise → tens digit = 1
    XCTAssertEqual(result.digits, ["0", "0", "3", "1"])
    XCTAssertEqual(result.paiseStartIndex, 3)
  }
}
