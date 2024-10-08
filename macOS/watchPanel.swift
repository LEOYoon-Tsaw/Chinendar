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
    private let baseLayout: BaseLayout
    fileprivate let backView: NSVisualEffectView
    fileprivate let settingButton: OptionView
    fileprivate let closeButton: OptionView
    fileprivate var settingWindow: NSWindow?
    private var buttonSize: NSSize {
        let ratio = 80 * 2.3 / (baseLayout.watchSize.width / 2)
        return NSSize(width: 80 / ratio, height: 30 / ratio)
    }

    var isPresented: Bool {
        get {
            _isPresented
        } set {
            _isPresented = newValue
            self.present()
        }
    }

    init(statusItem: NSStatusItem, baseLayout: BaseLayout, isPresented: Bool) {
        self._isPresented = isPresented
        self.statusItem = statusItem
        self.baseLayout = baseLayout

        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.wantsLayer = true
        backView = blurView

        self.settingButton = {
            let view = OptionView(frame: NSRect.zero)
            view.button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Setting")
            view.button.contentTintColor = .controlTextColor
            return view
        }()
        self.closeButton = {
            let view = OptionView(frame: NSRect.zero)
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
            var frame = NSRect(x: statusItemFrame.midX - baseLayout.watchSize.width / 2,
                               y: statusItemFrame.minY - baseLayout.watchSize.height - buttonSize.height * 1.7 - 6,
                               width: baseLayout.watchSize.width,
                               height: baseLayout.watchSize.height + buttonSize.height * 1.7)
            if frame.maxX >= windowRect.maxX {
                frame.origin.x = windowRect.maxX - frame.width
            } else if frame.minX <= windowRect.minX {
                frame.origin.x = windowRect.minX
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
            settingButton.frame = NSRect(x: bounds.width / 2 - buttonSize.width * 1.5, y: buttonSize.height / 2, width: buttonSize.width, height: buttonSize.height)
            settingButton.button.font = settingButton.button.font?.withSize(buttonSize.height / 2)
            closeButton.frame = NSRect(x: bounds.width / 2 + buttonSize.width * 0.5, y: buttonSize.height / 2, width: buttonSize.width, height: buttonSize.height)
            closeButton.button.font = closeButton.button.font?.withSize(buttonSize.height / 2)
        }
    }

    private func getCurrentScreen() -> NSRect {
        var screenRect = NSScreen.main!.frame
        let screens = NSScreen.screens
        for i in 0 ..< screens.count {
            let rect = screens[i].frame
            if let statusBarFrame = statusItem.button?.window?.frame, rect.contains(NSPoint(x: statusBarFrame.midX, y: statusBarFrame.midY)) {
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

    init(watch: WatchView, setting: SettingView, statusItem: NSStatusItem, baseLayout: BaseLayout, isPresented: Bool) {
        watchView = NSHostingView(rootView: watch)
        settingView = NSHostingController(rootView: setting)
        super.init(statusItem: statusItem, baseLayout: baseLayout, isPresented: isPresented)
        settingButton.button.action = #selector(openSetting(_:))
        contentView?.addSubview(watchView)
    }

    override func panelPosition() {
        super.panelPosition()
        watchView.frame = backView.frame
    }

    @objc func openSetting(_ sender: NSButton) {
        if settingWindow == nil || !settingWindow!.isVisible {
            settingWindow?.close()
            settingWindow = nil
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

private final class OptionView: NSView {
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
