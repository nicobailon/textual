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
  }
#endif
