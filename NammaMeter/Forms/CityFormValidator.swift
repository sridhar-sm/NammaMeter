import Foundation

enum CityFormField: String {
  case name
}

struct CityFormData {
  var name: String
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

  func validate(_ input: CityFormData) -> [ValidationError] {
    nameValidator.validate(input.name)
  }
}
