#if os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  import Textual

  // Records what each cell's style is given, so a test can read it back after a layout.
  @MainActor
  private final class Cells {
    var texts: [String] = []
  }

  private struct Recording: StructuredText.TableCellStyle {
    let cells: Cells

    func makeBody(configuration: Configuration) -> some View {
      cells.texts.append("\(configuration.row),\(configuration.column): \(configuration.text)")
      return configuration.label
    }
  }

  @MainActor
  struct TableCellTextTests {
    @Test
    func eachCellIsGivenItsOwnTableTextWithoutInlineStyles() {
      let cells = Cells()
      let view = NSHostingView(
        rootView: StructuredText(
          markdown: """
            | Channel | Status |
            | --- | --- |
            | `#flagship` | **Waiting** on shots |

            Between.

            | Lane |
            | --- |
            | narrow-tables |
            """
        )
        .textual.tableCellStyle(Recording(cells: cells))
        .frame(width: 400)
      )
      _ = view.fittingSize

      #expect(
        Set(cells.texts) == [
          "0,0: Channel", "0,1: Status", "1,0: #flagship", "1,1: Waiting on shots",
          "0,0: Lane", "1,0: narrow-tables",
        ])
    }
  }
#endif
