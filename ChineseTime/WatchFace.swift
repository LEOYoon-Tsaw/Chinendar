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
        
        var length = pow(t, 2) * (-1 - 2 * alpha + 9 * pow(alpha, 2)) - 5 * t * alpha * (1 - alpha)
        length *= 0.3 * (-1 + 2 * alpha + pow(alpha, 2))
        length += pow(1 - alpha, 2) * (1 - 4 * alpha + 5 * pow(alpha, 2))
        length *= pow(t / (1 - alpha), 3)
        length += 3 * t * ((1 - alpha) + t * (2 * alpha - 1))
        
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
    
    static var layoutTemplate: String? = nil
    let watchLayout: WatchLayout
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var shape: CAShapeLayer = CAShapeLayer()
    
    var cornerSize: CGFloat = 0.3
    private var oddSolarTerms: [CGFloat] = []
    private var evenSolarTerms: [CGFloat] = []
    private var monthDivides: [CGFloat] = []
    private var fullMoon: [CGFloat] = []
    private var monthNames: [String] = []
    private var dayNames: [String] = []
    private var currentDayInYear: CGFloat = 0
    private var currentDayInMonth: CGFloat = 0
    private var dayDivides: [CGFloat] = []
    private var currentDay: Int = 1
    private var currentHour: CGFloat = 0
    private var planetPosition: [CGFloat] = []
    private var dateString: String = ""
    private var timeString: String = ""
    private var eventInMonth = ChineseCalendar.CelestialEvent()
    private var eventInDay = ChineseCalendar.CelestialEvent()
    private var eventInHour = ChineseCalendar.CelestialEvent()
    
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
        self.dayNames = chineseCal.dayNames
        self.currentDayInYear = chineseCal.currentDayInYear
        self.currentDayInMonth = chineseCal.currentDayInMonth
        self.currentHour = chineseCal.currentHour
        self.currentDay = chineseCal.currentDay
        self.dayDivides = chineseCal.dayDivides
        self.planetPosition = chineseCal.planetPosition
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
        let isDark = self.isDark
        
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
        
        func applyGradient(to path: CGPath, gradient: WatchLayout.Gradient, alpha: CGFloat = 1.0, angle: CGFloat? = nil, outerRing: RoundedRect? = nil) -> CAGradientLayer {
            let gradientLayer = CAGradientLayer()
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.type = .conic
            gradientLayer.colors = gradient.colors.map { $0.cgColor }
            gradientLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
            gradientLayer.frame = self.frame
            
            let trackMask = shapeFrom(path: path)
            
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
            return gradientLayer
        }
        
        func drawMark(at locations: [CGFloat], on ring: RoundedRect, maskPath: CGPath, colors: [NSColor], radius: CGFloat) {
            let marks = CALayer()
            for i in 0..<locations.count {
                let pos = ring.arcPoints(lambdas: [locations[i]]).first!.position
                let markPath = CGPath(ellipseIn: NSMakeRect(pos.x - radius, pos.y - radius, 2 * radius, 2 * radius), transform: nil)
                let mark = shapeFrom(path: markPath)
                mark.fillColor = colors[i % colors.count].cgColor
                marks.addSublayer(mark)
            }
            let mask = shapeFrom(path: maskPath)
            marks.mask = mask
            self.layer?.addSublayer(marks)
        }
        
        func addMarks(position: ChineseCalendar.CelestialEvent, on ring: RoundedRect, maskPath: CGPath, radius: CGFloat) {
            drawMark(at: position.eclipse, on: ring, maskPath: maskPath, colors: [watchLayout.eclipseIndicator], radius: radius)
            drawMark(at: position.fullMoon, on: ring, maskPath: maskPath, colors: [watchLayout.fullmoonIndicator], radius: radius)
            drawMark(at: position.oddSolarTerm, on: ring, maskPath: maskPath, colors: [watchLayout.oddStermIndicator], radius: radius)
            drawMark(at: position.evenSolarTerm, on: ring, maskPath: maskPath, colors: [watchLayout.evenStermIndicator], radius: radius)
        }
        
        func drawText(str: String, at: NSPoint, angle: CGFloat, color: NSColor, size: CGFloat) -> CGPath {
            let font = watchLayout.textFont.withSize(size)
            let textLayer = CATextLayer()
            var attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttributes([.font: font, .foregroundColor: color], range: NSMakeRange(0, str.utf16.count))
            var box = attrStr.boundingRect(with: NSZeroSize, options: .usesLineFragmentOrigin)
            box.origin = NSMakePoint(at.x - box.width/2, at.y - box.height/2)
            if (angle > CGFloat.pi / 4 && angle < CGFloat.pi * 3/4) || (angle > CGFloat.pi * 5/4 && angle < CGFloat.pi * 7/4) {
                let shift = pow(size, 0.9) * watchLayout.verticalTextOffset
                textLayer.frame = NSMakeRect(at.x - box.width/2 + shift, at.y - box.height*1.8/2, box.width, box.height*1.8)
                attrStr.addAttributes([.verticalGlyphForm: 1], range: NSMakeRange(0, str.utf16.count))
            } else {
                let shift = pow(size, 0.9) * watchLayout.horizontalTextOffset
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
            let cornerSize = 0.2 * min(box.height, box.width)
            let path = CGPath(roundedRect: box, cornerWidth: cornerSize, cornerHeight: cornerSize, transform: &boxTransform)
            self.layer?.addSublayer(textLayer)
            return path
        }
        
        func drawCenterText(str: String, offset: CGFloat, size: CGFloat, rotate: Bool) -> CATextLayer {
            let center = NSMakePoint(self.bounds.midX, self.bounds.midY)
            let font = watchLayout.centerFont.withSize(size)
            let textLayer = CATextLayer()
            var attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttributes([.font: font, .foregroundColor: NSColor.white], range: NSMakeRange(0, str.utf16.count))
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
        
        func shapeFrom(path: CGPath) -> CAShapeLayer {
            let shape = CAShapeLayer()
            shape.path = path
            shape.fillRule = .evenOdd
            return shape
        }
        
        func drawRing(ringPath: CGPath, roundedRect: RoundedRect, gradient: WatchLayout.Gradient, angle: CGFloat, minorTickPositions: [CGFloat], majorTickPositions: [CGFloat], textPositions: [CGFloat], texts: [String], fontSize: CGFloat, minorLineWidth: CGFloat, majorLineWidth: CGFloat) {
            
            let ringLayer = CALayer()
            let ringShadow = applyGradient(to: ringPath, gradient: gradient, alpha: watchLayout.shadeAlpha)
            let ringActive = applyGradient(to: ringPath, gradient: gradient, angle: angle, outerRing: roundedRect)
            ringLayer.addSublayer(ringShadow)
            ringLayer.addSublayer(ringActive)
            
            
            let ringMinorTicksPath = roundedRect.arcPosition(lambdas: minorTickPositions, width: 0.1 * shortEdge)
            let ringMinorTicks = CAShapeLayer()
            ringMinorTicks.path = ringMinorTicksPath
            
            let ringMinorTrackOuter = roundedRect.shrink(by: 0.01 * shortEdge)
            let ringMinorTrackInner = roundedRect.shrink(by: 0.06 * shortEdge)
            let ringMinorTrackPath = ringMinorTrackOuter.path
            ringMinorTrackPath.addPath(ringMinorTrackInner.path)

            ringMinorTicks.strokeColor = isDark ? watchLayout.minorTickColorDark.cgColor : watchLayout.minorTickColor.cgColor
            ringMinorTicks.lineWidth = minorLineWidth
            
            let ringMinorTicksMaskPath = CGMutablePath()
            ringMinorTicksMaskPath.addPath(ringPath)
            ringMinorTicksMaskPath.addPath(ringMinorTicksPath.copy(strokingWithWidth: minorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            let ringMinorTicksMask = shapeFrom(path: ringMinorTicksMaskPath)
            
            let ringCrustPath = CGMutablePath()
            ringCrustPath.addPath(ringMinorTrackPath)
            ringCrustPath.addPath(ringPath)
            let ringCrust = shapeFrom(path: ringCrustPath)
            ringMinorTicksMask.addSublayer(ringCrust)
            
            let ringMajorTicksPath = roundedRect.arcPosition(lambdas: majorTickPositions, width: 0.15 * shortEdge)
            let ringMajorTicks = CAShapeLayer()
            ringMajorTicks.path = ringMajorTicksPath
            
            ringMajorTicks.strokeColor = isDark ? watchLayout.majorTickColorDark.cgColor : watchLayout.majorTickColor.cgColor
            ringMajorTicks.lineWidth = majorLineWidth
        
            ringLayer.mask = ringMinorTicksMask
            
            let ringLayerAfterMinor = CALayer()
            ringLayerAfterMinor.addSublayer(ringLayer)
            
            let ringMajorTicksMaskPath = CGMutablePath()
            ringMajorTicksMaskPath.addPath(ringPath)
            ringMajorTicksMaskPath.addPath(ringMajorTicksPath.copy(strokingWithWidth: majorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            let ringMajorTicksMask = shapeFrom(path: ringMajorTicksMaskPath)
            ringLayerAfterMinor.mask = ringMajorTicksMask
            
            self.layer?.addSublayer(ringLayerAfterMinor)
            self.layer?.addSublayer(ringMinorTicks)
            self.layer?.addSublayer(ringMajorTicks)
            
            let textRing = roundedRect.shrink(by: 0.035 * shortEdge)
            let textPoints = textRing.arcPoints(lambdas: textPositions)
            let textMaskPath = CGMutablePath()
            let fontColor = isDark ? watchLayout.fontColorDark : watchLayout.fontColor
            for i in 0..<textPoints.count {
                let point = textPoints[i]
                let textBoxPath = drawText(str: texts[i], at: point.position, angle: point.direction, color: fontColor, size: fontSize)
                textMaskPath.addPath(textBoxPath)
            }
            
            ringMinorTrackPath.addPath(textMaskPath)
            let ringMinorTrack = shapeFrom(path: ringMinorTrackPath)
            ringMinorTicks.mask = ringMinorTrack
            
            let ringPathCopy = CGMutablePath()
            ringPathCopy.addPath(ringPath)
            ringPathCopy.addPath(textMaskPath)
            let ringTrack = shapeFrom(path: ringPathCopy)
            ringMajorTicks.mask = ringTrack
            
            let textMaskMinor = shapeFrom(path: textMaskPath)
            ringMinorTicksMask.addSublayer(textMaskMinor)
            let textMaskMajor = shapeFrom(path: textMaskPath)
            ringMajorTicksMask.addSublayer(textMaskMajor)
        }
        
        // Basic paths
        
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
        
        // Zero ring
        let fontSize: CGFloat = min(shortEdge * 0.03, longEdge * 0.025)
        let minorLineWidth = shortEdge / 500
        let majorLineWidth = shortEdge / 300

        let zeroRingOuter = outerBound.shrink(by: 0.01 * shortEdge)
        let zeroRingPath = zeroRingOuter.path
        zeroRingPath.addPath(firstRingOuterPath)
        let oddSolarTermTickColor = isDark ? watchLayout.oddSolarTermTickColorDark : watchLayout.oddSolarTermTickColor
        let evenSolarTermTickColor = isDark ? watchLayout.evenSolarTermTickColorDark : watchLayout.evenSolarTermTickColor
        
        let zeroRingOdd = shapeFrom(path: zeroRingPath)
        let zeroRingOddTicks = zeroRingOuter.arcPosition(lambdas: oddSolarTerms, width: 0.05 * shortEdge)
        let zeroRingOddTicksShape = shapeFrom(path: zeroRingOddTicks)
        zeroRingOddTicksShape.mask = zeroRingOdd
        zeroRingOddTicksShape.strokeColor = oddSolarTermTickColor.cgColor
        zeroRingOddTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(zeroRingOddTicksShape)

        let zeroRingEven = shapeFrom(path: zeroRingPath)
        let zeroRingEvenTicks = zeroRingOuter.arcPosition(lambdas: evenSolarTerms, width: 0.05 * shortEdge)
        let zeroRingEvenTicksShape = shapeFrom(path: zeroRingEvenTicks)
        zeroRingEvenTicksShape.mask = zeroRingEven
        zeroRingEvenTicksShape.strokeColor = evenSolarTermTickColor.cgColor
        zeroRingEvenTicksShape.lineWidth = shortEdge / 300
        self.layer?.addSublayer(zeroRingEvenTicksShape)
        
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
        
        // Draw other rings
        
        var previous: CGFloat = 0.0
        var monthNameStart = 0
        var monthPositions = [CGFloat]()
        for i in 0..<monthDivides.count {
            let position = (monthDivides[i] + previous) / 2
            if position > 0.01 && position < 0.99 {
                monthPositions.append(position)
            } else if position <= 0.01 {
                monthNameStart = 1
            }
            previous = monthDivides[i]
        }
        if (1 + previous) / 2 < 0.99 {
            monthPositions.append((1 + previous) / 2)
        }
        
        drawRing(ringPath: firstRingOuterPath, roundedRect: firstRingOuter, gradient: watchLayout.firstRing, angle: currentDayInYear, minorTickPositions: fullMoon, majorTickPositions: [0] + monthDivides, textPositions: monthPositions, texts: monthNames.slice(from: monthNameStart), fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
        drawMark(at: planetPosition, on: firstRingOuter, maskPath: firstRingOuterPath, colors: watchLayout.planetIndicator, radius: 0.012 * shortEdge)
        
        var dayPositions = [CGFloat]()
        var dayNameStart = 0
        previous = 0.0
        for i in 0..<dayDivides.count {
            let position = (dayDivides[i] + previous) / 2
            if position > 0.01 && position < 0.99 {
                dayPositions.append(position)
            } else if position <= 0.01 {
                dayNameStart = 1
            }
            previous = dayDivides[i]
        }
        if (1 + previous) / 2 < 0.99 {
            dayPositions.append((1 + previous) / 2)
        }
        drawRing(ringPath: secondRingOuterPath, roundedRect: secondRingOuter, gradient: watchLayout.secondRing, angle: currentDayInMonth, minorTickPositions: [], majorTickPositions: [0] + dayDivides, textPositions: dayPositions, texts: dayNames.slice(from: dayNameStart), fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
        addMarks(position: eventInMonth, on: secondRingOuter, maskPath: secondRingOuterPath, radius: 0.012 * shortEdge)
        
        var hourTick = [CGFloat]()
        for i in 0..<24 {
            hourTick.append(CGFloat(i) / 24)
        }
        var quarterTick = [CGFloat]()
        for i in 0..<100 {
            quarterTick.append(CGFloat(i) / 100)
        }
        var hourNamePositions = [CGFloat]()
        for i in 0..<12 {
            hourNamePositions.append(CGFloat(i) / 12)
        }

        drawRing(ringPath: thirdRingOuterPath, roundedRect: thirdRingOuter, gradient: watchLayout.thirdRing, angle: currentHour / 24, minorTickPositions: quarterTick, majorTickPositions: hourTick, textPositions: hourNamePositions, texts: ChineseCalendar.terrestrial_branches, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
        addMarks(position: eventInDay, on: thirdRingOuter, maskPath: thirdRingOuterPath, radius: 0.012 * shortEdge)
        
        let priorHour = CGFloat(Int(currentHour / 2) * 2)
        let nextHour = CGFloat((Int(currentHour / 2) + 1) % 12) * 2
        let fourthRingColor = WatchLayout.Gradient(locations: [0, 1], colors: [
            watchLayout.thirdRing.interpolate(at: 1-(nextHour / 24)),
            watchLayout.thirdRing.interpolate(at: 1-(priorHour / 24))
        ], loop: false)
        
        var subHourTicks: Set<CGFloat> = [0, 0.5]
        for i in 1..<10 {
            let tick = CGFloat(i * 6 - ((Int(currentHour / 2)*2) % 6)) / 50
            if tick < 1 {
                subHourTicks.insert(tick)
            }
        }
        var subQuarterTicks = Set<CGFloat>()
        for i in 0..<50 {
            subQuarterTicks.insert(CGFloat(i) / 50)
        }
        subQuarterTicks = subQuarterTicks.subtracting(subHourTicks)
        let subQuarterTick = Array(subQuarterTicks).sorted()
        let subHourTick = Array(subHourTicks).sorted()
        
        let evenHourText = ChineseCalendar.terrestrial_branches[Int(currentHour / 2)] + ChineseCalendar.sub_hour_name[1]
        let oddHourText = ChineseCalendar.terrestrial_branches[(Int(currentHour / 2)+1) % 12] + ChineseCalendar.sub_hour_name[0]
        var subHourTexts = [String]()
        var subHourTextsPositions = [CGFloat]()
        for i in 0..<subHourTick.count {
            let str: String
            let dist = abs(subHourTick[i] * 2 - round(subHourTick[i] * 2))
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
                subHourTexts.append(str)
                subHourTextsPositions.append(subHourTick[i])
            }
        }
        
        drawRing(ringPath: fourthRingOuterPath, roundedRect: fourthRingOuter, gradient: fourthRingColor, angle: (currentHour - priorHour) / 2, minorTickPositions: subQuarterTick, majorTickPositions: subHourTick, textPositions: subHourTextsPositions, texts: subHourTexts, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
        addMarks(position: eventInHour, on: fourthRingOuter, maskPath: fourthRingOuterPath, radius: 0.012 * shortEdge)
        
        let innerBox = CAShapeLayer()
        innerBox.path = innerBoundPath
        innerBox.fillColor = isDark ? watchLayout.innerColorDark.cgColor : watchLayout.innerColor.cgColor
        self.layer?.addSublayer(innerBox)
        
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
