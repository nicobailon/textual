#if os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  @testable import Textual

  // One line of text that fills the row, so the selection layer takes a press anywhere in it.
  private struct Line: TextLayout {
    let bounds: CGRect
    var attributedString: NSAttributedString { NSAttributedString(string: "Glide at 60 Hz") }
    var origin: CGPoint { .zero }
    var lines: [any TextLine] { [Row(bounds: bounds)] }

    struct Row: TextLine {
      let bounds: CGRect
      var origin: CGPoint { bounds.origin }
      var typographicBounds: CGRect { bounds }
      var runs: [any TextRun] {
        [EmptyRun(typographicBounds: bounds, slice: EmptyRunSlice(typographicBounds: bounds, characterRange: 0..<14))]
      }
    }
  }

  private struct Lines: TextLayoutCollection {
    let layouts: [any TextLayout]
    func isEqual(to other: any TextLayoutCollection) -> Bool { false }
    func needsPositionReconciliation(with other: any TextLayoutCollection) -> Bool { false }
    func index(of layout: Text.Layout) -> Int? { nil }
  }

  @MainActor
  private final class Presses {
    var count = 0
  }

  @MainActor
  struct TextSelectionAreaPressTests {
    // A row as in a card: the selection layer lies over a button's label. A click the layer takes on the button's words
    // presses the button each time, and the keyboard stays where it was.
    @Test
    func aClickOnTextInsideAButtonPressesItEveryTime() throws {
      let presses = Presses()
      let size = CGSize(width: 300, height: 100)
      let model = TextSelectionModel(layoutCollection: Lines(layouts: [Line(bounds: CGRect(origin: .zero, size: size))]))
      let row = Button {
        presses.count += 1
      } label: {
        Text("Glide at 60 Hz").frame(width: size.width, height: size.height)
      }
      .buttonStyle(.plain)
      .overlay {
        AppKitTextInteractionOverlay(model: model, overflowFrames: [], isArea: true)
      }
      let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
      window.isReleasedWhenClosed = false
      window.contentView = NSHostingView(rootView: row)
      // Mouse events reach only an active app's key window.
      NSApp.setActivationPolicy(.accessory)
      NSApp.activate(ignoringOtherApps: true)
      window.orderFrontRegardless()
      window.makeKey()
      window.contentView?.layoutSubtreeIfNeeded()
      RunLoop.main.run(until: Date().addingTimeInterval(0.2))
      defer { window.orderOut(nil) }
      let layer = try #require(Self.layer(in: window.contentView))
      let responder = window.firstResponder

      for _ in 0..<3 {
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
          let event = try #require(NSEvent.mouseEvent(
            with: type, location: CGPoint(x: 150, y: 50), modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
          ))
          type == .leftMouseDown ? layer.mouseDown(with: event) : layer.mouseUp(with: event)
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
      }

      #expect(presses.count == 3)
      #expect(window.firstResponder === responder)
      #expect(model.selectedRange == nil)
    }

    private static func layer(in view: NSView?) -> NSTextInteractionView? {
      guard let view else { return nil }
      if let layer = view as? NSTextInteractionView { return layer }
      return view.subviews.lazy.compactMap { layer(in: $0) }.first
    }
  }
#endif
