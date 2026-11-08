#if TEXTUAL_ENABLE_TEXT_SELECTION && os(macOS)
  import Foundation
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct TextualTextLayoutTests {
    @Test
    func hitNamesTheWordAndBlockUnderAPoint() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let origin = CGPoint(x: 10, y: 20)
      let layout = TextualTextLayout(model: model, origin: origin)
      let m = TextPosition(indexPath: .init(runSlice: 2, run: 1, line: 0, layout: 0), affinity: .downstream)  // the 'm' in "sample"
      let caret = model.caretRect(for: m)
      let point = CGPoint(x: caret.midX + origin.x + 1, y: caret.midY + origin.y)

      // when
      let hit = try #require(layout.hit(at: point))

      // then
      #expect(hit.word == "sample")
      #expect(hit.block.contains("sample"))
      #expect(hit.block.count > hit.word.count)
      #expect(hit.wordBounds.contains(point))
    }

    @Test
    func boundsFindsARangeByItsCharacters() throws {
      // given
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let layout = TextualTextLayout(model: model, origin: .zero)
      let m = TextPosition(indexPath: .init(runSlice: 2, run: 1, line: 0, layout: 0), affinity: .downstream)
      let caret = model.caretRect(for: m)
      let hit = try #require(layout.hit(at: CGPoint(x: caret.midX + 1, y: caret.midY)))

      // when
      let bounds = layout.bounds(of: hit.wordRange)
      let outside = layout.bounds(of: TextualTextRange(lowerBound: 1_000_000, upperBound: 1_000_001))

      // then
      #expect(bounds == hit.wordBounds)
      #expect(outside == nil)
    }
  }
#endif
