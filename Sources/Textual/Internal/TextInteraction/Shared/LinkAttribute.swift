import SwiftUI

struct LinkAttribute: TextAttribute {
  var url: URL

  init(_ url: URL) {
    self.url = url
  }
}

extension Text.Layout.Run {
  var url: URL? {
    self[LinkAttribute.self]?.url
  }

  /// The URL of the link this run draws, for a `TextRenderer` that draws links its own way.
  public var textualLink: URL? {
    url
  }
}
