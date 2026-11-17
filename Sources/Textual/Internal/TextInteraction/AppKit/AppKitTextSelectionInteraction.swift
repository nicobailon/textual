#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextSelectionInteraction` presents the platform-specific text selection overlay for macOS.
  //
  // The modifier receives a `TextSelectionModel` and places it in the environment so selection highlights
  // and attachment dimming can access it. An overlay hosts `AppKitTextInteractionOverlay`, which wraps an
  // `NSView` that handles selection gestures and context menus. The modifier also manages cursor updates,
  // switching between I-beam and pointing hand based on hover position over text or links.
  //
  // In a selection area the texts are plain `Text` views among controls, so the area draws their highlight
  // itself, and the overlay takes only presses that start on text: hover, scrolling, right clicks and
  // presses anywhere else reach the views below it.

  typealias PlatformTextSelectionInteraction = AppKitTextSelectionInteraction

  struct AppKitTextSelectionInteraction: ViewModifier {
    @State private var cursorPushed = false

    private let model: TextSelectionModel
    private let isArea: Bool
    private let isActive: Bool
    private let click: (@MainActor (CGPoint) -> Bool)?

    init(model: TextSelectionModel, isArea: Bool = false, isActive: Bool = true, click: (@MainActor (CGPoint) -> Bool)? = nil) {
      self.model = model
      self.isArea = isArea
      self.isActive = isActive
      self.click = click
    }

    func body(content: Content) -> some View {
      if isArea {
        content
          .environment(model)
          .background {
            AreaSelectionHighlight(model: model)
          }
          .overlayPreferenceValue(OverflowFrameKey.self) { frames in
            if isActive {
              AppKitTextInteractionOverlay(model: model, overflowFrames: frames, isArea: true, click: click)
            }
          }
      } else {
        content
          // We need the selection model at text fragment level for the
          // text selection background and selected attachment dimming
          .environment(model)
          .overlayPreferenceValue(OverflowFrameKey.self) { frames in
            AppKitTextInteractionOverlay(model: model, overflowFrames: frames)
              .onContinuousHover { phase in
                updateCursor(for: phase, model: model)
              }
          }
      }
    }

    private func updateCursor(for phase: HoverPhase, model: TextSelectionModel) {
      switch phase {
      case .active(let location):
        let cursor =
          model.url(for: location) != nil
          ? NSCursor.pointingHand
          : NSCursor.iBeam
        if !cursorPushed {
          cursor.push()
          cursorPushed = true
        } else {
          cursor.set()
        }
      case .ended:
        if cursorPushed {
          NSCursor.pop()
          cursorPushed = false
        }
      }
    }
  }

  // One canvas for the whole area, drawn only while there is a selection.
  private struct AreaSelectionHighlight: View {
    let model: TextSelectionModel

    var body: some View {
      if let selectedRange = model.selectedRange {
        let _ = model.layoutRevision
        let rects = model.selectionRects(for: selectedRange)
        Canvas { context, _ in
          for selectionRect in rects {
            context.fill(
              Path(selectionRect.rect.integral),
              with: .color(.init(nsColor: .selectedTextBackgroundColor))
            )
          }
        }
        .allowsHitTesting(false)
      }
    }
  }
#endif
