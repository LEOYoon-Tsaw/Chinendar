//
//  WatchPanel.swift
//  Chinendar
//
//  Created by Leo Liu on 8/1/23.
//

import SwiftUI

class WatchPanel: NSPanel {
    private var _isPresented: Bool
    private let statusItem: NSStatusItem
    private let watchLayout = WatchLayout.shared
    fileprivate let backView: NSVisualEffectView
    fileprivate let settingButton: OptionView
    fileprivate let closeButton: OptionView
    fileprivate var settingWindow: NSWindow?
    private var buttonSize: NSSize {
        let ratio = 80 * 2.3 / (watchLayout.watchSize.width / 2)
        return NSMakeSize(80 / ratio, 30 / ratio)
    }

    var isPresented: Bool {
        get {
            _isPresented
        } set {
            _isPresented = newValue
            self.present()
        }
    }
    
    init(statusItem: NSStatusItem, isPresented: Bool) {
        self._isPresented = isPresented
        self.statusItem = statusItem
        
        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.wantsLayer = true
        backView = blurView
        
        self.settingButton = {
            let view = OptionView(frame: NSZeroRect)
            view.button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Setting")
            view.button.contentTintColor = .controlTextColor
            return view
        }()
        self.closeButton = {
            let view = OptionView(frame: NSZeroRect)
            view.button.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Quit")
            view.button.contentTintColor = .systemRed
            return view
        }()
        super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
        settingButton.button.target = self
        closeButton.button.target = self
        closeButton.button.action = #selector(closeApp(_:))
        self.alphaValue = 1
        self.level = NSWindow.Level.floating
        self.hasShadow = true
        self.isOpaque = false
        self.backgroundColor = .clear
        contentView = NSView()
        contentView?.addSubview(backView)
        contentView?.addSubview(settingButton)
        contentView?.addSubview(closeButton)
    }

    private func present() {
        if _isPresented {
            self.panelPosition()
            self.orderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            self.close()
        }
    }
    
    func panelPosition() {
        if let statusItemFrame = statusItem.button?.window?.frame {
            let windowRect = getCurrentScreen()
            var frame = NSMakeRect(
                statusItemFrame.midX - watchLayout.watchSize.width / 2,
                statusItemFrame.minY - watchLayout.watchSize.height - buttonSize.height * 1.7 - 6,
                watchLayout.watchSize.width,
                watchLayout.watchSize.height + buttonSize.height * 1.7)
            if NSMaxX(frame) >= NSMaxX(windowRect) {
                frame.origin.x = NSMaxX(windowRect) - frame.width
            } else if NSMinX(frame) <= NSMinX(windowRect) {
                frame.origin.x = NSMinX(windowRect)
            }
            setFrame(frame, display: true)
            var bounds = contentView!.bounds
            bounds.size.height -= buttonSize.height * 1.7
            let shortEdge = min(bounds.width, bounds.height)
            let mask = CAShapeLayer()
            mask.path = RoundedRect(rect: bounds, nodePos: shortEdge * 0.08, ankorPos: shortEdge * 0.08 * 0.2).path
            backView.layer?.mask = mask
            bounds.origin.y += buttonSize.height * 1.7
            backView.frame = bounds
            settingButton.frame = NSMakeRect(bounds.width / 2 - buttonSize.width * 1.5, buttonSize.height / 2, buttonSize.width, buttonSize.height)
            settingButton.button.font = settingButton.button.font?.withSize(buttonSize.height / 2)
            closeButton.frame = NSMakeRect(bounds.width / 2 + buttonSize.width * 0.5, buttonSize.height / 2, buttonSize.width, buttonSize.height)
            closeButton.button.font = closeButton.button.font?.withSize(buttonSize.height / 2)
        }
    }
    
    private func getCurrentScreen() -> NSRect {
        var screenRect = NSScreen.main!.frame
        let screens = NSScreen.screens
        for i in 0 ..< screens.count {
            let rect = screens[i].frame
            if let statusBarFrame = statusItem.button?.window?.frame, NSPointInRect(NSMakePoint(statusBarFrame.midX, statusBarFrame.midY), rect) {
                screenRect = rect
                break
            }
        }
        return screenRect
    }
    
    @objc func closeApp(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
}

internal final class WatchPanelHosting<WatchView: View, SettingView: View>: WatchPanel {
    private let watchView: NSHostingView<WatchView>
    private let settingView: NSHostingController<SettingView>
    
    init(watch: WatchView, setting: SettingView, statusItem: NSStatusItem, isPresented: Bool) {
        watchView = NSHostingView(rootView: watch)
        settingView = NSHostingController(rootView: setting)
        super.init(statusItem: statusItem, isPresented: isPresented)
        settingButton.button.action = #selector(openSetting(_:))
        contentView?.addSubview(watchView)
    }
    
    override func panelPosition() {
        super.panelPosition()
        watchView.frame = backView.frame
    }
    
    @objc func openSetting(_ sender: NSButton) {
        if settingWindow == nil {
            settingView.sceneBridgingOptions = [.all]
            settingWindow = NSWindow(contentViewController: settingView)
            settingWindow?.styleMask = [.closable, .resizable, .titled, .unifiedTitleAndToolbar, .fullSizeContentView]
            let frame = NSRect(x: frame.minX - 620, y: frame.midY - 200, width: 600, height: 400)
            settingWindow?.setFrame(frame, display: true)
            let controller = NSWindowController(window: settingWindow)
            controller.showWindow(nil)
        } else {
            settingWindow?.close()
            settingWindow = nil
        }
    }
}

fileprivate final class OptionView: NSView {
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
        background.material = .hudWindow
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
         fatalError("Not implemented")
     }
 }
