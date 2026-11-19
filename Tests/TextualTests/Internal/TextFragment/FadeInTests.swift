#if os(macOS)
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct FadeInTests {
    @Test func fadeInsGiveTheNewestArrivalAndTheGapBeforeIt() {
      var text = AttributedString("settled fresh newest")
      #expect(text.fadeIns == nil)
      text[text.range(of: "fresh")!].textual.fadeIn = 10
      #expect(text.fadeIns?.newest == 10)
      #expect(text.fadeIns?.gap == nil)
      text[text.range(of: "newest")!].textual.fadeIn = 12
      #expect(text.fadeIns?.newest == 12)
      #expect(text.fadeIns?.gap == 2)
      #expect(text[text.range(of: "settled")!].fadeIns == nil)
    }

    @Test func opacityEasesOutOnceOverTheDuration() {
      #expect(FadeInRenderer.opacity(since: 10, now: 9) == 0)
      #expect(FadeInRenderer.opacity(since: 10, now: 10) == 0)
      #expect(abs(FadeInRenderer.opacity(since: 10, now: 10 + FadeIn.duration / 2) - UnitCurve.easeOut.value(at: 0.5)) < 1e-9)
      #expect(FadeInRenderer.opacity(since: 10, now: 10 + FadeIn.duration) == 1)
      #expect(FadeInRenderer.opacity(since: 10, now: 100) == 1)
    }

    @Test func onlyMarkedRunsCarryTheirArrivalIntoTheText() {
      var text = AttributedString("settled fresh")
      text[text.range(of: "fresh")!].textual.fadeIn = 10
      let builder = TextFragment<AttributedString>.TextBuilder(text, environment: TextEnvironmentValues(dynamicTypeSize: .large))
      let recorder = Recorder()
      _ = ImageRenderer(content: builder.text.textRenderer(recorder)).nsImage
      #expect(recorder.box.starts.contains(nil), "\(recorder.box.starts)")
      #expect(recorder.box.starts.contains(10), "\(recorder.box.starts)")
      #expect(recorder.box.starts.allSatisfy { $0 == nil || $0 == 10 }, "\(recorder.box.starts)")
    }

    @Test func markedTextRendersWhileItFades() {
      var text = AttributedString("settled fresh")
      text[text.range(of: "fresh")!].textual.fadeIn = ProcessInfo.processInfo.systemUptime
      let renderer = ImageRenderer(content: TextFragment(text).frame(width: 320).coordinateSpace(.textContainer))
      #expect(renderer.nsImage != nil)
    }
  }

  private struct Recorder: TextRenderer {
    final class Box { var starts: [TimeInterval?] = [] }
    let box = Box()

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
      for line in layout {
        for run in line {
          box.starts.append(run[FadeInAttribute.self]?.start)
        }
      }
    }
  }
#endif
