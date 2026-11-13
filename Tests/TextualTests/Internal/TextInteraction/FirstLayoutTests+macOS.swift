#if os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  import Textual

  // A lazy stack sizes a new row from its first layout: text that is empty there makes it build every row it takes to
  // fill the screen at zero height.
  @MainActor
  struct FirstLayoutTests {
    @Test
    func structuredTextHasItsHeightOnItsFirstLayout() {
      let view = NSHostingView(rootView: StructuredText(markdown: "Hello").frame(width: 200))

      #expect(view.fittingSize.height > 0)
    }

    // Empty inline text still measures one line, so this checks that wrapped words are already there.
    @Test
    func inlineTextHasItsHeightOnItsFirstLayout() {
      let line = NSHostingView(rootView: InlineText(markdown: "Hello").frame(width: 120))
      let wrapped = NSHostingView(
        rootView: InlineText(markdown: "Hello there, this sentence wraps onto several lines at this width.")
          .frame(width: 120)
      )

      #expect(wrapped.fittingSize.height > line.fittingSize.height)
    }
  }
#endif
