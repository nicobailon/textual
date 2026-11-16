import SwiftUI

// MARK: - Overview
//
// OverflowFrameKey collects frame rectangles from scrollable overflow regions (like code blocks)
// and propagates them via preferences to selection overlays.
//
// Text selection uses these frames to exclude scrollable regions from hit-testing so embedded
// ScrollViews can receive touch events while the parent selection interaction ignores them.

struct OverflowFrameKey: PreferenceKey {
  static let defaultValue: [CGRect] = []

  static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
    value.append(contentsOf: nextValue())
  }
}

extension TextualNamespace where Base: View {
  /// Lets the view take clicks inside selectable text, such as a code block's own buttons.
  ///
  /// The text selection overlay covers the whole text, so controls drawn by a custom style
  /// otherwise never see the pointer.
  @MainActor public func interactive() -> some View {
    base.background(
      GeometryReader { geometry in
        Color.clear
          .preference(key: OverflowFrameKey.self, value: [geometry.frame(in: .textContainer)])
      }
    )
  }
}
