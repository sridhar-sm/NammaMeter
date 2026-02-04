import XCTest
@testable import NammaMeter

final class FormValidationTests: XCTestCase {
  func testCityNameValidatorTrimsWhitespace() {
    let validator = CityFormValidator()
    let errors = validator.validate(CityFormData(name: "   "))
    XCTAssertFalse(errors.isEmpty)
  }

  func testDoubleRangeValidatorRejectsNegativeValues() {
    let validator = DoubleRangeValidator(field: "value", label: "Value", min: 0, max: nil)
    let errors = validator.validate(-1)
    XCTAssertFalse(errors.isEmpty)
  }

  func testFareProfileValidatorRejectsNegativeBaseFare() {
    let validator = FareProfileFormValidator()
    let data = FareProfileFormData(
      effectiveFrom: Date(),
      baseFare: -5,
      perKmRate: 10,
      minFare: 40,
      includedKm: 2,
      nightMultiplier: 1.5,
      nightStartHour: 22,
      nightEndHour: 5,
      freeWaitMinutes: 5,
      waitIntervalMinutes: 15,
      waitIntervalCharge: 10
    )

    let errors = validator.validate(data)
    XCTAssertTrue(errors.contains { $0.field == FareProfileFormField.baseFare.rawValue })
  }

  func testFareProfileValidatorWarnsWhenMinFareBelowBaseFare() {
    let validator = FareProfileFormValidator()
    let data = FareProfileFormData(
      effectiveFrom: Date(),
      baseFare: 50,
      perKmRate: 10,
      minFare: 40,
      includedKm: 2,
      nightMultiplier: 1.5,
      nightStartHour: 22,
      nightEndHour: 5,
      freeWaitMinutes: 5,
      waitIntervalMinutes: 15,
      waitIntervalCharge: 10
    )

    let errors = validator.validate(data)
    XCTAssertTrue(errors.contains {
      $0.field == FareProfileFormField.minFare.rawValue && $0.severity == .warning
    })
  }

  func testFormStateUpdatesValidationOnInputChange() {
    let formState = FormState(input: CityFormData(name: ""), validator: CityFormValidator())
    XCTAssertFalse(formState.isValid)

    formState.input = CityFormData(name: "Bengaluru")
    XCTAssertTrue(formState.isValid)
  }

  func testFormStateAllowsWarnings() {
    let formState = FormState(
      input: FareProfileFormData(
        effectiveFrom: Date(),
        baseFare: 50,
        perKmRate: 10,
        minFare: 40,
        includedKm: 2,
        nightMultiplier: 1.5,
        nightStartHour: 22,
        nightEndHour: 5,
        freeWaitMinutes: 5,
        waitIntervalMinutes: 15,
        waitIntervalCharge: 10
      ),
      validator: FareProfileFormValidator()
    )

    XCTAssertTrue(formState.isValid)
    XCTAssertFalse(formState.errors.isEmpty)
  }
}
