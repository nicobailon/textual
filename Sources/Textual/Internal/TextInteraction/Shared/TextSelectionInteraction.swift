import SwiftUI

// MARK: - Overview
//
// `TextSelectionInteraction` manages the text selection model lifecycle for multiple `Text` fragments.
//
// Selection is opt-in through the `textSelection` environment value. When enabled, the modifier
// observes text layout changes via `overlayTextLayoutCollection` and creates or updates a
// `TextSelectionModel`. The model is then passed to the platform-specific implementation
// (`PlatformTextSelectionInteraction`), which presents the appropriate selection UI for macOS
// or iOS. This separation keeps model management in shared code while platform interactions
// remain independent.

struct TextSelectionInteraction: ViewModifier {
  // An area selects every `Text` inside it as one text, with or without the `textSelection` environment value.
  private let isArea: Bool

  init(isArea: Bool = false) {
    self.isArea = isArea
  }

  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.textSelection) private var textSelection
    @Environment(\.textSelectionChange) private var textSelectionChange
    @Environment(\.textClick) private var textClick
    @Environment(\.textLayoutChange) private var textLayoutChange
    @Environment(TextSelectionCoordinator.self) private var coordinator: TextSelectionCoordinator?

    @State private var model = TextSelectionModel()
    @State private var origin = CGPoint.zero
    @State private var isHovering = false
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if isArea {
        // An area tracks its texts only while the pointer is over it or it holds a selection: a press needs the
        // pointer there, and a card scrolling past does no selection work. Its origin is its own space's, always zero.
        let isActive = isHovering || model.selectedRange != nil
        content
          .overlayTextLayoutCollection(includesAllText: true, isActive: isActive) { layoutCollection in
            Color.clear
              .onChange(of: AnyTextLayoutCollection(layoutCollection), initial: true) {
                model.setCoordinator(coordinator)
                model.setLayoutCollection(layoutCollection)
                reportLayout()
              }
          }
          .modifier(PlatformTextSelectionInteraction(model: model, isArea: true, isActive: isActive, click: textClick))
          .onChange(of: model.selectedRange) {
            reportSelection()
          }
          .onHover { isHovering = $0 }
      } else if textSelection.allowsSelection {
        content
          .overlayTextLayoutCollection { layoutCollection in
            Color.clear
              .onChange(of: AnyTextLayoutCollection(layoutCollection), initial: true) {
                model.setCoordinator(coordinator)
                model.setLayoutCollection(layoutCollection)
                reportLayout()
              }
          }
          .modifier(PlatformTextSelectionInteraction(model: model, isArea: isArea))
          .onGeometryChange(for: CGPoint.self, of: { $0.frame(in: .textContainer).origin }) {
            origin = $0
            reportLayout()
          }
          .onChange(of: model.selectedRange) {
            reportSelection()
          }
      } else {
        content
      }
    #else
      content
    #endif
  }

  #if TEXTUAL_ENABLE_TEXT_SELECTION
    private func reportLayout() {
      textLayoutChange?(TextualTextLayout(model: model, origin: origin))
    }

    private func reportSelection() {
      guard let textSelectionChange else { return }
      guard let range = model.selectedRange, !range.isCollapsed else {
        textSelectionChange(nil)
        return
      }
      let bounds = model.selectionRects(for: range).reduce(CGRect.null) { $0.union($1.rect) }
      textSelectionChange(
        TextualSelection(text: model.text(in: range), bounds: bounds.offsetBy(dx: origin.x, dy: origin.y))
      )
    }
  #endif
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  extension EnvironmentValues {
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @usableFromInline
    @Entry var textSelection: any TextSelectability.Type = DisabledTextSelectability.self
  }
#endif
