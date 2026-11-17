#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextInteractionOverlay` bridges the shared `TextSelectionModel` into an `NSView`.
  //
  // The overlay reads exclusion rectangles for hit-testing. This allows embedded scrollable regions (like
  // code blocks) to receive touch events while the parent handles text selection. The view also
  // manages selection gestures, keyboard-driven updates, and context menus while SwiftUI renders
  // the text.

  struct AppKitTextInteractionOverlay: NSViewRepresentable {
    private let model: TextSelectionModel
    private let overflowFrames: [CGRect]
    private let isArea: Bool
    private let click: (@MainActor (CGPoint) -> Bool)?

    init(model: TextSelectionModel, overflowFrames: [CGRect], isArea: Bool = false, click: (@MainActor (CGPoint) -> Bool)? = nil) {
      self.model = model
      self.overflowFrames = overflowFrames
      self.isArea = isArea
      self.click = click
    }

    func makeNSView(context: Context) -> NSTextInteractionView {
      let view = NSTextInteractionView(
        model: model,
        exclusionRects: overflowFrames,
        openURL: context.environment.openURL
      )
      view.isArea = isArea
      view.textClick = click
      return view
    }

    func updateNSView(_ nsView: NSTextInteractionView, context: Context) {
      nsView.model = model
      nsView.exclusionRects = overflowFrames
      nsView.openURL = context.environment.openURL
      nsView.isArea = isArea
      nsView.textClick = click
    }
  }
#endif
