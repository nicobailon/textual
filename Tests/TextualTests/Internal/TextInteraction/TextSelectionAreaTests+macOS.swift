#if os(macOS)
  import AppKit
  import SwiftUI
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

    // A click on the text is handed to SwiftUI-drawn content only: an AppKit control tracks a press in its own loop.
    @Test
    func aClickIsHandedToSwiftUIContentButNotToAnAppKitControl() {
      let hosted = NSHostingView(rootView: Button("Glide at 60 Hz") {}.buttonStyle(.plain))
      #expect(NSTextInteractionView.handsClick(to: hosted))

      let controls: [NSView] = [
        NSButton(title: "Glide at 60 Hz", target: nil, action: nil),
        NSPopUpButton(frame: .zero, pullsDown: false),
        NSSegmentedControl(labels: ["Before", "After"], trackingMode: .selectOne, target: nil, action: nil),
        NSSlider(value: 1, minValue: 0, maxValue: 2, target: nil, action: nil),
      ]
      for control in controls {
        #expect(NSTextInteractionView.handsClick(to: control) == false, "\(type(of: control))")
      }
      #expect(NSTextInteractionView.handsClick(to: nil) == false)
    }
  }
#endif
