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

    // The click sent on to the control under the text comes back with its timestamp rounded, and late on a busy main
    // thread; taken again it was sent on again, in a loop.
    @Test(arguments: [
      (CGPoint(x: 150, y: 50), 1, 0.005, true),
      (CGPoint(x: 150, y: 50), 1, 0.05, true),
      (CGPoint(x: 150, y: 50), 1, 0.2, true),
      (CGPoint(x: 150, y: 50), 1, 0.4, false),
      (CGPoint(x: 150, y: 50), 2, 0.05, false),
      (CGPoint(x: 160, y: 50), 1, 0.05, false),
    ])
    func theClickSentOnIsKnownWhenItComesBack(location: CGPoint, clickCount: Int, after: TimeInterval, isSent: Bool) {
      let sent = SentOn(location: CGPoint(x: 150, y: 50), clickCount: 1, at: 100)
      #expect(sent.isSent(SentOn(location: location, clickCount: clickCount, at: 100 + after)) == isSent)
    }
  }
#endif
