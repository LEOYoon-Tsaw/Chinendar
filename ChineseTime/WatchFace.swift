//
//  watchFace.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import AppKit

func +(lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSMakePoint(lhs.x + rhs.x, lhs.y + rhs.y)
}

func -(lhs: NSPoint, rhs: NSPoint) -> NSPoint {
    return NSMakePoint(lhs.x - rhs.x, lhs.y - rhs.y)
}

func *(lhs: NSPoint, rhs: CGFloat) -> NSPoint {
    return NSMakePoint(lhs.x * rhs, lhs.y * rhs)
}

func /(lhs: NSPoint, rhs: CGFloat) -> NSPoint {
    return NSMakePoint(lhs.x / rhs, lhs.y / rhs)
}

class RoundedRect {
    let _boundBox: NSRect
    let _nodePos: CGFloat
    let _ankorPos: CGFloat
    
    init(rect: NSRect, nodePos: CGFloat, ankorPos: CGFloat) {
        _boundBox = rect
        _nodePos = nodePos
        _ankorPos = ankorPos
    }
    
    private func drawPath(vertex: Array<NSPoint>) -> CGMutablePath {
        let path = CGMutablePath()
        var previousPoint = vertex[vertex.count-1]
        var point = vertex[0]
        var nextPoint: NSPoint
        var control1: NSPoint
        var control2: NSPoint
        var target = previousPoint
        var diff: NSPoint
        target.x -= _nodePos
        path.move(to: target)
        for i in 0..<vertex.count {
            previousPoint = vertex[(vertex.count+i-1)%vertex.count]
            point = vertex[i]
            nextPoint = vertex[(i+1)%vertex.count]
            target = point
            control1 = point
            diff = point - previousPoint
            if (abs(diff.x) >= abs(diff.y)) {
                target.x -= diff.x >= 0 ? _nodePos : -_nodePos
                control1.x -= diff.x >= 0 ? _ankorPos : -_ankorPos
            } else {
                target.y -= diff.y >= 0 ? _nodePos : -_nodePos
                control1.y -= diff.y >= 0 ? _ankorPos : -_ankorPos
            }
            path.addLine(to: target)
            target = point
            control2 = point
            diff = nextPoint - point
            if (abs(diff.x) > abs(diff.y)) {
                control2.x += diff.x >= 0 ? _ankorPos : -_ankorPos
                target.x += diff.x >= 0 ? _nodePos : -_nodePos
            } else {
                control2.y += diff.y >= 0 ? _ankorPos : -_ankorPos
                target.y += diff.y >= 0 ? _nodePos : -_nodePos
            }
            path.addCurve(to: target, control1: control1, control2: control2)
        }
        path.closeSubpath()
        return path
    }
    
    var path: CGMutablePath {
        let vertex: Array<NSPoint> = [NSMakePoint(_boundBox.minX, _boundBox.minY),
                                      NSMakePoint(_boundBox.minX, _boundBox.maxY),
                                      NSMakePoint(_boundBox.maxX, _boundBox.maxY),
                                      NSMakePoint(_boundBox.maxX, _boundBox.minY)]
        return drawPath(vertex: vertex)
    }
    
    func shrink(by diameterChange: CGFloat) -> RoundedRect {
        let shortEdgeLength = min(_boundBox.width, _boundBox.height)
        let horizontalShift = diameterChange * (shortEdgeLength - _nodePos) / max(_boundBox.width, _boundBox.height)
        let newNodePos = max(0, min(shortEdgeLength / 2 - diameterChange, _nodePos + horizontalShift - diameterChange))
        let newAnkorPos = max(0, (_ankorPos + 0.55 * diameterChange + 0.31 * horizontalShift) - diameterChange)
        var newBoundBox = _boundBox
        newBoundBox.origin.x += diameterChange
        newBoundBox.origin.y += diameterChange
        newBoundBox.size.width -= 2 * diameterChange
        newBoundBox.size.height -= 2 * diameterChange
        return RoundedRect(rect: newBoundBox, nodePos: newNodePos, ankorPos: newAnkorPos)
    }
    
    func bezierLength(t: CGFloat) -> CGFloat {
        guard _nodePos > 0 else { return 0 }
        let alpha = _ankorPos / _nodePos
        
        var length = -2 * (3 - 3 * t + pow(t, 2))
        length += alpha * (18 - 24 * t + 10 * pow(t, 2) - 3 * pow(t, 3))
        length += 6 * pow(alpha, 2) * (-3 + 5 * t - 3 * pow(t, 2) + pow(t, 3))
        length += pow(alpha, 3) * (6 - 12 * t + 10 * pow(t, 2) + 3 * pow(t, 3))
        length *= t
        let denominator = 2 * (alpha - 1) * (1 - alpha)
        length /= denominator
        
        return length * _nodePos
    }
    
    struct OrientedPoint {
        var position: NSPoint
        var direction: CGFloat
    }
    
    func arcPoints(lambdas: [CGFloat]) -> [OrientedPoint] {

        let arcLength = bezierLength(t: 0.5) * 2
        let innerWidth = _boundBox.width - 2 * _nodePos
        let innerHeight = _boundBox.height - 2 * _nodePos
        let totalLength = 2 * (innerWidth + innerHeight) + 4 * arcLength
        
        func bezierNorm(l: CGFloat) -> (NSPoint, CGFloat) {
            var t: CGFloat = 0.0
            var otherSide = false
            var effectiveL = l
            if effectiveL > 0.5 {
                effectiveL = 1.0 - effectiveL
                otherSide = true
            }
            
            let stepSize: CGFloat = 0.1
            var currL: CGFloat = 0.0
            var prevL: CGFloat = -stepSize
            while currL < effectiveL * arcLength {
                prevL = currL
                t += stepSize
                if t > 0.5 {
                    t = 0.5
                }
                currL = bezierLength(t: t)
            }
            t -= (currL - effectiveL * arcLength) / (currL - prevL) * stepSize
            if otherSide {
                t = 1.0 - t
            }
            let alpha = _ankorPos / _nodePos
            let xt = pow(t, 3) + 3 * alpha * (1 - t) * pow(t, 2)
            let yt = pow(1 - t, 3) + 3 * alpha * t * pow(1 - t, 2)
            let dxt = 3 * (1 - alpha) * pow(1 - t, 2) + 6 * alpha * (1 - t) * t
            let dyt = 3 * (1 - alpha) * pow(t, 2) + 6 * alpha * (1 - t) * t
            let angle: CGFloat = atan2(dyt, dxt)
            let midPoint = NSMakePoint(xt * _nodePos, yt * _nodePos)
            return (midPoint, angle)
        }
        
        var firstLine = Array<CGFloat>(), secondLine = Array<CGFloat>(), thirdLine = Array<CGFloat>(), fourthLine = Array<CGFloat>(), fifthLine = Array<CGFloat>()
        var firstArc = Array<CGFloat>(), secondArc = Array<CGFloat>(), thirdArc = Array<CGFloat>(), fourthArc = Array<CGFloat>()
        
        for lambda in lambdas {
            switch lambda * totalLength {
            case 0.0..<innerWidth/2:
                firstLine.append(lambda * totalLength)
            case (innerWidth/2)..<(innerWidth/2+arcLength):
                firstArc.append((lambda * totalLength - innerWidth/2) / arcLength)
            case (innerWidth/2+arcLength)..<(innerWidth/2+arcLength+innerHeight):
                secondLine.append(lambda * totalLength - innerWidth/2 - arcLength)
            case (innerWidth/2+arcLength+innerHeight)..<(innerWidth/2+2*arcLength+innerHeight):
                secondArc.append((lambda * totalLength - (innerWidth/2+arcLength+innerHeight)) / arcLength)
            case (innerWidth/2+2*arcLength+innerHeight)..<(innerWidth*1.5+2*arcLength+innerHeight):
                thirdLine.append(lambda * totalLength - (innerWidth/2+2*arcLength+innerHeight))
            case (innerWidth*1.5+2*arcLength+innerHeight)..<(innerWidth*1.5+3*arcLength+innerHeight):
                thirdArc.append((lambda * totalLength-(innerWidth*1.5+2*arcLength+innerHeight)) / arcLength)
            case (innerWidth*1.5+3*arcLength+innerHeight)..<(innerWidth*1.5+3*arcLength+2*innerHeight):
                fourthLine.append(lambda * totalLength - (innerWidth*1.5+3*arcLength+innerHeight))
            case (innerWidth*1.5+3*arcLength+2*innerHeight)..<(totalLength-innerWidth/2):
                fourthArc.append((lambda * totalLength-(innerWidth*1.5+3*arcLength+2*innerHeight)) / arcLength)
            case (totalLength-innerWidth/2)...totalLength:
                fifthLine.append(lambda * totalLength - (totalLength-innerWidth/2))
            default:
                return []
            }
        }
        
        var points = Array<OrientedPoint>()
        
        for lambda in firstLine {
            let start = NSMakePoint(_boundBox.midX + lambda, _boundBox.maxY)
            let normAngle: CGFloat = 0
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in firstArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            start = NSMakePoint(_boundBox.maxX - start.y, _boundBox.maxY - start.x)
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in secondLine {
            let start = NSMakePoint(_boundBox.maxX, _boundBox.maxY - _nodePos - lambda)
            let normAngle = CGFloat.pi / 2
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in secondArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            start = NSMakePoint(_boundBox.maxX - start.x, _boundBox.minY + start.y)
            normAngle += CGFloat.pi / 2
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in thirdLine {
            let start = NSMakePoint(_boundBox.maxX - _nodePos - lambda, _boundBox.minY)
            let normAngle = CGFloat.pi
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in thirdArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            normAngle += CGFloat.pi
            start = NSMakePoint(_boundBox.minX + start.y, _boundBox.minY + start.x)
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in fourthLine {
            let start = NSMakePoint(_boundBox.minX, _boundBox.minY + _nodePos + lambda)
            let normAngle = CGFloat.pi * 3/2
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in fourthArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            normAngle += CGFloat.pi * 3/2
            start = NSMakePoint(_boundBox.minX + start.x, _boundBox.maxY - start.y)
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        for lambda in fifthLine {
            let start = NSMakePoint(_boundBox.minX + _nodePos + lambda, _boundBox.maxY)
            let normAngle: CGFloat = 0
            points.append(OrientedPoint(position: start, direction: normAngle))
        }
        
        return points
    }
    
    func arcPosition(lambdas: [CGFloat], width: CGFloat) -> CGPath {

        let center = NSMakePoint(_boundBox.midX, _boundBox.midY)
        func getEnd(start: NSPoint, center: NSPoint, width: CGFloat) -> NSPoint {
            var direction = start - center
            direction = direction / sqrt(pow(direction.x, 2) + pow(direction.y, 2))
            let end = start - direction * width
            return end
        }
        let points = arcPoints(lambdas: lambdas)
        let path = CGMutablePath()
        for start in points {
            let end = getEnd(start: start.position, center: center, width: width)
            path.move(to: start.position)
            path.addLine(to: end)
        }
        
        return path
    }
    
}

class WatchFaceView: NSView {
    
    struct CelestialEvent {
        var eclipse = [CGFloat]()
        var fullMoon = [CGFloat]()
        var oddSolarTerm = [CGFloat]()
        var evenSolarTerm = [CGFloat]()
    }
    
    static var layoutTemplate: String? = nil
    let watchLayout: WatchLayout
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var shape: CAShapeLayer = CAShapeLayer()
    
    var cornerSize: CGFloat = 0.3
    private var oddSolarTerms: Array<CGFloat> = []
    private var evenSolarTerms: Array<CGFloat> = []
    private var monthDivides: Array<CGFloat> = []
    private var fullMoon: Array<CGFloat> = []
    private var monthNames: Array<String> = []
    private var currentDayInYear: CGFloat = 0
    private var daysInMonth: Int = 30
    private var currentDay: Int = 1
    private var currentHour: CGFloat = 0
    private var dateString: String = ""
    private var timeString: String = ""
    private var eventInMonth = CelestialEvent()
    private var eventInDay = CelestialEvent()
    private var eventInHour = CelestialEvent()
    
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
        false
    }
    
    var isDark: Bool {
        self.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
    
    override func viewDidChangeEffectiveAppearance() {
        self.layer?.sublayers = nil
        self.needsDisplay = true
    }
    
    func update() {
        let time = displayTime ?? Date()
        let chineseCal = ChineseCalendar(time: time, timezone: timezone)
        self.dateString = chineseCal.dateString
        self.timeString = chineseCal.timeString
        self.evenSolarTerms = chineseCal.evenSolarTerms
        self.oddSolarTerms = chineseCal.oddSolarTerms
        self.monthDivides = chineseCal.monthDivides
        self.fullMoon = chineseCal.fullmoon
        self.monthNames = chineseCal.monthNames
        self.currentDayInYear = chineseCal.currentDayInYear
        self.currentHour = chineseCal.currentHour
        self.currentDay = chineseCal.currentDay
        self.daysInMonth = chineseCal.daysInMonth
        self.eventInMonth = chineseCal.eventInMonth
        self.eventInDay = chineseCal.eventInDay
        self.eventInHour = chineseCal.eventInHour
    }
    
    func drawView() {
        self.layer?.sublayers = nil
        update()
        self.needsDisplay = true
    }
    
    override func draw(_ rawRect: NSRect) {
        let frameOffset = 0.05 * min(rawRect.width, rawRect.height)
        let dirtyRect = rawRect.insetBy(dx: frameOffset, dy: frameOffset)
        
        func angleMask(angle: CGFloat, in circle: RoundedRect) -> CAShapeLayer {
            let path = CGMutablePath()
            if let point = circle.arcPoints(lambdas: [angle]).first?.position {
                let center = NSMakePoint(circle._boundBox.midX, circle._boundBox.midY)
                let direction = point - center
                
                path.move(to: point)
                switch (direction.x > 0, direction.y > 0) {
                case (true, true):
                    if point.y < circle._boundBox.maxY {
                        path.addLine(to: NSMakePoint(point.x, circle._boundBox.maxY))
                    }
                    path.addLine(to: NSMakePoint(circle._boundBox.midX, circle._boundBox.maxY))
                case (true, false):
                    if point.x < circle._boundBox.maxX {
                        path.addLine(to: NSMakePoint(circle._boundBox.maxX, point.y))
                    }
                    path.addLine(to: NSMakePoint(circle._boundBox.maxX, circle._boundBox.maxY))
                    path.addLine(to: NSMakePoint(circle._boundBox.midX, circle._boundBox.maxY))
                case (false, false):
                    if point.y > circle._boundBox.minY {
                        path.addLine(to: NSMakePoint(point.x, circle._boundBox.minY))
                    }
                    path.addLine(to: NSMakePoint(circle._boundBox.maxX, circle._boundBox.minY))
                    path.addLine(to: NSMakePoint(circle._boundBox.maxX, circle._boundBox.maxY))
                    path.addLine(to: NSMakePoint(circle._boundBox.midX, circle._boundBox.maxY))
                case (false, true):
                    if point.x > circle._boundBox.minX {
                        path.addLine(to: NSMakePoint(circle._boundBox.minX, point.y))
                    }
                    path.addLine(to: NSMakePoint(circle._boundBox.minX, circle._boundBox.minY))
                    path.addLine(to: NSMakePoint(circle._boundBox.maxX, circle._boundBox.minY))
                    path.addLine(to: NSMakePoint(circle._boundBox.maxX, circle._boundBox.maxY))
                    path.addLine(to: NSMakePoint(circle._boundBox.midX, circle._boundBox.maxY))
                }
                path.addLine(to: center)
                path.closeSubpath()
            }
            
            let shape = CAShapeLayer()
            shape.path = path
            return shape
        }
        
        func applyGradient(to path: CGPath, gradient: WatchLayout.Gradient, alpha: CGFloat = 1.0, angle: CGFloat? = nil, outerRing: RoundedRect? = nil) -> CAShapeLayer {
            let gradientLayer = CAGradientLayer()
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.type = .conic
            gradientLayer.colors = gradient.colors.map { $0.cgColor }
            gradientLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
            gradientLayer.frame = self.frame
            
            let trackMask = CAShapeLayer()
            trackMask.path = path
            trackMask.fillRule = .evenOdd
            
            let mask: CALayer
            if let angle = angle, let outerRing = outerRing {
                let angleMask = angleMask(angle: angle, in: outerRing)
                angleMask.fillColor = NSColor(deviceWhite: 1.0, alpha: alpha).cgColor
                angleMask.mask = trackMask
                mask = CALayer()
                mask.addSublayer(angleMask)
            } else {
                trackMask.fillColor = NSColor(deviceWhite: 1.0, alpha: alpha).cgColor
                mask = trackMask
            }
            gradientLayer.mask = mask
            self.layer?.addSublayer(gradientLayer)
            
            let shape = CAShapeLayer()
            shape.path = path
            shape.fillRule = .evenOdd
            return shape
        }
        
        func addMarks(position: CelestialEvent, on ring: RoundedRect, maskPath: CGPath, radius: CGFloat) {
            func drawMark(type: [CGFloat], color: NSColor) {
                let positions = ring.arcPoints(lambdas: type).map { $0.position }
                let marksPath = CGMutablePath()
                for pos in positions {
                    marksPath.addPath(CGPath(ellipseIn: NSMakeRect(pos.x - radius, pos.y - radius, 2 * radius, 2 * radius), transform: nil))
                }
                let marks = CAShapeLayer()
                marks.path = marksPath
                marks.fillColor = color.cgColor
                let mask = CAShapeLayer()
                mask.path = maskPath
                mask.fillRule = .evenOdd
                marks.mask = mask
                self.layer?.addSublayer(marks)
            }
            drawMark(type: position.eclipse, color: watchLayout.eclipseIndicator)
            drawMark(type: position.fullMoon, color: watchLayout.fullmoonIndicator)
            drawMark(type: position.oddSolarTerm, color: watchLayout.oddStermIndicator)
            drawMark(type: position.evenSolarTerm, color: watchLayout.evenStermIndicator)
        }
        
        func drawText(str: String, at: NSPoint, angle: CGFloat, color: NSColor, size: CGFloat) -> CGPath {
            let font = watchLayout.textFont.withSize(size)
            let textLayer = CATextLayer()
            var attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttributes([.font: font, .foregroundColor: color], range: NSMakeRange(0, str.utf16.count))
            var box = attrStr.boundingRect(with: NSZeroSize, options: .usesLineFragmentOrigin)
            box.origin = NSMakePoint(at.x - box.width/2, at.y - box.height/2)
            if (angle > CGFloat.pi / 4 && angle < CGFloat.pi * 3/4) || (angle > CGFloat.pi * 5/4 && angle < CGFloat.pi * 7/4) {
                let shift = size * size * watchLayout.verticalTextOffset
                textLayer.frame = NSMakeRect(at.x - box.width/2 + shift, at.y - box.height*1.8/2, box.width, box.height*1.8)
                attrStr.addAttributes([.verticalGlyphForm: 1], range: NSMakeRange(0, str.utf16.count))
            } else {
                let shift = size * size * watchLayout.horizontalTextOffset
                textLayer.frame = NSMakeRect(at.x - box.width/2, at.y - box.height/2 + shift, box.width, box.height)
                attrStr = NSMutableAttributedString(string: String(str.reversed()), attributes: attrStr.attributes(at: 0, effectiveRange: nil))
            }
            textLayer.string = attrStr
            textLayer.contentsScale = 3
            textLayer.alignmentMode = .center
            var boxTransform = CGAffineTransform(translationX: -at.x, y: -at.y)
            let transform: CGAffineTransform
            if angle <= CGFloat.pi / 2 {
                transform = CGAffineTransform(rotationAngle: -angle)
            } else if angle < CGFloat.pi * 3/4 {
                transform = CGAffineTransform(rotationAngle: 2*CGFloat.pi-angle)
            } else if angle < CGFloat.pi * 7/4 {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi-angle)
            } else {
                transform = CGAffineTransform(rotationAngle: 2*CGFloat.pi-angle)
            }
            boxTransform = boxTransform.concatenating(transform)
            boxTransform = boxTransform.concatenating(CGAffineTransform(translationX: at.x, y: at.y))
            textLayer.setAffineTransform(transform)
            let path = CGPath(rect: box, transform: &boxTransform)
            self.layer?.addSublayer(textLayer)
            return path
        }
        
        func drawCenterText(str: String, offset: CGFloat, size: CGFloat, rotate: Bool) -> CATextLayer {
            let center = NSMakePoint(self.bounds.midX, self.bounds.midY)
            let font = watchLayout.centerFont.withSize(size)
            let textLayer = CATextLayer()
            var attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttributes([.font: font, .foregroundColor: watchLayout.fontColor], range: NSMakeRange(0, str.utf16.count))
            let box = attrStr.boundingRect(with: NSZeroSize, options: .usesLineFragmentOrigin)
            if rotate {
                textLayer.frame = NSMakeRect(center.x - box.width/2 + offset, center.y - box.height*2.3/2, box.width, box.height*2.3)
                textLayer.setAffineTransform(CGAffineTransform(rotationAngle: -CGFloat.pi/2))
                attrStr.addAttributes([.verticalGlyphForm: 1], range: NSMakeRange(0, str.utf16.count))
            } else {
                textLayer.frame = NSMakeRect(center.x - box.width/2, center.y - box.height/2 + offset, box.width, box.height)
                attrStr = NSMutableAttributedString(string: String(str.reversed()), attributes: attrStr.attributes(at: 0, effectiveRange: nil))
            }
            textLayer.string = attrStr
            textLayer.contentsScale = 3
            textLayer.alignmentMode = .center
            
            return textLayer
        }
        
        let shortEdge = min(dirtyRect.width, dirtyRect.height)
        let longEdge = max(dirtyRect.width, dirtyRect.height)
        
        let outerBound = RoundedRect(rect: dirtyRect, nodePos: cornerSize, ankorPos: cornerSize*0.2)
        let firstRingOuter = outerBound.shrink(by: 0.05 * shortEdge)
        let firstRingInner = firstRingOuter.shrink(by: 0.07 * shortEdge)
        
        let secondRingOuter = firstRingInner.shrink(by: 0.01 * shortEdge)
        let secondRingInner = secondRingOuter.shrink(by: 0.07 * shortEdge)
        
        let thirdRingOuter = secondRingInner.shrink(by: 0.01 * shortEdge)
        let thirdRingInner = thirdRingOuter.shrink(by: 0.07 * shortEdge)
        
        let fourthRingOuter = thirdRingInner.shrink(by: 0.01 * shortEdge)
        let fourthRingInner = fourthRingOuter.shrink(by: 0.07 * shortEdge)
        
        let innerBound = fourthRingInner.shrink(by: 0.01 * shortEdge)
        
        let outerBoundPath = outerBound.path
        let firstRingOuterPath = firstRingOuter.path
        let firstRingInnerPath = firstRingInner.path
        firstRingOuterPath.addPath(firstRingInnerPath)
        
        let secondRingOuterPath = secondRingOuter.path
        let secondRingInnerPath = secondRingInner.path
        secondRingOuterPath.addPath(secondRingInnerPath)
        
        let thirdRingOuterPath = thirdRingOuter.path
        let thirdRingInnerPath = thirdRingInner.path
        thirdRingOuterPath.addPath(thirdRingInnerPath)
        
        let fourthRingOuterPath = fourthRingOuter.path
        let fourthRingInnerPath = fourthRingInner.path
        fourthRingOuterPath.addPath(fourthRingInnerPath)
        
        let innerBoundPath = innerBound.path

        // Will be used from outside this View
        shape.path = firstRingOuterPath
        shape.fillColor = NSColor(deviceWhite: 1.0, alpha: watchLayout.backAlpha).cgColor
        shape.shadowPath = outerBoundPath
        shape.shadowColor = shape.fillColor
        shape.shadowOpacity = 1
        shape.shadowOffset = NSMakeSize(0, 0)
        shape.shadowRadius = frameOffset / 2
        
        // Draw rings
        let _ = applyGradient(to: firstRingOuterPath, gradient: watchLayout.firstRing, alpha: watchLayout.shadeAlpha)
        let firstRing = applyGradient(to: firstRingOuterPath, gradient: watchLayout.firstRing, angle: currentDayInYear, outerRing: firstRingOuter)

        let currentDayInMonth = (CGFloat(currentDay) - 1 + currentHour / 24) / CGFloat(daysInMonth)
        let _ = applyGradient(to: secondRingOuterPath, gradient: watchLayout.secondRing, alpha: watchLayout.shadeAlpha)
        let secondRing = applyGradient(to: secondRingOuterPath, gradient: watchLayout.secondRing, angle: currentDayInMonth, outerRing: secondRingOuter)

        let _ = applyGradient(to: thirdRingOuterPath, gradient: watchLayout.thirdRing, alpha: watchLayout.shadeAlpha)
        let thirdRing = applyGradient(to: thirdRingOuterPath, gradient: watchLayout.thirdRing, angle: currentHour / 24, outerRing: thirdRingOuter)

        let priorHour = CGFloat(Int(currentHour / 2) * 2)
        let nextHour = CGFloat((Int(currentHour / 2) + 1) % 12) * 2

        let fourthRingColor = WatchLayout.Gradient(locations: [0, 1], colors: [
            watchLayout.thirdRing.interpolate(at: 1-(nextHour / 24)),
            watchLayout.thirdRing.interpolate(at: 1-(priorHour / 24))
        ], loop: false)
        let _ = applyGradient(to: fourthRingOuterPath, gradient: fourthRingColor, alpha: watchLayout.shadeAlpha)
        let fourthRing = applyGradient(to: fourthRingOuterPath, gradient: fourthRingColor,
                                       angle: (currentHour - priorHour) / 2, outerRing: fourthRingOuter)
        
        let innerBox = CAShapeLayer()
        innerBox.path = innerBoundPath
        innerBox.fillColor = watchLayout.innerColor.cgColor
        self.layer?.addSublayer(innerBox)

        // Ticks
        let zeroRingOuter = outerBound.shrink(by: 0.01 * shortEdge)
        let zeroRingOddTicks = zeroRingOuter.arcPosition(lambdas: oddSolarTerms, width: 0.05 * shortEdge)
        let zeroRingPath = zeroRingOuter.path
        zeroRingPath.addPath(firstRingOuterPath)
        let zeroRingOdd = CAShapeLayer()
        zeroRingOdd.path = zeroRingPath
        zeroRingOdd.fillRule = .evenOdd
        let zeroRingOddTicksShape = CAShapeLayer()
        zeroRingOddTicksShape.path = zeroRingOddTicks
        zeroRingOddTicksShape.mask = zeroRingOdd
        let oddSolarTermTickColor: NSColor
        let evenSolarTermTickColor: NSColor
        if self.isDark {
            oddSolarTermTickColor = watchLayout.oddSolarTermTickColorDark
            evenSolarTermTickColor = watchLayout.evenSolarTermTickColorDark
        } else {
            oddSolarTermTickColor = watchLayout.oddSolarTermTickColor
            evenSolarTermTickColor = watchLayout.evenSolarTermTickColor
        }
        zeroRingOddTicksShape.strokeColor = oddSolarTermTickColor.cgColor
        zeroRingOddTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(zeroRingOddTicksShape)

        let zeroRingEven = CAShapeLayer()
        zeroRingEven.path = zeroRingPath
        zeroRingEven.fillRule = .evenOdd
        let zeroRingEvenTicks = zeroRingOuter.arcPosition(lambdas: evenSolarTerms, width: 0.05 * shortEdge)
        let zeroRingEvenTicksShape = CAShapeLayer()
        zeroRingEvenTicksShape.path = zeroRingEvenTicks
        zeroRingEvenTicksShape.mask = zeroRingEven
        zeroRingEvenTicksShape.strokeColor = evenSolarTermTickColor.cgColor
        zeroRingEvenTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(zeroRingEvenTicksShape)

        let firstRingMinorTicks = firstRingOuter.arcPosition(lambdas: fullMoon, width: 0.1 * shortEdge)
        let firstRingMinorTicksShape = CAShapeLayer()
        firstRingMinorTicksShape.path = firstRingMinorTicks
        
        let firstRingMinorOuter = firstRingOuter.shrink(by: 0.01 * shortEdge)
        let firstRingMinorInner = firstRingOuter.shrink(by: 0.06 * shortEdge)
        let firstRingMinorPath = firstRingMinorOuter.path
        firstRingMinorPath.addPath(firstRingMinorInner.path)
        let firstRingMinor = CAShapeLayer()
        firstRingMinor.fillRule = .evenOdd

        firstRingMinorTicksShape.strokeColor = watchLayout.minorTickColor.cgColor
        firstRingMinorTicksShape.lineWidth = shortEdge / 500
        self.layer?.addSublayer(firstRingMinorTicksShape)
        
        let firstRingMajorTicks = firstRingOuter.arcPosition(lambdas: [0] + monthDivides, width: 0.1 * shortEdge)
        let firstRingMajorTicksShape = CAShapeLayer()
        firstRingMajorTicksShape.path = firstRingMajorTicks
        firstRingMajorTicksShape.mask = firstRing
        firstRingMajorTicksShape.strokeColor = watchLayout.majorTickColor.cgColor
        firstRingMajorTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(firstRingMajorTicksShape)

        var dayTick = Array<CGFloat>()
        for i in 0..<daysInMonth {
            dayTick.append(CGFloat(i) / CGFloat(daysInMonth))
        }
        let secondRingMajorTicks = secondRingOuter.arcPosition(lambdas: dayTick, width: 0.1 * shortEdge)
        let secondRingMajorTicksShape = CAShapeLayer()
        secondRingMajorTicksShape.path = secondRingMajorTicks
        secondRingMajorTicksShape.mask = secondRing
        secondRingMajorTicksShape.strokeColor = watchLayout.majorTickColor.cgColor
        secondRingMajorTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(secondRingMajorTicksShape)
        addMarks(position: eventInMonth, on: secondRingOuter, maskPath: secondRingOuterPath, radius: 0.012 * shortEdge)

        var hourTick = Array<CGFloat>()
        for i in 0..<24 {
            hourTick.append(CGFloat(i) / 24)
        }
        var quarterTick = Array<CGFloat>()
        for i in 0..<100 {
            quarterTick.append(CGFloat(i) / 100)
        }
        var hourNamePositions = Array<CGFloat>()
        for i in 0..<12 {
            hourNamePositions.append(CGFloat(i) / 12)
        }
        let hourRing = thirdRingOuter.shrink(by: 0.035 * shortEdge)
        let hourPoints = hourRing.arcPoints(lambdas: hourNamePositions)
        
        let thirdRingMinorTicks = thirdRingOuter.arcPosition(lambdas: quarterTick, width: 0.1 * shortEdge)
        let thirdRingMinorTicksShape = CAShapeLayer()
        thirdRingMinorTicksShape.path = thirdRingMinorTicks

        let thirdRingMinorOuter = thirdRingOuter.shrink(by: 0.01 * shortEdge)
        let thirdRingMinorInner = thirdRingOuter.shrink(by: 0.06 * shortEdge)
        let thirdRingMinorPath = thirdRingMinorOuter.path
        thirdRingMinorPath.addPath(thirdRingMinorInner.path)
        let thirdRingMinor = CAShapeLayer()
        thirdRingMinor.fillRule = .evenOdd

        thirdRingMinorTicksShape.strokeColor = watchLayout.minorTickColor.cgColor
        thirdRingMinorTicksShape.lineWidth = shortEdge / 500
        self.layer?.addSublayer(thirdRingMinorTicksShape)

        let thirdRingMajorTicks = thirdRingOuter.arcPosition(lambdas: hourTick, width: 0.1 * shortEdge)
        let thirdRingMajorTicksShape = CAShapeLayer()
        thirdRingMajorTicksShape.path = thirdRingMajorTicks
        thirdRingMajorTicksShape.strokeColor = watchLayout.majorTickColor.cgColor
        thirdRingMajorTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(thirdRingMajorTicksShape)
        addMarks(position: eventInDay, on: thirdRingOuter, maskPath: thirdRingOuterPath, radius: 0.012 * shortEdge)

        var subHourTick: Set<CGFloat> = [0, 0.5]
        for i in 1..<10 {
            let tick = CGFloat(i * 6 - ((Int(currentHour / 2)*2) % 6)) / 50
            if tick < 1 {
                subHourTick.insert(tick)
            }
        }
        var subQuarterTick = Set<CGFloat>()
        for i in 0..<50 {
            subQuarterTick.insert(CGFloat(i) / 50)
        }
        subQuarterTick = subQuarterTick.subtracting(subHourTick)
        
        let fourthRingMinorTicks = fourthRingOuter.arcPosition(lambdas: Array(subQuarterTick), width: 0.1 * shortEdge)
        let fourthRingMinorTicksShape = CAShapeLayer()
        fourthRingMinorTicksShape.path = fourthRingMinorTicks

        let fourthRingMinorOuter = fourthRingOuter.shrink(by: 0.01 * shortEdge)
        let fourthRingMinorInner = fourthRingOuter.shrink(by: 0.06 * shortEdge)
        let fourthRingMinorPath = fourthRingMinorOuter.path
        fourthRingMinorPath.addPath(fourthRingMinorInner.path)
        let fourthRingMinor = CAShapeLayer()
        fourthRingMinor.fillRule = .evenOdd

        fourthRingMinorTicksShape.strokeColor = watchLayout.minorTickColor.cgColor
        fourthRingMinorTicksShape.lineWidth = shortEdge / 500
        self.layer?.addSublayer(fourthRingMinorTicksShape)

        let fourthRingMajorTicks = fourthRingOuter.arcPosition(lambdas: Array(subHourTick), width: 0.1 * shortEdge)
        let fourthRingMajorTicksShape = CAShapeLayer()
        fourthRingMajorTicksShape.path = fourthRingMajorTicks
        fourthRingMajorTicksShape.strokeColor = watchLayout.majorTickColor.cgColor
        fourthRingMajorTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(fourthRingMajorTicksShape)
        addMarks(position: eventInHour, on: fourthRingOuter, maskPath: fourthRingOuterPath, radius: 0.012 * shortEdge)
        
        // Draw text
        let fontSize: CGFloat = min(shortEdge * 0.03, longEdge * 0.025)
        let solarTermsRing = zeroRingOuter.shrink(by: 0.02 * shortEdge)
        let evenPoints = solarTermsRing.arcPoints(lambdas: evenSolarTerms)
        var i = 0
        for point in evenPoints {
            let _ = drawText(str: ChineseCalendar.evenSolarTermChinese[i], at: point.position, angle: point.direction, color: evenSolarTermTickColor, size: fontSize)
            i += 1
        }
        i = 0
        let oddPoints = solarTermsRing.arcPoints(lambdas: oddSolarTerms)
        for point in oddPoints {
            let _ = drawText(str: ChineseCalendar.oddSolarTermChinese[i], at: point.position, angle: point.direction, color: oddSolarTermTickColor, size: fontSize)
            i += 1
        }
        
        let monthRing = firstRingOuter.shrink(by: 0.035 * shortEdge)
        var monthPositions = [CGFloat]()
        var previous: CGFloat = 0.0
        var monthNameStart = 0
        for i in 0..<monthDivides.count {
            let position = (self.monthDivides[i] + previous) / 2
            if position > 0.01 && position < 0.99 {
                monthPositions.append(position)
            } else if position <= 0.02 {
                monthNameStart = 1
            }
            previous = monthDivides[i]
        }
        if (1 + previous) / 2 < 0.99 {
            monthPositions.append((1 + previous) / 2)
        }
        let monthNamePoints = monthRing.arcPoints(lambdas: monthPositions)
        i = monthNameStart
        let monthNameMask = CGMutablePath()
        for point in monthNamePoints {
            let monthBox = drawText(str: self.monthNames[i], at: point.position, angle: point.direction, color: watchLayout.fontColor, size: fontSize)
            monthNameMask.addPath(monthBox)
            i += 1
        }
        firstRingMinorPath.addPath(monthNameMask)
        firstRingMinor.path = firstRingMinorPath
        firstRingMinorTicksShape.mask = firstRingMinor
        
        let dayRing = secondRingOuter.shrink(by: 0.035 * shortEdge)
        var dayPositions = [CGFloat]()
        previous = 0.0
        for i in 1..<dayTick.count {
            dayPositions.append((dayTick[i] + previous) / 2)
            previous = dayTick[i]
        }
        dayPositions.append((1 + previous) / 2)
        let dayNamePoints = dayRing.arcPoints(lambdas: dayPositions)
        i = 0
        for point in dayNamePoints {
            let _ = drawText(str: ChineseCalendar.day_chinese[i], at: point.position, angle: point.direction, color: watchLayout.fontColor, size: fontSize)
            i += 1
        }
        
        let hourNameMaskPath = CGMutablePath()
        i = 0
        for point in hourPoints {
            let path = drawText(str: ChineseCalendar.terrestrial_branches[i], at: point.position, angle: point.direction, color: watchLayout.fontColor, size: fontSize)
            hourNameMaskPath.addPath(path)
            i += 1
        }
        thirdRingOuterPath.addPath(hourNameMaskPath)
        thirdRing.path = thirdRingOuterPath
        thirdRingMajorTicksShape.mask = thirdRing
        thirdRingMinorPath.addPath(hourNameMaskPath)
        thirdRingMinor.path = thirdRingMinorPath
        thirdRingMinorTicksShape.mask = thirdRingMinor
        
        let quarterRing = fourthRingOuter.shrink(by: 0.035 * shortEdge)
        let subHourTicks = Array(subHourTick).sorted()
        let innerHourPoints = quarterRing.arcPoints(lambdas: subHourTicks)
        let innerHourNameMaskPath = CGMutablePath()
        let evenHourText = ChineseCalendar.terrestrial_branches[Int(currentHour / 2)] + ChineseCalendar.sub_hour_name[1]
        let oddHourText = ChineseCalendar.terrestrial_branches[(Int(currentHour / 2)+1) % 12] + ChineseCalendar.sub_hour_name[0]

        i = 0
        for point in innerHourPoints {
            let str: String
            let dist = abs(subHourTicks[i] * 2 - round(subHourTicks[i] * 2))
            if dist == 0 || dist > 0.05 {
                switch i {
                case 0:
                    str = evenHourText
                case 5:
                    str = oddHourText
                case 1...4:
                    str = ChineseCalendar.chinese_numbers[i]
                case 6...9:
                    str = ChineseCalendar.chinese_numbers[i-5]
                default:
                    str = ""
                }
                let path = drawText(str: str, at: point.position, angle: point.direction, color: watchLayout.fontColor, size: fontSize)
                innerHourNameMaskPath.addPath(path)
            }
            i += 1
        }
        fourthRingOuterPath.addPath(innerHourNameMaskPath)
        fourthRingMinorPath.addPath(innerHourNameMaskPath)
        fourthRingMinor.path = fourthRingMinorPath
        fourthRingMinorTicksShape.mask = fourthRingMinor
        fourthRing.path = fourthRingOuterPath
        fourthRingMajorTicksShape.mask = fourthRing
        
        // Center text
        let centerText = CALayer()
        let centerTextShortSize = min(innerBound._boundBox.width, innerBound._boundBox.height) * 0.31
        let centerTextLongSize = max(innerBound._boundBox.width, innerBound._boundBox.height) * 0.17
        let centerTextSize = min(centerTextShortSize, centerTextLongSize)
        let isVertical = innerBound._boundBox.height >= innerBound._boundBox.width
        let dateTextLayer = drawCenterText(str: dateString, offset: centerTextSize * (0.7 + watchLayout.centerTextOffset), size: centerTextSize, rotate: isVertical)
        centerText.addSublayer(dateTextLayer)
        let timeTextLayer = drawCenterText(str: timeString, offset: centerTextSize * (-0.7 + watchLayout.centerTextOffset), size: centerTextSize, rotate: isVertical)
        centerText.addSublayer(timeTextLayer)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: -0.3, y: 0.3)
        gradientLayer.endPoint = CGPoint(x: 0.3, y: -0.3)
        gradientLayer.type = .axial
        gradientLayer.colors = watchLayout.centerFontColor.colors.map { $0.cgColor }
        gradientLayer.locations = watchLayout.centerFontColor.locations.map { NSNumber(value: Double($0)) }
        gradientLayer.frame = self.frame
        gradientLayer.mask = centerText
        self.layer?.addSublayer(gradientLayer)
    }
}

class WatchFace: NSWindow {
    let _view: WatchFaceView
    let _backView: NSVisualEffectView
    private var _visible = false
    private var _timer: Timer?
    static var currentInstance: WatchFace? = nil
    
    init(position: NSRect) {
        _view = WatchFaceView(frame: position)
        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .fullScreenUI
        blurView.state = .active
        blurView.wantsLayer = true
        _backView = blurView
        super.init(contentRect: position, styleMask: .borderless, backing: .buffered, defer: true)
        self.alphaValue = 1
        self.level = NSWindow.Level.floating
        self.hasShadow = false
        self.isOpaque = false
        self.backgroundColor = .clear
        let contentView = NSView()
        self.contentView = contentView
        contentView.addSubview(_backView)
        contentView.addSubview(_view)
        self.isMovableByWindowBackground = true
    }
    
    override var isVisible: Bool {
        _visible
    }
    
    func getCurrentScreen() -> NSRect {
        var screenRect = NSScreen.main!.frame
        let screens = NSScreen.screens
        for i in 0..<screens.count {
            let rect = screens[i].frame
            if NSPointInRect(NSMakePoint(self.frame.midX, self.frame.midY), rect) {
                screenRect = rect
                break
            }
        }
        return screenRect
    }
    
    func updateSize(with frame: NSRect?) {
        let watchDimension = _view.watchLayout.watchSize
        if frame == nil {
            let windowRect = self.getCurrentScreen()
            self.setFrame(NSMakeRect(
                            windowRect.midX - watchDimension.width / 2,
                            windowRect.midY - watchDimension.height / 2,
                            watchDimension.width, watchDimension.height), display: true)
        } else {
            self.setFrame(NSMakeRect(
                            frame!.midX - watchDimension.width / 2,
                            frame!.midY - watchDimension.height / 2,
                            watchDimension.width, watchDimension.height), display: true)
        }
        _view.frame = _view.superview!.bounds
        _backView.frame = _view.superview!.bounds
        _view.cornerSize = _view.watchLayout.cornerRadiusRatio * min(watchDimension.width, watchDimension.height)
    }
    
    func show() {
        updateSize(with: nil)
        self.invalidateShadow()
        _view.drawView()
        self._backView.layer?.mask = _view.shape
        self.orderFront(nil)
        self._visible = true
        self._timer = Timer.scheduledTimer(withTimeInterval: 28.8, repeats: true) {_ in
            self.invalidateShadow()
            self._view.drawView()
        }
        Self.currentInstance = self
    }
    
    func hide() {
        self._timer?.invalidate()
        self._timer = nil
        self._visible = false
        Self.currentInstance = nil
    }
}
