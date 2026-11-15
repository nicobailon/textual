import SwiftUI

extension StructuredText {
  /// The properties of a code block passed to a `CodeBlockStyle`.
  public struct CodeBlockStyleConfiguration {
    /// A type-erased view that contains the code block content.
    public struct Label: View {
      init(_ label: some View) {
        self.body = AnyView(label)
      }
      public let body: AnyView
    }

    /// The code block content.
    public let label: Label
    /// The indentation level of the code block within the document structure.
    public let indentationLevel: Int
    /// A language hint extracted from the fenced code block, if present.
    public let languageHint: String?
    /// A proxy that provides code-block actions.
    public let codeBlock: CodeBlockProxy
    /// The syntax-highlighting theme used for this code block.
    public let highlighterTheme: HighlighterTheme

    let content: AttributedSubstring

    /// The code block's text, without its final line break.
    public var code: String {
      String(content.characters[...])
    }

    /// The code block's first `count` lines, highlighted like ``label``. It lays out only those lines.
    public func label(firstLines count: Int) -> Label {
      let characters = content.characters
      var end = characters.startIndex
      for _ in 0..<max(count, 0) {
        guard let newline = characters[end...].firstIndex(of: "\n") else {
          end = characters.endIndex
          break
        }
        end = characters.index(after: newline)
      }
      if end > characters.startIndex, characters[characters.index(before: end)] == "\n" {
        end = characters.index(before: end)
      }
      return lines(content[..<end])
    }

    /// The code block's last `count` lines, highlighted like ``label``. It lays out only those lines.
    public func label(lastLines count: Int) -> Label {
      let characters = content.characters
      var start = characters.endIndex
      for _ in 0..<max(count, 0) {
        guard start > characters.startIndex,
          let newline = characters[..<characters.index(before: start)].lastIndex(of: "\n")
        else {
          start = characters.startIndex
          break
        }
        start = characters.index(after: newline)
      }
      return lines(content[start...])
    }

    private func lines(_ part: AttributedSubstring) -> Label {
      Label(HighlightedTextFragment(part, languageHint: languageHint, theme: highlighterTheme))
    }
  }

  /// A style that controls how `StructuredText` renders code blocks.
  ///
  /// Apply a code block style with ``TextualNamespace/codeBlockStyle(_:)`` or through a bundled
  /// ``StructuredText/Style``.
  public protocol CodeBlockStyle: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents a code block.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = CodeBlockStyleConfiguration
  }
}

extension EnvironmentValues {
  @usableFromInline
  @Entry var codeBlockStyle: any StructuredText.CodeBlockStyle = .default
}
