import SwiftUI

// The text draws as plain text; a cover over each stretch of new runs fades out in Core Animation, so the app does no
// work per frame while words fade in.
struct FadeInOverlay: ViewModifier {
  let fadesIn: Bool

  func body(content: Content) -> some View {
    content
      .overlayPreferenceValue(Text.LayoutKey.self) { value in
        #if os(macOS)
          if fadesIn, let anchoredLayout = value.first {
            GeometryReader { geometry in
              FadeInCovers(stretches: anchoredLayout.layout.fadeInStretches(at: geometry[anchoredLayout.origin]))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
          }
        #endif
      }
  }
}
