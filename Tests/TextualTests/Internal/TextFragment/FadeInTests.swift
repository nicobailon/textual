#if os(macOS)
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct FadeInTests {
    @Test func newestFadeInIsTheLatestMarkedRun() {
      var text = AttributedString("settled fresh newest")
      #expect(text.newestFadeIn == nil)
      text[text.range(of: "fresh")!].textual.fadeIn = 10
      text[text.range(of: "newest")!].textual.fadeIn = 12
      #expect(text.newestFadeIn == 12)
      #expect(text[text.range(of: "settled")!].newestFadeIn == nil)
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
      #expect(recorder.box.starts == [nil, 10])
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
