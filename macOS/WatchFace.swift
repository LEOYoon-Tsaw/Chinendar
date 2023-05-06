//
//  watchFace.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import AppKit

class WatchFaceView: NSView {
    static let frameOffset: CGFloat = 5
    
    static var layoutTemplate: String? = nil
    let watchLayout: WatchLayout
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var realLocation: CGPoint? = nil
    var shape: CAShapeLayer = CAShapeLayer()
    var phase: StartingPhase = StartingPhase(zeroRing: 0, firstRing: 0, secondRing: 0, thirdRing: 0, fourthRing: 0)
    
    var cornerSize: CGFloat = 0.3
    private var chineseCalendar = ChineseCalendar(time: Date(), timezone: TimeZone.current, location: nil)
    
    var graphicArtifects = GraphicArtifects()
    private var keyStates = KeyStates()
    
    var location: CGPoint? {
        realLocation ?? watchLayout.location
    }
    
    override init(frame frameRect: NSRect) {
        if let template = Self.layoutTemplate {
            self.watchLayout = WatchLayout(from: template)
        } else {
            self.watchLayout = WatchLayout()
        }
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.masksToBounds = true
    }

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
        self.layer?.sublayers = nil
        self.graphicArtifects = GraphicArtifects()
        self.needsDisplay = true
    }
    
    func update(forceRefresh: Bool) {
        let time = displayTime ?? Date()
        if forceRefresh || !chineseCalendar.update(time: time, timezone: timezone, location: location) {
            self.chineseCalendar = ChineseCalendar(time: time, timezone: timezone, location: location)
        }
    }
    
    func drawView(forceRefresh: Bool) {
        self.layer?.sublayers = nil
        update(forceRefresh: forceRefresh)
        self.needsDisplay = true
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
            shape.path = RoundedRect(rect: dirtyRect, nodePos: shortEdge * 0.08, ankorPos: shortEdge*0.08*0.2).path
        }
        self.layer?.update(dirtyRect: dirtyRect, isDark: isDark, watchLayout: watchLayout, chineseCalendar: chineseCalendar, graphicArtifects: graphicArtifects, keyStates: keyStates, phase: phase)
        updateStatusBar(title: "\(chineseCalendar.dateString) \(chineseCalendar.timeString)")
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
        self.addSubview(self.background)
        self.addSubview(self.button)
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

class WatchFace: NSWindow {
    let _view: WatchFaceView
    let _backView: NSVisualEffectView
    let _settingButton: OptionView
    let _helpButton: OptionView
    let _closingButton: OptionView
    private var _timer: Timer?
    static var currentInstance: WatchFace? = nil
    private static let updateInterval: CGFloat = 14.4
    var buttonSize: NSSize {
        let ratio = 80 * 2.3 / (self._view.watchLayout.watchSize.width / 2)
        return NSMakeSize(60 / ratio, 30 / ratio)
    }
    
    init(position: NSRect) {
        _view = WatchFaceView(frame: position)
        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .popover
        blurView.state = .active
        blurView.wantsLayer = true
        _backView = blurView
        _settingButton = {
            let view = OptionView(frame: NSZeroRect)
            view.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Setting")
            view.button.contentTintColor = .systemGray
            return view
        }()
        _helpButton = {
            let view = OptionView(frame: NSZeroRect)
            view.image = NSImage(systemSymbolName: "info.bubble", accessibilityDescription: "Help")
            view.button.contentTintColor = .systemGray
            return view
        }()
        _closingButton = {
            let view = OptionView(frame: NSZeroRect)
            view.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Quit")
            view.button.contentTintColor = .systemRed
            return view
        }()
        super.init(contentRect: position, styleMask: .borderless, backing: .buffered, defer: true)
        _settingButton.target = self
        _settingButton.action = #selector(self.openSetting(_:))
        _helpButton.target = self
        _helpButton.action = #selector(self.openHelp(_:))
        _closingButton.target = self
        _closingButton.action = #selector(self.closeApp(_:))
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
        let windowRect = self.getCurrentScreen()
        self.setFrame(NSMakeRect(
            windowRect.midX - _view.watchLayout.watchSize.width / 2,
            windowRect.midY - _view.watchLayout.watchSize.height / 2 - buttonSize.height * 0.85,
            _view.watchLayout.watchSize.width, _view.watchLayout.watchSize.height + buttonSize.height * 1.7), display: true)
    }

    func moveTopCenter(to: CGPoint) {
        let windowRect = self.getCurrentScreen()
        var frame = NSMakeRect(
            to.x - _view.watchLayout.watchSize.width / 2,
            to.y - _view.watchLayout.watchSize.height - buttonSize.height * 1.7,
            _view.watchLayout.watchSize.width, _view.watchLayout.watchSize.height + buttonSize.height * 1.7
        )
        if NSMaxX(frame) >= NSMaxX(windowRect) {
            frame.origin.x = NSMaxX(windowRect) - frame.width
        } else if NSMinX(frame) <= NSMinX(windowRect) {
            frame.origin.x = NSMinX(windowRect)
        }
        self.setFrame(frame, display: true)
    }
    
    func getCurrentScreen() -> NSRect {
        var screenRect = NSScreen.main!.frame
        let screens = NSScreen.screens
        for i in 0..<screens.count {
            let rect = screens[i].frame
            if let statusBarFrame = Chinese_Time.statusItem?.button?.window?.frame, NSPointInRect(NSMakePoint(statusBarFrame.midX, statusBarFrame.midY), rect) {
                screenRect = rect
                break
            }
        }
        return screenRect
    }
    
    func updateSize(with frame: NSRect?) {
        let watchDimension = _view.watchLayout.watchSize
        let buttonSize = buttonSize
        if frame != nil {
            self.setFrame(NSMakeRect(
                            frame!.midX - watchDimension.width / 2,
                            frame!.midY - watchDimension.height / 2 - buttonSize.height * 0.85,
                            watchDimension.width, watchDimension.height + buttonSize.height * 1.7), display: true)
        } else {
            setCenter()
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
        _view.cornerSize = _view.watchLayout.cornerRadiusRatio * min(watchDimension.width, watchDimension.height)
        _view.graphicArtifects = GraphicArtifects()
    }
    
    func show() {
        updateSize(with: nil)
        self.invalidateShadow()
        _view.drawView(forceRefresh: false)
        self._backView.layer?.mask = _view.shape
        self.orderFront(nil)
        self.isVisible = true
        self._timer = Timer.scheduledTimer(withTimeInterval: Self.updateInterval, repeats: true) {_ in
            self.invalidateShadow()
            self._view.drawView(forceRefresh: false)
        }
        Self.currentInstance = self
    }
    
    func hide() {
        self.isVisible = false
    }
    
    override func close() {
        self._timer?.invalidate()
        self._timer = nil
        Self.currentInstance = nil
        super.close()
    }
}
