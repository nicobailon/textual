import SwiftUI

/// The text a user has selected in ``StructuredText`` or ``InlineText``.
///
/// `bounds` encloses the selection in the coordinate space of the text view the selection belongs to.
public struct TextualSelection: Equatable, Sendable {
  public let text: String
  public let bounds: CGRect

  public init(text: String, bounds: CGRect) {
    self.text = text
    self.bounds = bounds
  }
}

extension EnvironmentValues {
  @Entry var textSelectionChange: (@MainActor (TextualSelection?) -> Void)?
}

extension TextualNamespace where Base: View {
  /// Calls `action` with the selected text whenever the selection changes, and with `nil` when it clears.
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public func onSelectionChange(_ action: @escaping @MainActor (TextualSelection?) -> Void) -> some View {
    base.environment(\.textSelectionChange, action)
  }
}
