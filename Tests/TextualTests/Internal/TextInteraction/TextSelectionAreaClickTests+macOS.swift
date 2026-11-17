#if os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  @testable import Textual

  // One line of text that fills the area, so the layer takes a press anywhere in it.
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
  private final class Clicks {
    var points: [CGPoint] = []
    var takes = true
  }

  // The layer's own handlers are called as the window calls them; no event goes through a window, which a test process
  // can't count on being active to receive.
  @MainActor
  struct TextSelectionAreaClickTests {
    @Test
    func aPressThatDoesNotMoveIsReportedAsAClickWhereItLanded() {
      let (layer, model, clicks) = Self.layer()

      press(layer, from: CGPoint(x: 150, y: 50), to: CGPoint(x: 151, y: 51))

      #expect(clicks.points == [CGPoint(x: 150, y: 50)])
      #expect(model.selectedRange == nil)
    }

    @Test
    func aDragSelectsAndIsNoClick() {
      let (layer, model, clicks) = Self.layer()

      press(layer, from: CGPoint(x: 10, y: 50), to: CGPoint(x: 290, y: 50))

      #expect(clicks.points.isEmpty)
      #expect(model.selectedRange != nil)
    }

    // Clicked twice in quick succession, an option is picked and cleared, as a button is.
    @Test
    func aSecondClickOnAControlIsAClickNotAWordSelection() {
      let (layer, model, clicks) = Self.layer()

      press(layer, from: CGPoint(x: 150, y: 50), to: CGPoint(x: 150, y: 50))
      press(layer, from: CGPoint(x: 150, y: 50), to: CGPoint(x: 150, y: 50), clickCount: 2)

      #expect(clicks.points.count == 2)
      #expect(model.selectedRange == nil)
    }

    @Test
    func aDoubleClickOnWordsNoControlTakesSelectsAWord() {
      let (layer, model, clicks) = Self.layer()
      clicks.takes = false

      press(layer, from: CGPoint(x: 150, y: 50), to: CGPoint(x: 150, y: 50))
      press(layer, from: CGPoint(x: 150, y: 50), to: CGPoint(x: 150, y: 50), clickCount: 2)

      #expect(model.selectedRange != nil)
    }

    private static let size = CGSize(width: 300, height: 100)

    private static func layer() -> (NSTextInteractionView, TextSelectionModel, Clicks) {
      let model = TextSelectionModel(layoutCollection: Lines(layouts: [Line(bounds: CGRect(origin: .zero, size: size))]))
      let clicks = Clicks()
      let layer = NSTextInteractionView(model: model, exclusionRects: [], openURL: OpenURLAction { _ in .handled })
      layer.isArea = true
      layer.textClick = {
        clicks.points.append($0)
        return clicks.takes
      }
      layer.frame = CGRect(origin: .zero, size: size)
      let window = NSWindow(contentRect: layer.frame, styleMask: [.titled], backing: .buffered, defer: false)
      window.isReleasedWhenClosed = false
      window.contentView = layer
      return (layer, model, clicks)
    }

    // Points in the layer's own (flipped) coordinates.
    private func press(_ layer: NSTextInteractionView, from start: CGPoint, to end: CGPoint, clickCount: Int = 1) {
      func event(_ type: NSEvent.EventType, at point: CGPoint) -> NSEvent {
        NSEvent.mouseEvent(
          with: type, location: layer.convert(point, to: nil), modifierFlags: [], timestamp: 0,
          windowNumber: layer.window?.windowNumber ?? 0, context: nil, eventNumber: 0, clickCount: clickCount, pressure: 1
        )!
      }
      layer.mouseDown(with: event(.leftMouseDown, at: start))
      layer.mouseDragged(with: event(.leftMouseDragged, at: end))
      layer.mouseUp(with: event(.leftMouseUp, at: end))
    }
  }
#endif
