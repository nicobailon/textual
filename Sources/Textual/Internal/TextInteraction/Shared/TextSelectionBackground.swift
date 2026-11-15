import SwiftUI

// MARK: - Overview
//
// `TextSelectionBackground` draws selection highlights behind a `Text` fragment.
//
// The platform selection interaction stores a `TextSelectionModel` in the environment at fragment
// scope. This modifier reads the fragment’s anchored `Text.Layout` and forwards it to the AppKit
// selection view so it can convert the current selected range into highlight rectangles.

struct TextSelectionBackground: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
      content
        .backgroundPreferenceValue(Text.LayoutKey.self) { value in
          // Only while there is a selection: a geometry reader resolves its anchor again on every frame the text
          // scrolls, for every fragment on screen. Gated in here, so the fragment's own identity never changes.
          if textSelectionModel?.selectedRange != nil, let anchoredLayout = value.first {
            GeometryReader { geometry in
              AppKitTextSelectionView(
                layout: anchoredLayout.layout,
                origin: geometry[anchoredLayout.origin]
              )
            }
          }
        }
    #else
      content
    #endif
  }
}
