import SwiftUI

struct FadeInAttribute: TextAttribute {
  var start: TimeInterval
}

extension AttributedStringProtocol {
  var newestFadeIn: TimeInterval? {
    runs[AttributeScopes.TextualAttributes.FadeInAttribute.self].compactMap(\.0).max()
  }
}
