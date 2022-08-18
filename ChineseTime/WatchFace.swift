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
        
        var firstLine = [(CGFloat, Int)](), secondLine = [(CGFloat, Int)](), thirdLine = [(CGFloat, Int)](), fourthLine = [(CGFloat, Int)](), fifthLine = [(CGFloat, Int)]()
        var firstArc = [(CGFloat, Int)](), secondArc = [(CGFloat, Int)](), thirdArc = [(CGFloat, Int)](), fourthArc = [(CGFloat, Int)]()
        
        var i = 0
        for lambda in lambdas {
            switch lambda * totalLength {
            case 0.0..<innerWidth/2:
                firstLine.append((lambda * totalLength, i))
            case (innerWidth/2)..<(innerWidth/2+arcLength):
                firstArc.append(((lambda * totalLength - innerWidth/2) / arcLength, i))
            case (innerWidth/2+arcLength)..<(innerWidth/2+arcLength+innerHeight):
                secondLine.append((lambda * totalLength - innerWidth/2 - arcLength, i))
            case (innerWidth/2+arcLength+innerHeight)..<(innerWidth/2+2*arcLength+innerHeight):
                secondArc.append(((lambda * totalLength - (innerWidth/2+arcLength+innerHeight)) / arcLength, i))
            case (innerWidth/2+2*arcLength+innerHeight)..<(innerWidth*1.5+2*arcLength+innerHeight):
                thirdLine.append((lambda * totalLength - (innerWidth/2+2*arcLength+innerHeight), i))
            case (innerWidth*1.5+2*arcLength+innerHeight)..<(innerWidth*1.5+3*arcLength+innerHeight):
                thirdArc.append(((lambda * totalLength-(innerWidth*1.5+2*arcLength+innerHeight)) / arcLength, i))
            case (innerWidth*1.5+3*arcLength+innerHeight)..<(innerWidth*1.5+3*arcLength+2*innerHeight):
                fourthLine.append((lambda * totalLength - (innerWidth*1.5+3*arcLength+innerHeight), i))
            case (innerWidth*1.5+3*arcLength+2*innerHeight)..<(totalLength-innerWidth/2):
                fourthArc.append(((lambda * totalLength-(innerWidth*1.5+3*arcLength+2*innerHeight)) / arcLength, i))
            case (totalLength-innerWidth/2)...totalLength:
                fifthLine.append((lambda * totalLength - (totalLength-innerWidth/2), i))
            default:
                return []
            }
            i += 1
        }
        
        var points = [(OrientedPoint, Int)]()
        
        for (lambda, i) in firstLine {
            let start = NSMakePoint(_boundBox.midX + lambda, _boundBox.maxY)
            let normAngle: CGFloat = 0
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in firstArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            start = NSMakePoint(_boundBox.maxX - start.y, _boundBox.maxY - start.x)
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in secondLine {
            let start = NSMakePoint(_boundBox.maxX, _boundBox.maxY - _nodePos - lambda)
            let normAngle = CGFloat.pi / 2
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in secondArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            start = NSMakePoint(_boundBox.maxX - start.x, _boundBox.minY + start.y)
            normAngle += CGFloat.pi / 2
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in thirdLine {
            let start = NSMakePoint(_boundBox.maxX - _nodePos - lambda, _boundBox.minY)
            let normAngle = CGFloat.pi
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in thirdArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            normAngle += CGFloat.pi
            start = NSMakePoint(_boundBox.minX + start.y, _boundBox.minY + start.x)
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in fourthLine {
            let start = NSMakePoint(_boundBox.minX, _boundBox.minY + _nodePos + lambda)
            let normAngle = CGFloat.pi * 3/2
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in fourthArc {
            var (start, normAngle) = bezierNorm(l: lambda)
            normAngle += CGFloat.pi * 3/2
            start = NSMakePoint(_boundBox.minX + start.x, _boundBox.maxY - start.y)
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        for (lambda, i) in fifthLine {
            let start = NSMakePoint(_boundBox.minX + _nodePos + lambda, _boundBox.maxY)
            let normAngle: CGFloat = 0
            points.append((OrientedPoint(position: start, direction: normAngle), i))
        }
        
        return points.sorted { $0.1 < $1.1 }.map { $0.0 }
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
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval / 12
    
    class GraphicArtifects {
        var outerBound: RoundedRect?
        var firstRingOuter: RoundedRect?
        var firstRingInner: RoundedRect?
        var secondRingOuter: RoundedRect?
        var secondRingInner: RoundedRect?
        var thirdRingOuter: RoundedRect?
        var thirdRingInner: RoundedRect?
        var fourthRingOuter: RoundedRect?
        var fourthRingInner: RoundedRect?
        var innerBound: RoundedRect?
        var zeroRingOuter: RoundedRect?
        var solarTermsRing: RoundedRect?
        
        var outerBoundPath: CGMutablePath?
        var firstRingOuterPath: CGMutablePath?
        var firstRingInnerPath: CGMutablePath?
        var secondRingOuterPath: CGMutablePath?
        var secondRingInnerPath: CGMutablePath?
        var thirdRingOuterPath: CGMutablePath?
        var thirdRingInnerPath: CGMutablePath?
        var fourthRingOuterPath: CGMutablePath?
        var fourthRingInnerPath: CGMutablePath?
        var innerBoundPath: CGMutablePath?
        
        var outerOddLayer: CALayer?
        var outerEvenLayer: CALayer?
        var firstRingLayer: CALayer?
        var firstRingMarks: CALayer?
        var secondRingLayer: CALayer?
        var secondRingMarks: CALayer?
        var thirdRingLayer: CALayer?
        var thirdRingMarks: CALayer?
        var fourthRingLayer: CALayer?
        var fourthRingMarks: CALayer?
        var innerBox: CAShapeLayer?
        var centerText: CALayer?
    }
    
    struct KeyStates {
        var year = -1
        var globalMonth = true
        var month = -1
        var day = -1
        var yearUpdatedTime = Date()
        var monthUpdatedTime = Date()
        var priorHour: CGFloat = -1.0
        var datetimeString = ""
        var timezone = -1
    }
    
    static var layoutTemplate: String? = nil
    let watchLayout: WatchLayout
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var location: NSPoint = NSMakePoint(0, CGFloat(Calendar.current.timeZone.secondsFromGMT()) / 86400 * 360)
    var shape: CAShapeLayer = CAShapeLayer()
    
    var cornerSize: CGFloat = 0.3
    private var chineseCalendar = ChineseCalendar(time: Date(), timezone: TimeZone.current)
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
    private var dateString: String = ""
    private var timeString: String = ""
    private var calPlanetTime: Date = Date()
    private var planetPosition: [CGFloat] = []
    private var sunPositions: [CGFloat?] = []
    private var moonPositions: [CGFloat?] = []
    private var eventInMonth = ChineseCalendar.CelestialEvent()
    private var eventInDay = ChineseCalendar.CelestialEvent()
    private var eventInHour = ChineseCalendar.CelestialEvent()
    
    var graphicArtifects = GraphicArtifects()
    private var keyStates = KeyStates()
    
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
        self.graphicArtifects = GraphicArtifects()
        self.needsDisplay = true
    }
    
    func update() {
        let time = displayTime ?? Date()
        if !chineseCalendar.update(time: time, timezone: timezone) {
            self.chineseCalendar = ChineseCalendar(time: time, timezone: timezone)
        }
        self.dateString = chineseCalendar.dateString
        self.timeString = chineseCalendar.timeString
        self.evenSolarTerms = chineseCalendar.evenSolarTerms
        self.oddSolarTerms = chineseCalendar.oddSolarTerms
        self.monthDivides = chineseCalendar.monthDivides
        self.fullMoon = chineseCalendar.fullmoon
        self.monthNames = chineseCalendar.monthNames
        self.dayNames = chineseCalendar.dayNames
        self.currentDayInYear = chineseCalendar.currentDayInYear
        self.currentDayInMonth = chineseCalendar.currentDayInMonth
        self.currentHour = chineseCalendar.currentHour
        self.currentDay = chineseCalendar.currentDay
        self.dayDivides = chineseCalendar.dayDivides
        self.eventInMonth = chineseCalendar.eventInMonth
        self.eventInDay = chineseCalendar.eventInDay
        self.eventInHour = chineseCalendar.eventInHour
        
        if planetPosition.isEmpty || (abs(calPlanetTime.distance(to: time)) >= Self.majorUpdateInterval) {
            // Expensive calculation
            self.planetPosition = chineseCalendar.planetPosition
            calPlanetTime = time
        }
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
            let radius = sqrt(pow(circle._boundBox.width, 2) + pow(circle._boundBox.height, 2))
            let center = NSMakePoint(circle._boundBox.midX, circle._boundBox.midY)
            let anglePoint = circle.arcPoints(lambdas: [min(1 - 1e-15, max(0, angle))])[0].position
            let angle = atan2(anglePoint.y - center.y, anglePoint.x - center.x)
            let endAngle = (CGFloat.pi / 2 - angle) % (CGFloat.pi * 2) - CGFloat.pi / 2
            let path = CGMutablePath()
            path.move(to: center)
            path.addLine(to: center + NSMakePoint(0, radius))
            path.addArc(center: center, radius: radius, startAngle: CGFloat.pi / 2, endAngle: -endAngle, clockwise: true)
            path.closeSubpath()
            let shape = CAShapeLayer()
            shape.path = path
            return shape
        }
        
        func applyGradient(to path: CGPath, gradient: WatchLayout.Gradient, alpha: CGFloat = 1.0, angle: CGFloat? = nil, outerRing: RoundedRect? = nil) -> CAGradientLayer {
            let gradientLayer = CAGradientLayer()
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint = gradientLayer.startPoint + NSMakePoint(0, 0.5)
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
        
        func drawMark(at locations: [CGFloat], on ring: RoundedRect, maskPath: CGPath, colors: [NSColor], radius: CGFloat) -> CALayer {
            let marks = CALayer()
            let points = ring.arcPoints(lambdas: locations.filter { 0 <= $0 && 1 >= $0} )
            for i in 0..<locations.count {
                let point = points[i]
                let pos = point.position
                let angle = point.direction
                var transform = CGAffineTransform(translationX: -pos.x, y: -pos.y)
                transform = transform.concatenating(CGAffineTransform(rotationAngle: -angle))
                transform = transform.concatenating(CGAffineTransform(translationX: pos.x, y: pos.y))
                let markPath: CGPath = RoundedRect(rect: NSMakeRect(pos.x - radius, pos.y - radius, 2 * radius, 2 * radius), nodePos: 0.7 * radius, ankorPos: 0.3 * radius).path
                let mark = shapeFrom(path: markPath)
                mark.setAffineTransform(transform)
                mark.fillColor = colors[i % colors.count].cgColor
                mark.shadowPath = mark.path
                mark.shadowOffset = NSZeroSize
                mark.shadowRadius = radius / 2
                mark.shadowOpacity = Float(0.3 * mark.fillColor!.alpha)
                marks.addSublayer(mark)
            }
            let mask = shapeFrom(path: maskPath)
            marks.mask = mask
            return marks
        }
        
        func addMarks(position: ChineseCalendar.CelestialEvent, on ring: RoundedRect, maskPath: CGPath, radius: CGFloat) -> CALayer {
            let marks = CALayer()
            marks.addSublayer(drawMark(at: position.eclipse, on: ring, maskPath: maskPath, colors: [watchLayout.eclipseIndicator], radius: radius))
            marks.addSublayer(drawMark(at: position.fullMoon, on: ring, maskPath: maskPath, colors: [watchLayout.fullmoonIndicator], radius: radius))
            marks.addSublayer(drawMark(at: position.oddSolarTerm, on: ring, maskPath: maskPath, colors: [watchLayout.oddStermIndicator], radius: radius))
            marks.addSublayer(drawMark(at: position.evenSolarTerm, on: ring, maskPath: maskPath, colors: [watchLayout.evenStermIndicator], radius: radius))
            return marks
        }
        
        func drawText(str: String, at: NSPoint, angle: CGFloat, color: NSColor, size: CGFloat) -> (CALayer, CGPath) {
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
            let finishedRingLayer = CALayer()
            finishedRingLayer.addSublayer(textLayer)
            return (finishedRingLayer, path)
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
        
        func drawRing(ringPath: CGPath, roundedRect: RoundedRect, gradient: WatchLayout.Gradient, minorTickPositions: [CGFloat], majorTickPositions: [CGFloat], textPositions: [CGFloat], texts: [String], fontSize: CGFloat, minorLineWidth: CGFloat, majorLineWidth: CGFloat) -> CALayer {
            
            let ringLayer = CALayer()
            let ringShadow = applyGradient(to: ringPath, gradient: gradient, alpha: watchLayout.shadeAlpha)
            ringLayer.addSublayer(ringShadow)
            
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
            let ringBase = shapeFrom(path: ringPath)
            ringBase.fillColor = NSColor.init(white: 1, alpha: watchLayout.minorTickAlpha).cgColor
            ringMinorTicksMask.addSublayer(ringCrust)
            ringMinorTicksMask.addSublayer(ringBase)
            
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
            let ringBase2 = shapeFrom(path: ringPath)
            ringBase2.fillColor = NSColor.init(white: 1, alpha: watchLayout.majorTickAlpha).cgColor
            ringMajorTicksMask.addSublayer(ringBase2)
            ringLayerAfterMinor.mask = ringMajorTicksMask
            
            let finishedRingLayer = CALayer()
            finishedRingLayer.addSublayer(ringLayerAfterMinor)
            finishedRingLayer.addSublayer(ringMinorTicks)
            finishedRingLayer.addSublayer(ringMajorTicks)
            
            let textRing = roundedRect.shrink(by: 0.035 * shortEdge)
            let textPoints = textRing.arcPoints(lambdas: textPositions)
            let textMaskPath = CGMutablePath()
            let fontColor = isDark ? watchLayout.fontColorDark : watchLayout.fontColor
            for i in 0..<textPoints.count {
                let point = textPoints[i]
                let (textLayer, textBoxPath) = drawText(str: texts[i], at: point.position, angle: point.direction, color: fontColor, size: fontSize)
                textMaskPath.addPath(textBoxPath)
                finishedRingLayer.addSublayer(textLayer)
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
            
            return finishedRingLayer
        }
        func activeRingAngle(to layer: CALayer, ringPath: CGPath, gradient: WatchLayout.Gradient, angle: CGFloat, outerRing: RoundedRect) {
            let ringActive = applyGradient(to: ringPath, gradient: gradient, angle: angle, outerRing: outerRing)
            if let count = layer.sublayers?[0].sublayers?[0].sublayers?.count, count < 2 {
                layer.sublayers?[0].sublayers?[0].addSublayer(ringActive)
            } else {
                layer.sublayers?[0].sublayers?[0].sublayers?[1] = ringActive
            }
        }
        
        func drawOuterRing(path: CGPath, roundedRect: RoundedRect, textRoundedRect: RoundedRect, tickPositions: [CGFloat], texts: [String], fontSize: CGFloat, lineWidth: CGFloat, color: NSColor) -> CALayer {
            let ringPath = roundedRect.path
            ringPath.addPath(path)
            
            let ringShape = shapeFrom(path: ringPath)
            let ringTicks = roundedRect.arcPosition(lambdas: tickPositions, width: 0.05 * shortEdge)
            let ringTicksShape = shapeFrom(path: ringTicks)
            ringTicksShape.mask = ringShape
            ringTicksShape.strokeColor = color.cgColor
            ringTicksShape.lineWidth = lineWidth
            let finishedRingLayer = CALayer()
            finishedRingLayer.addSublayer(ringTicksShape)
            
            var i = 0
            let points = textRoundedRect.arcPoints(lambdas: tickPositions)
            for point in points {
                let (textLayer, _) = drawText(str: texts[i], at: point.position, angle: point.direction, color: color, size: fontSize)
                finishedRingLayer.addSublayer(textLayer)
                i += 1
            }
            return finishedRingLayer
        }
        
        func calMonthParams() -> (Int, [CGFloat]) {
            var previous: CGFloat = 0.0
            var monthNameStart = 0
            var monthPositions = [CGFloat]()
            let minMonthLength: CGFloat = 0.01
            for i in 0..<monthDivides.count {
                let position = (monthDivides[i] + previous) / 2
                if position > minMonthLength && position < 1-minMonthLength {
                    monthPositions.append(position)
                } else if position <= minMonthLength {
                    monthNameStart = 1
                }
                previous = monthDivides[i]
            }
            if (1 + previous) / 2 < 1-minMonthLength {
                monthPositions.append((1 + previous) / 2)
            }
            return (monthNameStart, monthPositions)
        }
        
        func calDayParams() -> (Int, [CGFloat]) {
            var dayPositions = [CGFloat]()
            var dayNameStart = 0
            var previous: CGFloat = 0.0
            let minDayLength = 0.01
            for i in 0..<dayDivides.count {
                let position = (dayDivides[i] + previous) / 2
                if position > minDayLength && position < 1-minDayLength {
                    dayPositions.append(position)
                } else if position <= minDayLength {
                    dayNameStart = 1
                }
                previous = dayDivides[i]
            }
            if (1 + previous) / 2 < 1-minDayLength {
                dayPositions.append((1 + previous) / 2)
            }
            return (dayNameStart, dayPositions)
        }
        
        func calHourParams() -> ([CGFloat], [CGFloat], [CGFloat]) {
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
            return (hourNamePositions, hourTick, quarterTick)
        }
        
        func calSubHourParams() -> (WatchLayout.Gradient, CGFloat, [String], [CGFloat], [CGFloat], [CGFloat]) {
            let priorHour = floor(currentHour / 2) * 2
            let nextHour = ((floor(currentHour / 2) + 1) % 12) * 2
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
            
            let evenHourText = ChineseCalendar.terrestrial_branches[Int(currentHour / 2) % 12] + ChineseCalendar.sub_hour_name[1]
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
            return (fourthRingColor, priorHour, subHourTexts, subHourTextsPositions, subHourTick, subQuarterTick)
        }
        
        func drawCenterTextGradient(innerBound: RoundedRect) -> CALayer {
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
            
            return gradientLayer as CALayer
        }
        
        func getVagueShapes(shortEdge: CGFloat, longEdge: CGFloat) {
            // Basic paths
            graphicArtifects.outerBound = RoundedRect(rect: dirtyRect, nodePos: cornerSize, ankorPos: cornerSize*0.2)
            graphicArtifects.firstRingOuter = graphicArtifects.outerBound!.shrink(by: 0.05 * shortEdge)
            graphicArtifects.firstRingInner = graphicArtifects.firstRingOuter!.shrink(by: 0.07 * shortEdge)
            
            graphicArtifects.secondRingOuter = graphicArtifects.firstRingInner!.shrink(by: 0.01 * shortEdge)
            graphicArtifects.secondRingInner = graphicArtifects.secondRingOuter!.shrink(by: 0.07 * shortEdge)
            
            graphicArtifects.thirdRingOuter = graphicArtifects.secondRingInner!.shrink(by: 0.01 * shortEdge)
            graphicArtifects.thirdRingInner = graphicArtifects.thirdRingOuter!.shrink(by: 0.07 * shortEdge)
            
            graphicArtifects.fourthRingOuter = graphicArtifects.thirdRingInner!.shrink(by: 0.01 * shortEdge)
            graphicArtifects.fourthRingInner = graphicArtifects.fourthRingOuter!.shrink(by: 0.07 * shortEdge)
            
            graphicArtifects.innerBound = graphicArtifects.fourthRingInner!.shrink(by: 0.01 * shortEdge)
            
            graphicArtifects.outerBoundPath = graphicArtifects.outerBound!.path
            graphicArtifects.firstRingOuterPath = graphicArtifects.firstRingOuter!.path
            graphicArtifects.firstRingInnerPath = graphicArtifects.firstRingInner!.path
            graphicArtifects.firstRingOuterPath!.addPath(graphicArtifects.firstRingInnerPath!)
            
            graphicArtifects.secondRingOuterPath = graphicArtifects.secondRingOuter!.path
            graphicArtifects.secondRingInnerPath = graphicArtifects.secondRingInner!.path
            graphicArtifects.secondRingOuterPath!.addPath(graphicArtifects.secondRingInnerPath!)
            
            graphicArtifects.thirdRingOuterPath = graphicArtifects.thirdRingOuter!.path
            graphicArtifects.thirdRingInnerPath = graphicArtifects.thirdRingInner!.path
            graphicArtifects.thirdRingOuterPath!.addPath(graphicArtifects.thirdRingInnerPath!)
            
            graphicArtifects.fourthRingOuterPath = graphicArtifects.fourthRingOuter!.path
            graphicArtifects.fourthRingInnerPath = graphicArtifects.fourthRingInner!.path
            graphicArtifects.fourthRingOuterPath!.addPath(graphicArtifects.fourthRingInnerPath!)
            
            graphicArtifects.innerBoundPath = graphicArtifects.innerBound!.path
            
            // Will be used from outside this View
            shape.path = graphicArtifects.firstRingOuterPath!
            shape.fillColor = NSColor(deviceWhite: 1.0, alpha: watchLayout.backAlpha).cgColor
            shape.shadowPath = graphicArtifects.outerBoundPath!
            shape.shadowColor = shape.fillColor
            shape.shadowOpacity = 1
            shape.shadowOffset = NSMakeSize(0, 0)
            shape.shadowRadius = frameOffset / 2
        }
        
        let shortEdge = min(dirtyRect.width, dirtyRect.height)
        let longEdge = max(dirtyRect.width, dirtyRect.height)
        let fontSize: CGFloat = min(shortEdge * 0.03, longEdge * 0.025)
        let minorLineWidth = shortEdge / 500
        let majorLineWidth = shortEdge / 300
        
        if graphicArtifects.outerBound == nil {
            getVagueShapes(shortEdge: shortEdge, longEdge: longEdge)
        }
        
        // Zero ring
        if (graphicArtifects.zeroRingOuter == nil) || (chineseCalendar.year != keyStates.year) {
            
            graphicArtifects.zeroRingOuter = graphicArtifects.outerBound!.shrink(by: 0.01 * shortEdge)
            graphicArtifects.solarTermsRing = graphicArtifects.zeroRingOuter!.shrink(by: 0.02 * shortEdge)
            let oddSolarTermTickColor = isDark ? watchLayout.oddSolarTermTickColorDark : watchLayout.oddSolarTermTickColor
            let evenSolarTermTickColor = isDark ? watchLayout.evenSolarTermTickColorDark : watchLayout.evenSolarTermTickColor
            
            graphicArtifects.outerOddLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.zeroRingOuter!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: oddSolarTerms, texts: ChineseCalendar.oddSolarTermChinese, fontSize: fontSize, lineWidth: majorLineWidth, color: oddSolarTermTickColor)
            graphicArtifects.outerEvenLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.zeroRingOuter!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: evenSolarTerms, texts: ChineseCalendar.evenSolarTermChinese, fontSize: fontSize, lineWidth: majorLineWidth, color: evenSolarTermTickColor)
        }
        self.layer?.addSublayer(graphicArtifects.outerOddLayer!)
        self.layer?.addSublayer(graphicArtifects.outerEvenLayer!)
        
        // First Ring
        if (graphicArtifects.firstRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.yearUpdatedTime)) >= Self.majorUpdateInterval) {
            if (graphicArtifects.firstRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) {
                let (monthNameStart, monthPositions) = calMonthParams()
                graphicArtifects.firstRingLayer = drawRing(ringPath: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.firstRingOuter!, gradient: watchLayout.firstRing, minorTickPositions: fullMoon, majorTickPositions: [0] + monthDivides, textPositions: monthPositions, texts: monthNames.slice(from: monthNameStart), fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
                keyStates.year = chineseCalendar.year
            }
            graphicArtifects.firstRingMarks = drawMark(at: planetPosition, on: graphicArtifects.firstRingOuter!, maskPath: graphicArtifects.firstRingOuterPath!, colors: watchLayout.planetIndicator, radius: 0.012 * shortEdge)
            activeRingAngle(to: graphicArtifects.firstRingLayer!, ringPath: graphicArtifects.firstRingOuterPath!, gradient: watchLayout.firstRing, angle: currentDayInYear, outerRing: graphicArtifects.firstRingOuter!)
            keyStates.yearUpdatedTime = chineseCalendar.time
        }
        self.layer?.addSublayer(graphicArtifects.firstRingLayer!)
        self.layer?.addSublayer(graphicArtifects.firstRingMarks!)
        
        // Second Ring
        if (graphicArtifects.secondRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.month != keyStates.month) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.monthUpdatedTime)) >= Self.minorUpdateInterval) {
            if (graphicArtifects.secondRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.month != keyStates.month) || (chineseCalendar.timezone != keyStates.timezone) || (ChineseCalendar.globalMonth != keyStates.globalMonth) {
                let (dayNameStart, dayPositions) = calDayParams()
                graphicArtifects.secondRingLayer = drawRing(ringPath: graphicArtifects.secondRingOuterPath!, roundedRect: graphicArtifects.secondRingOuter!, gradient: watchLayout.secondRing, minorTickPositions: [], majorTickPositions: [0] + dayDivides, textPositions: dayPositions, texts: dayNames.slice(from: dayNameStart), fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
                graphicArtifects.secondRingMarks = addMarks(position: eventInMonth, on: graphicArtifects.secondRingOuter!, maskPath: graphicArtifects.secondRingOuterPath!, radius: 0.012 * shortEdge)
                keyStates.month = chineseCalendar.month
                keyStates.globalMonth = ChineseCalendar.globalMonth
            }
            activeRingAngle(to: graphicArtifects.secondRingLayer!, ringPath: graphicArtifects.secondRingOuterPath!, gradient: watchLayout.secondRing, angle: currentDayInMonth, outerRing: graphicArtifects.secondRingOuter!)
            keyStates.monthUpdatedTime = chineseCalendar.time
        }
        self.layer?.addSublayer(graphicArtifects.secondRingLayer!)
        self.layer?.addSublayer(graphicArtifects.secondRingMarks!)
        
        // Third Ring
        if (graphicArtifects.thirdRingLayer == nil) || (keyStates.day != chineseCalendar.currentDay) || (chineseCalendar.timezone != keyStates.timezone) {
            sunPositions = chineseCalendar.sunPositions(latitude: location.x, longitude: location.y)
            moonPositions = chineseCalendar.moonrise(latitude: location.x, longitude: location.y)
            if graphicArtifects.thirdRingLayer == nil {
                let (hourNamePositions, hourTick, quarterTick) = calHourParams()
                graphicArtifects.thirdRingLayer = drawRing(ringPath: graphicArtifects.thirdRingOuterPath!, roundedRect: graphicArtifects.thirdRingOuter!, gradient: watchLayout.thirdRing, minorTickPositions: quarterTick, majorTickPositions: hourTick, textPositions: hourNamePositions, texts: ChineseCalendar.terrestrial_branches, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
            }
            graphicArtifects.thirdRingMarks = addMarks(position: eventInDay, on: graphicArtifects.thirdRingOuter!, maskPath: graphicArtifects.thirdRingOuterPath!, radius: 0.012 * shortEdge)
            var sunPositionsInDay = [CGFloat](), moonPositionsInDay = [CGFloat]()
            var sunPositionsInDayColors = [NSColor](), moonPositionsInDayColors = [NSColor]()
            for i in 0..<sunPositions.count {
                if let sunPos = sunPositions[i] {
                    sunPositionsInDay.append(sunPos)
                    sunPositionsInDayColors.append(watchLayout.sunPositionIndicator[i%4])
                }
            }
            for i in 0..<moonPositions.count {
                if let moonPos = moonPositions[i] {
                    moonPositionsInDay.append(moonPos)
                    moonPositionsInDayColors.append(watchLayout.moonPositionIndicator[i%3])
                }
            }
            graphicArtifects.thirdRingMarks?.addSublayer(drawMark(at: sunPositionsInDay, on: graphicArtifects.thirdRingInner!, maskPath: graphicArtifects.thirdRingOuterPath!, colors: sunPositionsInDayColors, radius: 0.012 * shortEdge))
            graphicArtifects.thirdRingMarks?.addSublayer(drawMark(at: moonPositionsInDay, on: graphicArtifects.thirdRingInner!, maskPath: graphicArtifects.thirdRingOuterPath!, colors: moonPositionsInDayColors, radius: 0.012 * shortEdge))
            keyStates.day = chineseCalendar.currentDay
        }
        activeRingAngle(to: graphicArtifects.thirdRingLayer!, ringPath: graphicArtifects.thirdRingOuterPath!, gradient: watchLayout.thirdRing, angle: currentHour / 24, outerRing: graphicArtifects.thirdRingOuter!)
        self.layer?.addSublayer(graphicArtifects.thirdRingLayer!)
        self.layer?.addSublayer(graphicArtifects.thirdRingMarks!)
        
        // Fourth Ring
        let (fourthRingColor, priorHour, subHourTexts, subHourTextsPositions, subHourTick, subQuarterTick) = calSubHourParams()
        if (graphicArtifects.fourthRingLayer == nil) || (priorHour != keyStates.priorHour) || (chineseCalendar.timezone != keyStates.timezone) {
            if (graphicArtifects.fourthRingLayer == nil) || (priorHour != keyStates.priorHour) {
                graphicArtifects.fourthRingLayer = drawRing(ringPath: graphicArtifects.fourthRingOuterPath!, roundedRect: graphicArtifects.fourthRingOuter!, gradient: fourthRingColor, minorTickPositions: subQuarterTick, majorTickPositions: subHourTick, textPositions: subHourTextsPositions, texts: subHourTexts, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
                keyStates.priorHour = priorHour
            }
            graphicArtifects.fourthRingMarks = addMarks(position: eventInHour, on: graphicArtifects.fourthRingOuter!, maskPath: graphicArtifects.fourthRingOuterPath!, radius: 0.012 * shortEdge)
            var sunPositionsSubhour = [CGFloat](), moonPositionsSubhour = [CGFloat]()
            var sunPositionsSubhourColors = [NSColor](), moonPositionsSubhourColors = [NSColor]()
            for i in 0..<sunPositions.count {
                if let sunPos = sunPositions[i], Int(sunPos * 12) == Int(currentHour / 2) {
                    sunPositionsSubhour.append(sunPos.truncatingRemainder(dividingBy: 1/12) * 12)
                    sunPositionsSubhourColors.append(watchLayout.sunPositionIndicator[i % 4])
                }
            }
            for i in 0..<moonPositions.count {
                if let moonPos = moonPositions[i], Int(moonPos * 12) == Int(currentHour / 2) {
                    moonPositionsSubhour.append(moonPos.truncatingRemainder(dividingBy: 1/12) * 12)
                    moonPositionsSubhourColors.append(watchLayout.moonPositionIndicator[i % 3])
                }
            }
            graphicArtifects.fourthRingMarks?.addSublayer(drawMark(at: sunPositionsSubhour, on: graphicArtifects.fourthRingInner!, maskPath: graphicArtifects.fourthRingOuterPath!, colors: sunPositionsSubhourColors, radius: 0.012 * shortEdge))
            graphicArtifects.fourthRingMarks?.addSublayer(drawMark(at: moonPositionsSubhour, on: graphicArtifects.fourthRingInner!, maskPath: graphicArtifects.fourthRingOuterPath!, colors: moonPositionsSubhourColors, radius: 0.012 * shortEdge))
            keyStates.timezone = chineseCalendar.timezone
        }
        activeRingAngle(to: graphicArtifects.fourthRingLayer!, ringPath: graphicArtifects.fourthRingOuterPath!, gradient: fourthRingColor, angle: (currentHour - priorHour) / 2, outerRing: graphicArtifects.fourthRingOuter!)
        self.layer?.addSublayer(graphicArtifects.fourthRingLayer!)
        self.layer?.addSublayer(graphicArtifects.fourthRingMarks!)
        
        if (graphicArtifects.innerBox == nil) {
            graphicArtifects.innerBox = shapeFrom(path: graphicArtifects.innerBoundPath!)
            graphicArtifects.innerBox!.fillColor = isDark ? watchLayout.innerColorDark.cgColor : watchLayout.innerColor.cgColor
        }
        self.layer?.addSublayer(graphicArtifects.innerBox!)
        
        // Center text
        if (graphicArtifects.centerText == nil) || (dateString+timeString != keyStates.datetimeString) {
            graphicArtifects.centerText = drawCenterTextGradient(innerBound: graphicArtifects.innerBound!)
            keyStates.datetimeString = dateString+timeString
        }
        self.layer?.addSublayer(graphicArtifects.centerText!)
    }
}

class WatchFace: NSWindow {
    let _view: WatchFaceView
    let _backView: NSVisualEffectView
    private var _visible = false
    private var _timer: Timer?
    static var currentInstance: WatchFace? = nil
    private static let updateInterval: CGFloat = 14.4
    
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
    
    var isLocked: Bool {
        !self.isMovableByWindowBackground
    }
    var isTop: Bool {
        self.level == NSWindow.Level.floating
    }
    
    func locked(_ on: Bool) {
        if on {
            self.isMovableByWindowBackground = false
        } else {
            self.isMovableByWindowBackground = true
        }
    }
    func setTop(_ on: Bool) {
        if on {
            self.level = NSWindow.Level.floating
        } else {
            self.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
        }
    }
    func setCenter() {
        let windowRect = self.getCurrentScreen()
        self.setFrame(NSMakeRect(
                        windowRect.midX - _view.watchLayout.watchSize.width / 2,
                        windowRect.midY - _view.watchLayout.watchSize.height / 2,
                        _view.watchLayout.watchSize.width, _view.watchLayout.watchSize.height), display: true)
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
            setCenter()
        } else {
            self.setFrame(NSMakeRect(
                            frame!.midX - watchDimension.width / 2,
                            frame!.midY - watchDimension.height / 2,
                            watchDimension.width, watchDimension.height), display: true)
        }
        _view.frame = _view.superview!.bounds
        _backView.frame = _view.superview!.bounds
        _view.cornerSize = _view.watchLayout.cornerRadiusRatio * min(watchDimension.width, watchDimension.height)
        _view.graphicArtifects = WatchFaceView.GraphicArtifects()
    }
    
    func show() {
        updateSize(with: nil)
        self.invalidateShadow()
        _view.drawView()
        self._backView.layer?.mask = _view.shape
        self.orderFront(nil)
        self._visible = true
        self._timer = Timer.scheduledTimer(withTimeInterval: Self.updateInterval, repeats: true) {_ in
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
