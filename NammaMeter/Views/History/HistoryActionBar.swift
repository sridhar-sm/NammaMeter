import SwiftUI

struct HistoryActionBar: View {
  let isEditing: Bool
  let showSelectAll: Bool
  let showDelete: Bool
  let isAllSelected: Bool
  let onToggleSelectAll: () -> Void
  let onDeleteSelected: () -> Void
  let onToggleEdit: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      if showSelectAll {
        Button {
          onToggleSelectAll()
        } label: {
          mangoPillLabel(isAllSelected ? "Deselect All" : "Select All")
        }
        .accessibilityLabel(isAllSelected ? "Deselect All" : "Select All")
        .accessibilityIdentifier("history.selectAllButton")
      }
      Spacer()
      if showDelete {
        Button(role: .destructive) {
          onDeleteSelected()
        } label: {
          Label("Delete", systemImage: "trash")
        }
        .tint(.red)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityIdentifier("history.deleteButton")
      }
      Button {
        onToggleEdit()
      } label: {
        mangoPillLabel(isEditing ? "Done" : "Edit")
      }
      .accessibilityLabel(isEditing ? "Done" : "Edit")
      .accessibilityIdentifier("history.editButton")
    }
  }

  private func mangoPillLabel(_ title: String) -> some View {
    Text(title)
      .font(FontPresets.Display.caption)
      .foregroundStyle(Theme.ink)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(Theme.mango.opacity(0.6))
      .clipShape(Capsule())
  }
}
