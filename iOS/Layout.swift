//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import UIKit

class WatchLayout: MetaWatchLayout {
    var textFont: UIFont
    var centerFont: UIFont
    
    override init() {
        textFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        centerFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)
        super.init()
    }
}

class ColorWell: UIColorWell {
    var index: Int!
    
    @objc func dragged(_ sender: UIPanGestureRecognizer) {
        guard let slider = self.superview as? GradientSlider else { return }
        let translation = sender.translation(in: slider)
        self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: slider)
        if sender.state == .ended {
            if slider.bounds.contains(self.center) || slider.controls.count <= 2 {
                self.frame = CGRect(x: frame.origin.x, y: (slider.bounds.height - frame.height) / 2, width: frame.width, height: frame.height)
                slider.values[index] = (center.x - slider.bounds.origin.x) / (slider.bounds.width - slider.controlRadius * 2)
            } else {
                self.removeFromSuperview()
                slider.removeControl(at: index)
                UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
            }
            slider.updateGradient()
            if let action = slider.action {
                action()
            }
        }
    }
    
    @objc func colorWellChanged(_ sender: Any) {
        guard let slider = self.superview as? GradientSlider else { return }
        if let color = self.selectedColor {
            slider.colors[index] = color
            slider.updateGradient()
            if let action = slider.action {
                action()
            }
        }
    }
}

class GradientSlider: UIControl, UIGestureRecognizerDelegate {
    let minimumValue: CGFloat = 0
    let maximumValue: CGFloat = 1
    var values: [CGFloat] = [0, 1]
    var colors: [UIColor] = [.black, .white]
    internal var controls = [ColorWell]()
    var action: (() -> Void)?
    
    var isLoop = false
    private let trackLayer = CAGradientLayer()
    private var previousLocation: CGPoint? = nil
    internal var controlRadius: CGFloat = 0
    private var dragging = false
    
    var gradient: WatchLayout.Gradient {
        get {
            return WatchLayout.Gradient(locations: values, colors: colors.map{$0.cgColor}, loop: isLoop)
        } set {
            if newValue.isLoop {
                values = newValue.locations.dropLast()
                colors = newValue.colors.dropLast().map { UIColor(cgColor: $0) }
            } else {
                values = newValue.locations
                colors = newValue.colors.map { UIColor(cgColor: $0) }
            }
            isLoop = newValue.isLoop
            updateLayerFrames()
            initializeControls()
            updateGradient()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        layer.addSublayer(trackLayer)
        updateLayerFrames()
        initializeControls()
        updateGradient()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            let ratio = (location.x - bounds.origin.x - controlRadius) / (bounds.width - controlRadius * 2)
            let color = UIColor(cgColor: self.gradient.interpolate(at: ratio))
            addControl(at: ratio, color: color)
            values.append(ratio)
            colors.append(color)
            UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
            updateGradient()
            if let action = action {
                action()
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
            changeChontrols()
        }
    }

    private func addControl(at value: CGFloat, color: UIColor) {
        let control = ColorWell()
        control.frame = CGRect(origin: thumbOriginForValue(value), size: CGSize(width: controlRadius * 2, height: controlRadius * 2))
        control.selectedColor = color
        let panGesture = UIPanGestureRecognizer(target: control, action: #selector(ColorWell.dragged(_:)))
        control.isUserInteractionEnabled = true
        control.addGestureRecognizer(panGesture)
        control.addTarget(control, action: #selector(ColorWell.colorWellChanged(_:)), for: .allEvents)
        controls.append(control)
        control.index = controls.count - 1
        self.addSubview(control)
    }
    
    private func initializeControls() {
        for control in controls.reversed() {
            control.removeFromSuperview()
        }
        controls = []
        for i in 0..<values.count {
            addControl(at: values[i], color: colors[i])
        }
    }
    
    func removeControl(at index: Int) {
        colors.remove(at: index)
        values.remove(at: index)
        controls.remove(at: index)
        for i in index..<controls.count {
            controls[i].index = i
        }
    }
    
    private func changeChontrols() {
        for i in 0..<controls.count {
            controls[i].frame = CGRect(origin: thumbOriginForValue(values[i]), size: CGSize(width: controlRadius * 2, height: controlRadius * 2))
        }
    }
    
    private func updateLayerFrames() {
        trackLayer.frame = bounds.insetBy(dx: bounds.height / 2, dy: bounds.height * 0.42)
        let mask = CAShapeLayer()
        let maskShape = RoundedRect(rect: trackLayer.bounds, nodePos: trackLayer.frame.height / 2, ankorPos: trackLayer.frame.height / 5).path
        mask.path = maskShape
        trackLayer.mask = mask
        controlRadius = bounds.height / 3
        trackLayer.startPoint = CGPoint(x: 0, y: 0)
        trackLayer.endPoint = CGPoint(x: 1, y: 0)
    }
    
    func updateGradient() {
        let gradient = self.gradient
        trackLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
        trackLayer.colors = gradient.colors
    }

    func positionForValue(_ value: CGFloat) -> CGFloat {
        return trackLayer.frame.width * value
    }

    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - controlRadius
        return CGPoint(x: trackLayer.frame.minX + x, y: bounds.height / 2 - controlRadius)
    }
}
