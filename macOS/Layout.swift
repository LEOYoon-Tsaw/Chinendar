//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import AppKit

class WatchLayout: MetaWatchLayout {
    var textFont: NSFont
    var centerFont: NSFont
    override init() {
        textFont = NSFont.userFont(ofSize: NSFont.systemFontSize)!
        centerFont = NSFontManager.shared.font(withFamily: NSFont.userFont(ofSize: NSFont.systemFontSize)!.familyName!,
                                               traits: .boldFontMask, weight: 900, size: NSFont.systemFontSize)!
        super.init()
    }
    override func encode() -> String {
        var encoded = super.encode()
        encoded += "textFont: \(textFont.fontName)\n"
        encoded += "centerFont: \(centerFont.fontName)\n"
        return encoded
    }
    override func update(from values: Dictionary<String, String>) {
        super.update(from: values)
        if let name = values["textFont"] {
            textFont = NSFont(name: name, size: NSFont.systemFontSize) ?? textFont
        }
        if let name = values["centerFont"] {
            centerFont = NSFont(name: name, size: NSFont.systemFontSize) ?? centerFont
        }
    }
}

class ColorWell: NSColorWell {
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        NSColorPanel.shared.showsAlpha = true
        super.mouseDown(with: event)
    }
    override func resignFirstResponder() -> Bool {
        NSColorPanel.shared.close()
        return super.resignFirstResponder()
    }
}

class GradientSlider: NSControl, NSColorChanging {
    let minimumValue: CGFloat = 0
    let maximumValue: CGFloat = 1
    var values: [CGFloat] = [0, 1]
    var colors: [NSColor] = [.black, .white]
    private var controls = [CAShapeLayer]()
    private var controlsLayer = CALayer()
    
    var isLoop = false
    private let trackLayer = CAGradientLayer()
    private var previousLocation: CGPoint? = nil
    private var movingControl: CAShapeLayer? = nil
    private var movingIndex: Int? = nil
    private var controlRadius: CGFloat = 0
    private var dragging = false
    
    var gradient: WatchLayout.Gradient {
        get {
            return WatchLayout.Gradient(locations: values, colors: colors.map { $0.cgColor }, loop: isLoop)
        } set {
            if newValue.isLoop {
                values = newValue.locations.dropLast()
                colors = newValue.colors.dropLast().map { NSColor(cgColor: $0)! }
            } else {
                values = newValue.locations
                colors = newValue.colors.map { NSColor(cgColor: $0)! }
            }
            isLoop = newValue.isLoop
            updateLayerFrames()
            initializeControls()
            updateGradient()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        layer?.addSublayer(trackLayer)
        layer?.addSublayer(controlsLayer)
        updateLayerFrames()
        initializeControls()
        updateGradient()
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
            changeChontrols()
        }
    }
    
    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }

    private func addControl(at value: CGFloat, color: NSColor) {
        let control = CAShapeLayer()
        control.path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(value), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
        control.fillColor = color.cgColor
        control.shadowPath = control.path
        control.shadowOpacity = 0.3
        control.shadowRadius = 1.5
        control.shadowOffset = NSMakeSize(0, -1)
        control.lineWidth = 2.0
        controls.append(control)
        controlsLayer.addSublayer(control)
    }
    
    private func initializeControls() {
        controlsLayer.sublayers = []
        controls = []
        for i in 0..<values.count {
            addControl(at: values[i], color: colors[i])
        }
    }
    
    private func changeChontrols() {
        for i in 0..<controls.count {
            controls[i].path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(values[i]), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
            controls[i].shadowPath = controls[i].path
        }
    }
    
    private func updateLayerFrames() {
        trackLayer.frame = bounds.insetBy(dx: bounds.height / 2, dy: bounds.height / 3)
        let mask = CAShapeLayer()
        let maskShape = RoundedRect(rect: trackLayer.bounds, nodePos: bounds.height / 6, ankorPos: bounds.height / 6 * 0.2).path
        mask.path = maskShape
        trackLayer.mask = mask
        controlRadius = bounds.height / 3
        trackLayer.startPoint = NSMakePoint(0, 0)
        trackLayer.endPoint = NSMakePoint(1, 0)
    }
    
    func updateGradient() {
        let gradient = self.gradient
        trackLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
        trackLayer.colors = gradient.colors
    }
    
    private func moveControl() {
        if let movingControl = movingControl, let movingIndex = movingIndex {
            movingControl.path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(values[movingIndex]), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
            movingControl.shadowPath = movingControl.path
            updateGradient()
        }
    }

    func positionForValue(_ value: CGFloat) -> CGFloat {
        return trackLayer.frame.width * value
    }

    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - controlRadius
        return CGPoint(x: trackLayer.frame.minX + x, y: bounds.height / 2 - controlRadius)
    }
    
    override func resignFirstResponder() -> Bool {
        movingControl?.strokeColor = nil
        movingControl = nil
        movingIndex = nil
        previousLocation = nil
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        previousLocation = event.locationInWindow
        previousLocation = self.convert(previousLocation!, from: window?.contentView)
        var hit = false
        var i = 0
        for control in controls {
            if control.path!.contains(previousLocation!) {
                movingControl?.strokeColor = nil
                movingControl = control
                movingControl!.strokeColor = NSColor.controlAccentColor.cgColor
                movingIndex = i
                hit = true
            }
            i += 1
        }
        if !hit {
            var newValue = (previousLocation!.x - trackLayer.frame.minX) / trackLayer.frame.width
            newValue = min(max(newValue, minimumValue), maximumValue)
            let color = self.gradient.interpolate(at: newValue)
            values.append(newValue)
            colors.append(NSColor(cgColor: color)!)
            addControl(at: newValue, color: NSColor(cgColor: color)!)
            movingIndex = values.count - 1
            movingControl?.strokeColor = nil
            movingControl = controls.last!
            movingControl!.strokeColor = NSColor.controlAccentColor.cgColor
        }
    }
    override func mouseDragged(with event: NSEvent) {
        dragging = true
        if (movingIndex != nil) && (previousLocation != nil) && (movingIndex! < values.count) {
            var location = event.locationInWindow
            location = self.convert(location, from: window?.contentView)
            let deltaLocation = location.x - previousLocation!.x
            let deltaValue = (maximumValue - minimumValue) * deltaLocation / trackLayer.frame.width
            previousLocation = location
            // Change value
            values[movingIndex!] += deltaValue
            values[movingIndex!] = min(max(values[movingIndex!], minimumValue), maximumValue)
            moveControl()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if !dragging && movingControl != nil && movingIndex != nil {
            NSColorPanel.shared.showsAlpha = true
            let colorPicker = NSColorPanel.shared
            if let currentColor = movingControl?.fillColor {
                colorPicker.color = NSColor(cgColor: currentColor)!
                colorPicker.orderFront(self)
                colorPicker.setTarget(self)
                colorPicker.setAction(#selector(changeColor(_:)))
            }
        }
        dragging = false
        previousLocation = nil
    }
    
    override func keyUp(with event: NSEvent) {
        if event.keyCode == 51 && movingControl != nil && movingIndex != nil && values.count > 2 && colors.count > 2 {
            movingControl?.strokeColor = nil
            movingControl!.removeFromSuperlayer()
            controls.remove(at: movingIndex!)
            values.remove(at: movingIndex!)
            colors.remove(at: movingIndex!)
            movingControl = nil
            movingIndex = nil
            NSColorPanel.shared.close()
            updateGradient()
        }
    }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 51 && movingControl != nil && movingIndex != nil && values.count > 2 && colors.count > 2 {
            return true
        } else {
            return false
        }
    }
    
    @objc func changeColor(_ sender: NSColorPanel?) {
        if movingControl != nil && movingIndex != nil && sender != nil {
            movingControl!.fillColor = sender!.color.cgColor
            colors[movingIndex!] = sender!.color
            updateGradient()
        }
    }
    
}
