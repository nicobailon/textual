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

  private struct NativeButton: NSViewRepresentable {
    let presses: Presses

    func makeNSView(context: Context) -> NSButton {
      NSButton(title: "Glide at 60 Hz", target: context.coordinator, action: #selector(Coordinator.press))
    }

    func updateNSView(_ view: NSButton, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(presses: presses) }

    @MainActor
    final class Coordinator: NSObject {
      let presses: Presses
      init(presses: Presses) { self.presses = presses }
      @objc func press() { presses.count += 1 }
    }
  }

  @MainActor
  struct TextSelectionAreaPressTests {
    // A row as in a card: the selection layer lies over a button's label. A click the layer takes on the button's words
    // presses the button each time, and the keyboard stays where it was.
    @Test
    func aClickOnTextInsideAButtonPressesItEveryTime() throws {
      let presses = Presses()
      let row = Button {
        presses.count += 1
      } label: {
        Text("Glide at 60 Hz").frame(width: Self.size.width, height: Self.size.height)
      }
      .buttonStyle(.plain)
      let (window, layer, model) = try Self.window(over: row)
      defer { window.orderOut(nil) }
      let responder = window.firstResponder

      for _ in 0..<3 {
        try Self.click(layer, in: window)
      }

      #expect(presses.count == 3)
      #expect(window.firstResponder === responder)
      #expect(model.selectedRange == nil)
    }

    // An AppKit control tracks a press in its own loop (a pop-up opens its menu), so the layer hands a click only to
    // SwiftUI-drawn content. The time limit guards against a loop left waiting for a release.
    @Test(.timeLimit(.minutes(1)))
    func aClickOnTextOverAnAppKitControlIsNotHandedToIt() throws {
      let presses = Presses()
      let (window, layer, _) = try Self.window(over: NativeButton(presses: presses).frame(width: Self.size.width, height: Self.size.height))
      defer { window.orderOut(nil) }

      let start = Date()
      try Self.click(layer, in: window)

      #expect(Date().timeIntervalSince(start) < 1)
      #expect(presses.count == 0)
    }

    private static let size = CGSize(width: 300, height: 100)

    private static func window(over content: some View) throws -> (NSWindow, NSTextInteractionView, TextSelectionModel) {
      let model = TextSelectionModel(layoutCollection: Lines(layouts: [Line(bounds: CGRect(origin: .zero, size: size))]))
      let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled], backing: .buffered, defer: false)
      window.isReleasedWhenClosed = false
      window.contentView = NSHostingView(rootView: content.overlay {
        AppKitTextInteractionOverlay(model: model, overflowFrames: [], isArea: true)
      })
      // Mouse events reach only an active app's key window.
      NSApp.setActivationPolicy(.accessory)
      NSApp.activate(ignoringOtherApps: true)
      window.orderFrontRegardless()
      window.makeKey()
      window.contentView?.layoutSubtreeIfNeeded()
      RunLoop.main.run(until: Date().addingTimeInterval(0.2))
      return (window, try #require(layer(in: window.contentView)), model)
    }

    // Straight to the layer's own handlers, as the window sends them a press that lands on its text.
    private static func click(_ layer: NSTextInteractionView, in window: NSWindow) throws {
      for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
        let event = try #require(NSEvent.mouseEvent(
          with: type, location: CGPoint(x: 150, y: 50), modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
          windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        ))
        type == .leftMouseDown ? layer.mouseDown(with: event) : layer.mouseUp(with: event)
      }
      RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    private static func layer(in view: NSView?) -> NSTextInteractionView? {
      guard let view else { return nil }
      if let layer = view as? NSTextInteractionView { return layer }
      return view.subviews.lazy.compactMap { layer(in: $0) }.first
    }
  }
#endif
