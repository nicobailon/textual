#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
  import SwiftUI

  // MARK: - Overview
  //
  // `NSTextInteractionView` implements selection and link interaction on macOS.
  //
  // The view sits in an overlay above one or more rendered `Text` fragments. It uses
  // `TextSelectionModel` for hit testing and range manipulation, and it respects `exclusionRects`
  // so embedded scrollable regions continue to receive input events. Link taps are forwarded to
  // `openURL`.

  final class NSTextInteractionView: NSView {
    var model: TextSelectionModel {
      didSet {
        if model !== oldValue { watchSelection() }
      }
    }
    var exclusionRects: [CGRect]
    var openURL: OpenURLAction
    var isArea = false {
      didSet {
        if isArea != oldValue {
          updateTrackingAreas()
          watchSelection()
        }
      }
    }

    // An area takes the keyboard only for a selection, so a click it sends on leaves focus where the control under it puts it.
    override var acceptsFirstResponder: Bool { isArea == false || model.selectedRange != nil }
    override var isFlipped: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    private var dragStart: TextPosition?
    private var selectionAnchor: TextPosition?

    // In an area, a press on text that never moves is a click for the view under the text, sent on to it on release.
    private var pressedAt: NSEvent?
    private var isDragging = false
    private var showsTextCursor = false
    private var isHandingOn = false
    private var handedOn: (down: NSEvent, up: NSEvent)?
    private var ownsPress = false
    private var clickAway: Any?

    init(
      model: TextSelectionModel,
      exclusionRects: [CGRect],
      openURL: OpenURLAction
    ) {
      self.model = model
      self.exclusionRects = exclusionRects
      self.openURL = openURL

      super.init(frame: .zero)
      self.wantsLayer = false
      watchSelection()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
      let localPoint = convert(point, from: superview)
      let isExcluded = exclusionRects.contains {
        $0.contains(localPoint)
      }

      if isExcluded {
        return nil
      } else if isArea {
        guard isHandingOn == false, let event = NSApp.currentEvent, event.type == .leftMouseDown,
          event.modifierFlags.contains(.control) == false
        else { return nil }
        guard model.isText(at: localPoint) else { return nil }
        return super.hitTest(point)
      } else {
        return super.hitTest(point)
      }
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      updateClickAway()
    }

    private func watchSelection() {
      guard isArea else { return }
      model.selectionDidChange = { [weak self] in
        self?.updateClickAway()
      }
      updateClickAway()
    }

    // An area takes only presses on its text, so while it holds a selection a press anywhere else in the window ends it,
    // on the release: a button there, such as one acting on the selection, runs first. Only then is a monitor installed.
    private func updateClickAway() {
      let wanted = isArea && window != nil && model.selectedRange != nil
      if wanted, clickAway == nil {
        clickAway = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
          MainActor.assumeIsolated {
            if let self, event.window === self.window { self.releasedAway() }
          }
          return event
        }
      } else if wanted == false, let clickAway {
        NSEvent.removeMonitor(clickAway)
        self.clickAway = nil
      }
    }

    private func releasedAway() {
      if ownsPress {
        ownsPress = false
        return
      }
      guard model.selectedRange != nil else { return }
      DispatchQueue.main.async { [weak self] in
        self?.resetSelection()
      }
    }

    override func updateTrackingAreas() {
      super.updateTrackingAreas()
      trackingAreas.forEach(removeTrackingArea)
      guard isArea else { return }
      addTrackingArea(
        NSTrackingArea(
          rect: .zero,
          options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
          owner: self
        )
      )
    }

    override func mouseMoved(with event: NSEvent) {
      guard isArea else {
        super.mouseMoved(with: event)
        return
      }
      let location = convert(event.locationInWindow, from: nil)
      if exclusionRects.contains(where: { $0.contains(location) }) == false, model.isText(at: location) {
        (model.url(for: location) != nil ? NSCursor.pointingHand : NSCursor.iBeam).set()
        showsTextCursor = true
      } else if showsTextCursor {
        NSCursor.arrow.set()
        showsTextCursor = false
      }
    }

    override func mouseExited(with event: NSEvent) {
      guard isArea else {
        super.mouseExited(with: event)
        return
      }
      if showsTextCursor {
        NSCursor.arrow.set()
        showsTextCursor = false
      }
    }

    override func mouseDown(with event: NSEvent) {
      if isArea == false {
        window?.makeFirstResponder(self)
      }
      let location = convert(event.locationInWindow, from: nil)
      pressedAt = nil
      isDragging = false
      ownsPress = isArea

      switch event.clickCount {
      case 1:
        if let url = model.url(for: location) {
          openURL(url)
        } else {
          resetSelection()
          if isArea { pressedAt = event }
        }
        dragStart = model.closestPosition(to: location)
      case 2:
        if let position = model.closestPosition(to: location) {
          model.selectedRange = model.wordRange(for: position)
        }
        dragStart = nil
      case 3:
        if let position = model.closestPosition(to: location) {
          model.selectedRange = model.blockRange(for: position)
        }
        dragStart = nil
      default:
        break
      }
      if isArea, model.selectedRange != nil {
        window?.makeFirstResponder(self)
      }
    }

    override func mouseDragged(with event: NSEvent) {
      guard let dragStart else {
        return
      }

      let location = convert(event.locationInWindow, from: nil)

      if let pressedAt, isDragging == false {
        guard Self.isDrag(from: convert(pressedAt.locationInWindow, from: nil), to: location) else { return }
        isDragging = true
      }

      guard let currentPosition = model.closestPosition(to: location) else {
        return
      }

      model.selectedRange = TextRange(from: dragStart, to: currentPosition)
      if isArea, window?.firstResponder !== self, model.selectedRange != nil {
        window?.makeFirstResponder(self)
      }
      autoscroll(with: event)
    }

    override func mouseUp(with event: NSEvent) {
      dragStart = nil
      if let pressedAt, isDragging == false {
        passOn(pressedAt, event)
      }
      pressedAt = nil
      isDragging = false
    }

    // A hand's tremor during a click moves the pointer a point or two.
    static func isDrag(from start: CGPoint, to end: CGPoint) -> Bool {
      hypot(end.x - start.x, end.y - start.y) > 3
    }

    // Sent once the release the layer took has gone through: sent within it, a SwiftUI button under the text took the click
    // only the first time. The hit test steps aside until the click is through, so it can't come back to the layer.
    // Only to SwiftUI-drawn content: an AppKit control under the text tracks a press in its own loop, and a pop-up would
    // open its menu.
    private func passOn(_ down: NSEvent, _ up: NSEvent) {
      guard window != nil else { return }
      isHandingOn = true
      handedOn = (down, up)
      DispatchQueue.main.async { [weak self] in
        self?.handOn()
      }
    }

    private func handOn() {
      defer {
        isHandingOn = false
        handedOn = nil
      }
      guard let (down, up) = handedOn, let window, window.windowNumber == down.windowNumber, let content = window.contentView
      else { return }
      guard Self.handsClick(to: content.hitTest(content.superview?.convert(down.locationInWindow, from: nil) ?? down.locationInWindow))
      else { return }
      window.sendEvent(down)
      window.sendEvent(up)
    }

    static func handsClick(to hit: NSView?) -> Bool {
      guard let hit else { return false }
      return (hit is NSControl) == false
    }

    override func rightMouseDown(with event: NSEvent) {
      let location = convert(event.locationInWindow, from: nil)
      updateSelectionForContextMenu(at: location)

      NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: self)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
      let location = convert(event.locationInWindow, from: nil)
      updateSelectionForContextMenu(at: location)

      return makeContextMenu()
    }

    override func selectAll(_ sender: Any?) {
      model.selectedRange = TextRange(start: model.startPosition, end: model.endPosition)
    }

    override func keyDown(with event: NSEvent) {
      interpretKeyEvents([event])
    }

    override func moveRightAndModifySelection(_ sender: Any?) {
      modifySelection { position, _ in
        model.position(from: position, offset: 1)
      }
    }

    override func moveLeftAndModifySelection(_ sender: Any?) {
      modifySelection { position, _ in
        model.position(from: position, offset: -1)
      }
    }

    override func moveUpAndModifySelection(_ sender: Any?) {
      modifySelection { position, anchor in
        model.positionAbove(position, anchor: anchor)
      }
    }

    override func moveDownAndModifySelection(_ sender: Any?) {
      modifySelection { position, anchor in
        model.positionBelow(position, anchor: anchor)
      }
    }

    override func moveWordRightAndModifySelection(_ sender: Any?) {
      modifySelection { position, _ in
        model.nextWord(from: position)
      }
    }

    override func moveWordLeftAndModifySelection(_ sender: Any?) {
      modifySelection { position, _ in
        model.previousWord(from: position)
      }
    }

    override func moveParagraphBackwardAndModifySelection(_ sender: Any?) {
      modifySelection { position, _ in
        model.blockStart(for: position)
      }
    }

    override func moveParagraphForwardAndModifySelection(_ sender: Any?) {
      modifySelection { position, _ in
        model.blockEnd(for: position)
      }
    }

    private func updateSelectionForContextMenu(at location: CGPoint) {
      guard let position = model.closestPosition(to: location) else {
        resetSelection()
        return
      }

      if let selectedRange = model.selectedRange, selectedRange.contains(position) {
        // do nothing
        return
      }

      model.selectedRange = model.wordRange(for: position)
    }

    private func makeContextMenu() -> NSMenu {
      let contextMenu = NSMenu()

      guard let selectedRange = model.selectedRange, !selectedRange.isCollapsed else {
        return contextMenu
      }

      // Get the localized title for the share action
      let sharingPicker = NSSharingServicePicker(items: [])
      let shareActionTitle = sharingPicker.standardShareMenuItem.title

      // Get the localized title for the copy action
      let copyActionTitle =
        if let defaultMenu = NSTextView.defaultMenu,
          let copyAction = defaultMenu.items.first(where: { $0.action == #selector(copy(_:)) })
        {
          copyAction.title
        } else {
          NSLocalizedString("Copy", bundle: .main, comment: "")
        }

      contextMenu.addItem(
        .init(
          title: shareActionTitle,
          action: #selector(share(_:)),
          keyEquivalent: ""
        )
      )
      contextMenu.addItem(.separator())
      contextMenu.addItem(
        .init(
          title: copyActionTitle,
          action: #selector(copy(_:)),
          keyEquivalent: ""
        )
      )

      return contextMenu
    }

    private func modifySelection(
      _ transform: (_ position: TextPosition, _ anchor: TextPosition) -> TextPosition?
    ) {
      guard let selectedRange = model.selectedRange else {
        return
      }

      // set anchor on first move
      selectionAnchor = selectionAnchor ?? selectedRange.start

      guard let selectionAnchor else {
        return
      }

      // modify the non-anchor end of the selection
      let position =
        selectionAnchor == selectedRange.start
        ? selectedRange.end
        : selectedRange.start

      guard let newPosition = transform(position, selectionAnchor) else {
        return
      }
      model.selectedRange = TextRange(from: selectionAnchor, to: newPosition)

      // scroll to make the new position visible
      let caretRect = model.caretRect(for: newPosition)
      scrollToVisible(caretRect)
    }

    private func resetSelection() {
      model.selectedRange = nil
      selectionAnchor = nil
    }

    @objc private func share(_ sender: Any?) {
      guard let selectedRange = model.selectedRange else {
        return
      }

      let attributedText = model.attributedText(in: selectedRange)
      let transferableText = TransferableText(attributedString: attributedText)
      let itemProvider = NSItemProvider(object: transferableText)

      let sharingPicker = NSSharingServicePicker(items: [itemProvider])
      let rect =
        model.selectionRects(for: selectedRange)
        .last?.rect.integral ?? .zero

      sharingPicker.show(relativeTo: rect, of: self, preferredEdge: .maxY)
    }

    @objc private func copy(_ sender: Any?) {
      guard let selectedRange = model.selectedRange else {
        return
      }

      let attributedText = model.attributedText(in: selectedRange)

      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()

      let formatter = Formatter(attributedText)
      pasteboard.setString(formatter.plainText(), forType: .string)
      pasteboard.setString(formatter.html(), forType: .html)
    }
  }

  extension NSTextInteractionView: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
      switch item.action {
      case #selector(selectAll(_:)):
        return model.hasText
      case #selector(copy(_:)):
        guard let selectedRange = model.selectedRange else {
          return false
        }
        return !selectedRange.isCollapsed
      case #selector(moveRightAndModifySelection(_:)),
        #selector(moveLeftAndModifySelection(_:)),
        #selector(moveUpAndModifySelection(_:)),
        #selector(moveDownAndModifySelection(_:)),
        #selector(moveWordRightAndModifySelection(_:)),
        #selector(moveWordLeftAndModifySelection(_:)),
        #selector(moveParagraphBackwardAndModifySelection(_:)),
        #selector(moveParagraphForwardAndModifySelection(_:)):
        return model.selectedRange != nil
      default:
        return true
      }
    }
  }
#endif
