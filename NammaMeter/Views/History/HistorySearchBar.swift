import SwiftUI

struct HistorySearchBar: View {
  @Binding var searchText: String
  @FocusState.Binding var searchFocused: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(Color(uiColor: .secondaryLabel))
      TextField("Search trips · ಹುಡುಕಿ", text: $searchText)
        .font(.system(size: 16))
        .foregroundStyle(Color(uiColor: .label))
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .focused($searchFocused)
        .submitLabel(.search)
      if !searchText.isEmpty {
        Button {
          searchText = ""
          searchFocused = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear search")
      } else if searchFocused {
        Button {
          searchFocused = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel search")
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color(uiColor: .systemGray6))
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(Color(uiColor: .systemGray4), lineWidth: 0.5)
    )
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}
