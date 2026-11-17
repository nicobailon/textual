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
  @Entry var textClick: (@MainActor (CGPoint) -> Bool)?
}

extension TextualNamespace where Base: View {
  /// Calls `action` with the selected text whenever the selection changes, and with `nil` when it clears.
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public func onSelectionChange(_ action: @escaping @MainActor (TextualSelection?) -> Void) -> some View {
    base.environment(\.textSelectionChange, action)
  }
}

extension TextualNamespace where Base: View {
  /// Calls `action` with the point, in the area's own coordinates, where a click on the text of a
  /// ``textual/textSelectionArea()`` landed: a press on its text that didn't move far enough to select.
  ///
  /// Return `true` when the click acted on something there. A second or third click that `action` doesn't take selects
  /// a word or a paragraph, as a double or triple click on text does.
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  public func onTextClick(_ action: @escaping @MainActor (CGPoint) -> Bool) -> some View {
    base.environment(\.textClick, action)
  }
}
