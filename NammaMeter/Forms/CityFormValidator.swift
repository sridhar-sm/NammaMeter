import Foundation

enum CityFormField: String {
  case name
  case countryCode
  case currencyCode
}

struct CityFormData {
  var name: String
  var countryCode: String = "IN"
  var currencyCode: String = "INR"
}

struct CityFormValidator: FormValidator {
  private let nameValidator = StringValidator(
    field: CityFormField.name.rawValue,
    label: "City name",
    minLength: 1,
    maxLength: 50,
    allowEmpty: false,
    trimWhitespace: true
  )

  private let countryCodeValidator = StringValidator(
    field: CityFormField.countryCode.rawValue,
    label: "Country code",
    minLength: 2,
    maxLength: 2,
    allowEmpty: false,
    trimWhitespace: true
  )

  private let currencyCodeValidator = StringValidator(
    field: CityFormField.currencyCode.rawValue,
    label: "Currency code",
    minLength: 3,
    maxLength: 3,
    allowEmpty: false,
    trimWhitespace: true
  )

  func validate(_ input: CityFormData) -> [ValidationError] {
    nameValidator.validate(input.name)
      + countryCodeValidator.validate(input.countryCode)
      + currencyCodeValidator.validate(input.currencyCode)
  }
}
