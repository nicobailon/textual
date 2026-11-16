#if os(macOS)
  import AppKit
  import Testing

  @testable import Textual

  @MainActor
  struct TextSelectionAreaTests {
    @Test(arguments: [
      (CGPoint(x: 10, y: 10), false),
      (CGPoint(x: 12, y: 12), false),
      (CGPoint(x: 13, y: 10), false),
      (CGPoint(x: 14, y: 10), true),
      (CGPoint(x: 10, y: 30), true),
    ])
    func aPressThatMovesMoreThanThreePointsSelects(end: CGPoint, selects: Bool) {
      #expect(NSTextInteractionView.isDrag(from: CGPoint(x: 10, y: 10), to: end) == selects)
    }

    // The press sent on to the control under the text comes back with its timestamp rounded; taking it again looped.
    @Test(arguments: [
      (NSEvent.EventType.leftMouseDown, false, 5.0, nil, true),
      (.leftMouseDown, false, 5.0, 5.0, false),
      (.leftMouseDown, false, 5.000_000_3, 5.0, false),
      (.leftMouseDown, false, 5.2, 5.0, true),
      (.leftMouseDown, true, 5.2, nil, false),
      (.mouseMoved, false, 5.2, nil, false),
    ] as [(NSEvent.EventType, Bool, TimeInterval, TimeInterval?, Bool)])
    func theLayerTakesARealLeftPressButNotTheOneItSentOn(
      type: NSEvent.EventType, control: Bool, time: TimeInterval, passedOn: TimeInterval?, takes: Bool
    ) {
      #expect(NSTextInteractionView.takesPress(type, control: control, at: time, passedOn: passedOn) == takes)
    }
  }
#endif
