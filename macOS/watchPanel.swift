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
    private let viewModel: ViewModel
    fileprivate let backView: NSVisualEffectView
    fileprivate let controlBar: OptionView
    fileprivate var settingWindow: NSWindow?
    private var buttonSize: NSSize {
        let shortEdge = min(viewModel.watchLayout.baseLayout.offsets.watchSize.width, viewModel.watchLayout.baseLayout.offsets.watchSize.height)
        let ratio = 80 * 2.3 / (shortEdge / 2)
        return NSSize(width: 32 / ratio, height: 32 / ratio)
    }

    var isPresented: Bool {
        get {
            _isPresented
        } set {
            _isPresented = newValue
            self.present()
        }
    }

    init(statusItem: NSStatusItem, viewModel: ViewModel, isPresented: Bool) {
        self._isPresented = isPresented
        self.statusItem = statusItem
        self.viewModel = viewModel
        self.controlBar = OptionView(frame: NSRect.zero)

        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.wantsLayer = true
        backView = blurView

        super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
        controlBar.setting.target = self
        controlBar.close.target = self
        controlBar.close.action = #selector(closeApp(_:))
        self.alphaValue = 1
        self.level = NSWindow.Level.floating
        self.hasShadow = true
        self.isOpaque = false
        self.backgroundColor = .clear
        contentView = NSView()
        contentView?.addSubview(backView)
        contentView?.addSubview(controlBar)
        self.autoUpdatePanelPosition()
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
            let baseLayout = viewModel.baseLayout
            var frame = NSRect(x: statusItemFrame.midX - baseLayout.offsets.watchSize.width / 2,
                               y: statusItemFrame.minY - baseLayout.offsets.watchSize.height - buttonSize.height * 1.7 - 6,
                               width: baseLayout.offsets.watchSize.width,
                               height: baseLayout.offsets.watchSize.height + buttonSize.height * 1.7)
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
            controlBar.frame = NSRect(x: bounds.width * 0.5 - buttonSize.width * 1.3, y: buttonSize.height * 0.25, width: buttonSize.width * 2.6, height: buttonSize.height)
        }
    }

    func autoUpdatePanelPosition() {
        withObservationTracking {
            panelPosition()
        } onChange: {
            Task { @MainActor in
                self.autoUpdatePanelPosition()
            }
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

    init(watch: WatchView, setting: SettingView, statusItem: NSStatusItem, viewModel: ViewModel, isPresented: Bool) {
        watchView = NSHostingView(rootView: watch)
        settingView = NSHostingController(rootView: setting)
        super.init(statusItem: statusItem, viewModel: viewModel, isPresented: isPresented)
        controlBar.setting.action = #selector(openSetting(_:))
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
    let setting: NSButton
    let close: NSButton
    override var frame: NSRect {
        didSet {
            self.background.frame = self.bounds
            setting.frame = NSRect(x: bounds.height - bounds.width * 0.5, y: 0, width: bounds.width - bounds.height, height: bounds.height)
            setting.font = setting.font?.withSize(bounds.height * 0.5)
            close.frame = NSRect(x: bounds.width * 0.5, y: 0, width: bounds.width - bounds.height, height: bounds.height)
            close.font = close.font?.withSize(bounds.height * 0.5)
            (background.layer?.mask as? CAShapeLayer)?.path = Capsule(style: .continuous).path(in: background.frame).cgPath
        }
    }

    override init(frame frameRect: NSRect) {
        let background = NSVisualEffectView(frame: frameRect)
        background.blendingMode = .behindWindow
        background.material = .hudWindow
        background.state = .active
        background.wantsLayer = true
        let optionMask = CAShapeLayer()
        optionMask.path = Capsule().path(in: background.bounds).cgPath
        background.layer?.mask = optionMask

        let setting = NSButton(frame: frameRect)
        setting.alignment = .center
        setting.isBordered = false
        setting.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Setting")
        setting.contentTintColor = .controlTextColor

        let close = NSButton(frame: frameRect)
        close.alignment = .center
        close.isBordered = false
        close.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Quit")
        close.contentTintColor = .systemRed

        self.background = background
        self.setting = setting
        self.close = close
        super.init(frame: frameRect)
        addSubview(self.background)
        addSubview(self.setting)
        addSubview(self.close)
    }

    required init?(coder: NSCoder) {
         fatalError("Not implemented")
     }
 }
