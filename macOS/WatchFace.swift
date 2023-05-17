//
//  watchFace.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import AppKit

class WatchFaceView: NSView {
    static let frameOffset: CGFloat = 5

    let watchLayout: WatchLayout = .shared
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var shape: CAShapeLayer = .init()
    var phase: StartingPhase = .init(zeroRing: 0, firstRing: 0, secondRing: 0, thirdRing: 0, fourthRing: 0)
    var entityNotes: [EntityNote] = []
    var tooltipView: NoteView?
    
    var cornerSize: CGFloat = 0.3
    private var chineseCalendar = ChineseCalendar(time: Date(), timezone: TimeZone.current, location: nil)
    
    var graphicArtifects = GraphicArtifects()
    private var keyStates = KeyStates()
    
    var location: CGPoint? {
        LocationManager.shared.location ?? watchLayout.location
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        layer?.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Need flipped coordinate system, as required by textStorage
    override var isFlipped: Bool {
        true
    }
    
    var isDark: Bool {
        self.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
    
    override func viewDidChangeEffectiveAppearance() {
        layer?.sublayers = nil
        graphicArtifects = GraphicArtifects()
        needsDisplay = true
    }
    
    func update() {
        let time = displayTime ?? Date()
        chineseCalendar.update(time: time, timezone: timezone, location: location)
    }
    
    func drawView(forceRefresh: Bool) {
        layer?.sublayers = nil
        update()
        if forceRefresh {
            graphicArtifects = GraphicArtifects()
        }
        needsDisplay = true
    }
    
    func updateStatusBar(title: String) {
        if String(title.reversed()) != Chinese_Time.statusItem?.button?.title {
            Chinese_Time.updateStatusTitle(title: title)
        }
    }
    
    override func draw(_ rawRect: NSRect) {
        let dirtyRect = rawRect.insetBy(dx: Self.frameOffset, dy: Self.frameOffset)
        if graphicArtifects.outerBound == nil {
            let shortEdge = min(dirtyRect.width, dirtyRect.height)
            shape.path = RoundedRect(rect: dirtyRect, nodePos: shortEdge * 0.08, ankorPos: shortEdge * 0.08 * 0.2).path
        }
        entityNotes = (layer!.update(dirtyRect: dirtyRect, isDark: isDark, watchLayout: watchLayout, chineseCalendar: chineseCalendar, graphicArtifects: graphicArtifects, keyStates: keyStates, phase: phase))
        updateStatusBar(title: "\(chineseCalendar.dateString) \(chineseCalendar.timeString)")
    }
    
    override func rightMouseUp(with event: NSEvent) {
        let shortEdge = min(bounds.width, bounds.height)
        let point = convert(event.locationInWindow, from: nil)
        var entities = [EntityNote]()
        for entity in entityNotes {
            let diff = point - entity.position
            let dist = sqrt(diff.x * diff.x + diff.y * diff.y)
            if dist.isFinite && dist < GraphicArtifects.markRadius * 2 * shortEdge {
                entities.append(entity)
            }
        }
        if let contentView = window?.contentView, entities.count > 0 {
            let width = CGFloat(entities.count) * (NSFont.systemFontSize + 6) + 8
            let height = CGFloat(entities.map { $0.name.count }.reduce(0) { max($0, $1) }) * (NSFont.systemFontSize + 2) + 32
            let frame = CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height)
            var newFrame = convert(frame, to: contentView)
            
            if newFrame.maxX > contentView.bounds.maxX - Self.frameOffset {
                newFrame.origin.x -= newFrame.maxX - contentView.bounds.maxX + Self.frameOffset
            }
            if newFrame.maxY > contentView.bounds.maxY - Self.frameOffset {
                newFrame.origin.y -= newFrame.maxY - contentView.bounds.maxY + Self.frameOffset
            }
            if newFrame.minX >= contentView.bounds.minX + Self.frameOffset && newFrame.minY >= contentView.bounds.minY + Self.frameOffset {
                let tooltip = NoteView(frame: newFrame, entities: entities)
                tooltip.shadow = { () -> NSShadow in
                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = 5
                    shadow.shadowOffset = CGSize(width: 3, height: -3)
                    shadow.shadowColor = .black.withAlphaComponent(0.2)
                    return shadow
                }()
                tooltipView?.removeFromSuperview()
                contentView.addSubview(tooltip)
                tooltipView = tooltip
            }
        }
        super.rightMouseUp(with: event)
    }
}

class NoteView: NSView {
    private var visualEffectView: NSVisualEffectView!
    private var entities: [EntityNote] = []
    
    init(frame frameRect: NSRect, entities: [EntityNote]) {
        self.entities = entities
        super.init(frame: frameRect)
        setupView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 1
        }
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                self.animator().alphaValue = 0
            }) {
                self.removeFromSuperview()
            }
        }
    }
    
    private func setupView() {
        visualEffectView = NSVisualEffectView(frame: bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.blendingMode = .withinWindow
        visualEffectView.state = .active
        addSubview(visualEffectView)
        
        visualEffectView.wantsLayer = true
        let mask = CAShapeLayer()
        mask.path = RoundedRect(rect: visualEffectView.frame, nodePos: 10, ankorPos: 2).path
        visualEffectView.layer?.mask = mask
        
        var lastView: NSView? = nil
        for entity in entities.reversed() {
            let entityView = createEntityView(for: entity)
            visualEffectView.addSubview(entityView)
            
            entityView.translatesAutoresizingMaskIntoConstraints = false
            if let lastView = lastView {
                entityView.trailingAnchor.constraint(equalTo: lastView.leadingAnchor, constant: -4).isActive = true
            } else {
                entityView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -6).isActive = true
            }
            entityView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 6).isActive = true
            entityView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -6).isActive = true
            entityView.widthAnchor.constraint(equalToConstant: NSFont.systemFontSize + 2).isActive = true
            
            lastView = entityView
        }
    }
    
    private func createEntityView(for entity: EntityNote) -> NSView {
        let view = NSView()
        
        let colorMark = NSView()
        colorMark.wantsLayer = true
        colorMark.layer?.backgroundColor = entity.color
        let mask = CAShapeLayer()
        mask.path = RoundedRect(rect: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)), nodePos: 6 * 0.7, ankorPos: 6 * 0.3).path
        colorMark.layer?.mask = mask
        view.addSubview(colorMark)
        
        let label = NSTextField(labelWithString: entity.name.map { String($0) }.joined(separator: "\n"))
        label.alignment = .right
        view.addSubview(label)
        
        colorMark.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorMark.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1),
            colorMark.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            colorMark.widthAnchor.constraint(equalToConstant: 12),
            colorMark.heightAnchor.constraint(equalToConstant: 12),
            
            label.topAnchor.constraint(equalTo: colorMark.bottomAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
}

class OptionView: NSView {
    let background: NSVisualEffectView
    let button: NSButton
    override var frame: NSRect {
        didSet {
            self.background.frame = self.bounds
            self.button.frame = self.bounds
            (background.layer?.mask as? CAShapeLayer)?.path = RoundedRect(rect: background.bounds, nodePos: background.bounds.height / 2, ankorPos: background.bounds.height / 2 * 0.2).path
        }
    }

    override init(frame frameRect: NSRect) {
        let background = NSVisualEffectView(frame: frameRect)
        background.blendingMode = .behindWindow
        background.material = .popover
        background.state = .active
        background.wantsLayer = true
        let optionMask = CAShapeLayer()
        optionMask.path = RoundedRect(rect: background.bounds, nodePos: background.bounds.height / 2, ankorPos: background.bounds.height / 2 * 0.2).path
        background.layer?.mask = optionMask
        
        let button = NSButton(frame: frameRect)
        button.alignment = .center
        button.isBordered = false
        
        self.background = background
        self.button = button
        super.init(frame: frameRect)
        addSubview(self.background)
        addSubview(self.button)
    }
    
    required init?(coder: NSCoder) {
        self.background = NSVisualEffectView()
        self.button = NSButton()
        super.init(coder: coder)
    }
    
    var title: String {
        get {
            button.title
        } set {
            button.title = newValue
        }
    }

    var image: NSImage? {
        get {
            button.image
        } set {
            button.image = newValue
        }
    }

    var action: Selector? {
        get {
            button.action
        } set {
            button.action = newValue
        }
    }

    var target: AnyObject? {
        get {
            button.target
        } set {
            button.target = newValue
        }
    }
}

class WatchFace: NSPanel {
    let _view: WatchFaceView
    let _backView: NSVisualEffectView
    let _settingButton: OptionView
    let _helpButton: OptionView
    let _closingButton: OptionView
    private var _timer: Timer?
    static var currentInstance: WatchFace? = nil
    private static let updateInterval: CGFloat = 14.4
    var buttonSize: NSSize {
        let ratio = 80 * 2.3 / (WatchLayout.shared.watchSize.width / 2)
        return NSMakeSize(60 / ratio, 30 / ratio)
    }
    
    init(position: NSRect) {
        self._view = WatchFaceView(frame: position)
        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .popover
        blurView.state = .active
        blurView.wantsLayer = true
        self._backView = blurView
        self._settingButton = {
            let view = OptionView(frame: NSZeroRect)
            view.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Setting")
            view.button.contentTintColor = .systemGray
            return view
        }()
        self._helpButton = {
            let view = OptionView(frame: NSZeroRect)
            view.image = NSImage(systemSymbolName: "info.bubble", accessibilityDescription: "Help")
            view.button.contentTintColor = .systemGray
            return view
        }()
        self._closingButton = {
            let view = OptionView(frame: NSZeroRect)
            view.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Quit")
            view.button.contentTintColor = .systemRed
            return view
        }()
        super.init(contentRect: position, styleMask: .borderless, backing: .buffered, defer: true)
        _settingButton.target = self
        _settingButton.action = #selector(openSetting(_:))
        _helpButton.target = self
        _helpButton.action = #selector(openHelp(_:))
        _closingButton.target = self
        _closingButton.action = #selector(closeApp(_:))
        self.alphaValue = 1
        self.level = NSWindow.Level.floating
        self.hasShadow = true
        self.isOpaque = false
        self.backgroundColor = .clear
        let contentView = NSView()
        self.contentView = contentView
        contentView.addSubview(_backView)
        contentView.addSubview(_view)
        contentView.addSubview(_settingButton)
        contentView.addSubview(_helpButton)
        contentView.addSubview(_closingButton)
        self.isMovableByWindowBackground = false
    }
    
    @objc func openSetting(_ sender: NSButton) {
        if let congigurationView = ConfigurationViewController.currentInstance {
            congigurationView.view.window?.close()
        } else {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let windowController = storyboard.instantiateController(withIdentifier: "WindowController") as! NSWindowController
            if let window = windowController.window {
                let viewController = window.contentViewController as! ConfigurationViewController
                ConfigurationViewController.currentInstance = viewController
                windowController.showWindow(nil)
            }
        }
    }

    @objc func openHelp(_ sender: NSButton) {
        if let helperView = HelpViewController.currentInstance {
            helperView.view.window?.close()
        } else {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let windowController = storyboard.instantiateController(withIdentifier: "HelpWindow") as! NSWindowController
            if let window = windowController.window {
                let viewController = window.contentViewController as! HelpViewController
                HelpViewController.currentInstance = viewController
                windowController.showWindow(nil)
            }
        }
    }

    @objc func closeApp(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
    
    override var isVisible: Bool {
        get {
            contentView != nil && !contentView!.isHidden
        } set {
            contentView?.isHidden = !newValue
        }
    }
    
    func setCenter() {
        let windowRect = getCurrentScreen()
        setFrame(NSMakeRect(
            windowRect.midX - WatchLayout.shared.watchSize.width / 2,
            windowRect.midY - WatchLayout.shared.watchSize.height / 2 - buttonSize.height * 0.85,
            WatchLayout.shared.watchSize.width,
            WatchLayout.shared.watchSize.height + buttonSize.height * 1.7), display: true)
    }

    func moveTopCenter(to: CGPoint) {
        let windowRect = getCurrentScreen()
        var frame = NSMakeRect(
            to.x - WatchLayout.shared.watchSize.width / 2,
            to.y - WatchLayout.shared.watchSize.height - buttonSize.height * 1.7,
            WatchLayout.shared.watchSize.width,
            WatchLayout.shared.watchSize.height + buttonSize.height * 1.7)
        if NSMaxX(frame) >= NSMaxX(windowRect) {
            frame.origin.x = NSMaxX(windowRect) - frame.width
        } else if NSMinX(frame) <= NSMinX(windowRect) {
            frame.origin.x = NSMinX(windowRect)
        }
        setFrame(frame, display: true)
    }
    
    func getCurrentScreen() -> NSRect {
        var screenRect = NSScreen.main!.frame
        let screens = NSScreen.screens
        for i in 0 ..< screens.count {
            let rect = screens[i].frame
            if let statusBarFrame = Chinese_Time.statusItem?.button?.window?.frame, NSPointInRect(NSMakePoint(statusBarFrame.midX, statusBarFrame.midY), rect) {
                screenRect = rect
                break
            }
        }
        return screenRect
    }
    
    func updateSize() {
        let watchDimension = WatchLayout.shared.watchSize
        let buttonSize = buttonSize
        if frame.isEmpty {
            setCenter()
        } else {
            setFrame(NSMakeRect(
                frame.midX - watchDimension.width / 2,
                frame.midY - watchDimension.height / 2 - buttonSize.height * 0.85,
                watchDimension.width, watchDimension.height + buttonSize.height * 1.7), display: true)
        }

        var bounds = _view.superview!.bounds
        bounds.origin.y += buttonSize.height * 1.7
        bounds.size.height -= buttonSize.height * 1.7
        _view.frame = bounds
        _backView.frame = bounds
        _settingButton.frame = NSMakeRect(bounds.width / 2 - buttonSize.width * 2, buttonSize.height / 2, buttonSize.width, buttonSize.height)
        _settingButton.button.font = _settingButton.button.font?.withSize(buttonSize.height / 2)
        _helpButton.frame = NSMakeRect(bounds.width / 2 - buttonSize.width * 0.5, buttonSize.height / 2, buttonSize.width, buttonSize.height)
        _helpButton.button.font = _helpButton.button.font?.withSize(buttonSize.height / 2)
        _closingButton.frame = NSMakeRect(bounds.width / 2 + buttonSize.width, buttonSize.height / 2, buttonSize.width, buttonSize.height)
        _closingButton.button.font = _closingButton.button.font?.withSize(buttonSize.height / 2)
        _view.cornerSize = WatchLayout.shared.cornerRadiusRatio * min(watchDimension.width, watchDimension.height)
    }
    
    func show() {
        updateSize()
        _view.drawView(forceRefresh: true)
        invalidateShadow()
        _view.drawView(forceRefresh: false)
        _backView.layer?.mask = _view.shape
        orderFront(nil)
        isVisible = true
        _timer = Timer.scheduledTimer(withTimeInterval: Self.updateInterval, repeats: true) { _ in
            self.invalidateShadow()
            self._view.drawView(forceRefresh: false)
        }
        Self.currentInstance = self
    }
    
    func hide() {
        isVisible = false
    }
    
    override func close() {
        _timer?.invalidate()
        _timer = nil
        Self.currentInstance = nil
        super.close()
    }
}
