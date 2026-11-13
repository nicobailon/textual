#if os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  @testable import Textual

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

    // The parsed and styled values are kept from body, so a new input has to replace them rather than show the old.
    @Test
    func changedMarkupRecomputes() {
      let structured = NSHostingView(rootView: StructuredText(markdown: "Hello").frame(width: 200))
      let short = structured.fittingSize.height
      structured.rootView = StructuredText(markdown: "Hello\n\nThere\n\n- one\n- two").frame(width: 200)
      #expect(structured.fittingSize.height > short)

      let inline = NSHostingView(rootView: InlineText(markdown: "Hello").frame(width: 120))
      let line = inline.fittingSize.height
      inline.rootView = InlineText(markdown: "Hello there, this sentence wraps onto several lines at this width.")
        .frame(width: 120)
      #expect(inline.fittingSize.height > line)
    }

    @Test
    func memoComputesOncePerDistinctKey() {
      let memo = Memo<String, Int>()
      var computed = 0
      let count = { (key: String) -> Int in
        computed += 1
        return key.count
      }

      #expect(memo.value(for: "ab", count) == 2)
      #expect(memo.value(for: "ab", count) == 2)
      #expect(computed == 1)
      #expect(memo.value(for: "abc", count) == 3)
      #expect(computed == 2)
      #expect(memo.value == 3)
    }
  }
#endif
