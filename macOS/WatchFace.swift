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
    
    func copy() -> RoundedRect {
        return RoundedRect(rect: _boundBox, nodePos: _nodePos, ankorPos: _ankorPos)
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
            case (innerWidth*1.5+3*arcLength+2*innerHeight)..<(innerWidth*1.5+4*arcLength+2*innerHeight):
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
    static let frameOffset: CGFloat = 5
    
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
        var priorHour = Date()
        var dateString = ""
        var timeString = ""
        var timezone = -1
    }
    
    struct StartingPhase {
        var zeroRing: CGFloat = -0.5
        var firstRing: CGFloat = -0.5
        var secondRing: CGFloat = -0.5
        var thirdRing: CGFloat = -0.5
        var fourthRing: CGFloat = -0.5
    }
    
    static var layoutTemplate: String? = nil
    let watchLayout: WatchLayout
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var location: NSPoint? = nil
    var shape: CAShapeLayer = CAShapeLayer()
    var phase: StartingPhase = StartingPhase()
    
    var cornerSize: CGFloat = 0.3
    private var chineseCalendar = ChineseCalendar(time: Date(), timezone: TimeZone.current, location: nil)
    
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
    
    func update(forchRefresh: Bool) {
        let time = displayTime ?? Date()
        if forchRefresh || !chineseCalendar.update(time: time, timezone: timezone, location: location) {
            self.chineseCalendar = ChineseCalendar(time: time, timezone: timezone, location: location)
        }
    }
    
    func drawView(forceRefresh: Bool) {
        self.layer?.sublayers = nil
        update(forchRefresh: forceRefresh)
        self.needsDisplay = true
    }
    
    func updateStatusBar() {
        Chinese_Time.updateStatusTitle(title: "\(chineseCalendar.dateString) \(chineseCalendar.timeString)")
    }
    
    override func draw(_ rawRect: NSRect) {
        let dirtyRect = rawRect.insetBy(dx: Self.frameOffset, dy: Self.frameOffset)
        let isDark = self.isDark
        
        func angleMask(angle: CGFloat, startingAngle: CGFloat, in circle: RoundedRect) -> CAShapeLayer {
            let radius = sqrt(pow(circle._boundBox.width, 2) + pow(circle._boundBox.height, 2))
            let center = NSMakePoint(circle._boundBox.midX, circle._boundBox.midY)
            let anglePoints = circle.arcPoints(lambdas: [startingAngle % 1.0, (startingAngle + (startingAngle >= 0 ? angle : -angle)) % 1.0])
            let realStartingAngle = atan2(anglePoints[0].position.y - center.y, anglePoints[0].position.x - center.x)
            let realAngle = atan2(anglePoints[1].position.y - center.y, anglePoints[1].position.x - center.x)
            let path = CGMutablePath()
            path.move(to: center)
            path.addLine(to: center + NSMakePoint(radius * cos(realStartingAngle), radius * sin(realStartingAngle)))
            path.addArc(center: center, radius: radius, startAngle: realStartingAngle, endAngle: realAngle, clockwise: startingAngle >= 0)
            path.closeSubpath()
            let shape = CAShapeLayer()
            shape.path = path
            return shape
        }
        
        func applyGradient(to path: CGPath, gradient: WatchLayout.Gradient, alpha: CGFloat = 1.0, angle: CGFloat? = nil, startingAngle: CGFloat, outerRing: RoundedRect? = nil) -> CAGradientLayer {
            let gradientLayer = CAGradientLayer()
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint = gradientLayer.startPoint + NSMakePoint(sin(startingAngle * CGFloat.pi * 2), cos(startingAngle * CGFloat.pi * 2))
            gradientLayer.type = .conic
            if startingAngle >= 0 {
                gradientLayer.colors = gradient.colors.map { $0.cgColor }.reversed()
                gradientLayer.locations = gradient.locations.map { NSNumber(value: Double(1-$0)) }.reversed()
            } else {
                gradientLayer.colors = gradient.colors.map { $0.cgColor }
                gradientLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
            }
            gradientLayer.frame = self.bounds
            
            let trackMask = shapeFrom(path: path)
            let mask: CALayer
            if let angle = angle, let outerRing = outerRing {
                let angleMask = angleMask(angle: angle, startingAngle: startingAngle, in: outerRing)
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
        
        func changePhase(phase: CGFloat, angles: [CGFloat]) -> [CGFloat] {
            return angles.map { angle in
                if phase >= 0 {
                    return (angle + phase) % 1.0
                } else {
                    return (-angle + phase) % 1.0
                }
            }
        }
        
        func drawMark(at locations: [CGFloat], on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, colors: [NSColor], radius: CGFloat) -> CALayer {
            let marks = CALayer()
            let points = ring.arcPoints(lambdas: changePhase(phase: startingAngle, angles: locations.filter { 0 <= $0 && 1 > $0} ))
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
        
        func addMarks(position: ChineseCalendar.CelestialEvent, on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, radius: CGFloat) -> CALayer {
            let marks = CALayer()
            marks.addSublayer(drawMark(at: position.eclipse, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.eclipseIndicator], radius: radius))
            marks.addSublayer(drawMark(at: position.fullMoon, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.fullmoonIndicator], radius: radius))
            marks.addSublayer(drawMark(at: position.oddSolarTerm, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.oddStermIndicator], radius: radius))
            marks.addSublayer(drawMark(at: position.evenSolarTerm, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.evenStermIndicator], radius: radius))
            return marks
        }
        
        func addIntradayMarks(positions: ChineseCalendar.DailyEvent, on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, radius: CGFloat) -> CALayer {
            let (sunPositionsInDay, sunPositionsInDayColors) = pairMarkPositionColor(rawPositions: positions.solar, rawColors: watchLayout.sunPositionIndicator)
            let (moonPositionsInDay, moonPositionsInDayColors) = pairMarkPositionColor(rawPositions: positions.lunar, rawColors: watchLayout.moonPositionIndicator)
            let marks = CALayer()
            marks.addSublayer(drawMark(at: sunPositionsInDay, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: sunPositionsInDayColors, radius: radius))
            marks.addSublayer(drawMark(at: moonPositionsInDay, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: moonPositionsInDayColors, radius: radius))
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
        
        func drawRing(ringPath: CGPath, roundedRect: RoundedRect, gradient: WatchLayout.Gradient, ticks: ChineseCalendar.Ticks, startingAngle: CGFloat, fontSize: CGFloat, minorLineWidth: CGFloat, majorLineWidth: CGFloat, drawShadow: Bool) -> CALayer {
            let ringLayer = CALayer()
            let ringShadow = applyGradient(to: ringPath, gradient: gradient, alpha: watchLayout.shadeAlpha, startingAngle: startingAngle)
            ringLayer.addSublayer(ringShadow)
            
            let ringMinorTicksPath = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.minorTicks), width: 0.1 * shortEdge)
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
            
            let ringMajorTicksPath = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTicks), width: 0.15 * shortEdge)
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
            let textLayers = CALayer()
            let shadowLayer = CALayer()
            finishedRingLayer.addSublayer(ringLayerAfterMinor)
            finishedRingLayer.addSublayer(shadowLayer)
            finishedRingLayer.addSublayer(ringMinorTicks)
            finishedRingLayer.addSublayer(ringMajorTicks)
            finishedRingLayer.addSublayer(textLayers)
            
            let textRing = roundedRect.shrink(by: 0.035 * shortEdge)
            let textPoints = textRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTickNames.map { $0.position }))
            let textMaskPath = CGMutablePath()
            let fontColor = isDark ? watchLayout.fontColorDark : watchLayout.fontColor
            for i in 0..<textPoints.count {
                let point = textPoints[i]
                if !ticks.majorTickNames[i].name.isEmpty {
                    let (textLayer, textBoxPath) = drawText(str: ticks.majorTickNames[i].name, at: point.position, angle: point.direction, color: fontColor, size: fontSize)
                    textLayer.opacity = Float(watchLayout.shadeAlpha)
                    textMaskPath.addPath(textBoxPath)
                    textLayers.addSublayer(textLayer)
                }
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
            
            if drawShadow {
                let shadowPath = roundedRect.path
                shadowLayer.shadowPath = shadowPath
                shadowLayer.shadowOffset = NSMakeSize(0.01 * shortEdge, -0.01 * shortEdge)
                shadowLayer.shadowRadius = 0.03 * shortEdge
                shadowLayer.shadowOpacity = 0.2
                let shadowMaskPath = CGMutablePath()
                shadowMaskPath.addPath(shadowPath)
                shadowMaskPath.addPath(CGPath(rect: self.bounds, transform: nil))
                let shadowMask = shapeFrom(path: shadowMaskPath)
                shadowLayer.mask = shadowMask
            }
            
            return finishedRingLayer
        }
        func activeRingAngle(to layer: CALayer, ringPath: CGPath, gradient: WatchLayout.Gradient, angle: CGFloat, startingAngle: CGFloat, outerRing: RoundedRect, ticks: ChineseCalendar.Ticks) {
            let ringActive = applyGradient(to: ringPath, gradient: gradient, angle: angle, startingAngle: startingAngle, outerRing: outerRing)
            if let count = layer.sublayers?[0].sublayers?[0].sublayers?.count, count < 2 {
                layer.sublayers?[0].sublayers?[0].addSublayer(ringActive)
            } else {
                layer.sublayers?[0].sublayers?[0].sublayers?[1] = ringActive
            }
            for i in 0..<ticks.majorTickNames.count {
                if let sublayers = layer.sublayers,
                   let textLayer = sublayers[sublayers.count-1].sublayers?[i] as? CALayer {
                    textLayer.opacity = ticks.majorTickNames[i].active ? 1.0 : Float(watchLayout.shadeAlpha)
                }
            }
        }
        
        func drawOuterRing(path: CGPath, roundedRect: RoundedRect, textRoundedRect: RoundedRect, tickPositions: [CGFloat], texts: [String], startingAngle: CGFloat, fontSize: CGFloat, lineWidth: CGFloat, color: NSColor) -> CALayer {
            let ringPath = roundedRect.path
            ringPath.addPath(path)
            
            let ringShape = shapeFrom(path: ringPath)
            let ringTicks = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: tickPositions), width: 0.05 * shortEdge)
            let ringTicksShape = shapeFrom(path: ringTicks)
            ringTicksShape.mask = ringShape
            ringTicksShape.strokeColor = color.cgColor
            ringTicksShape.lineWidth = lineWidth
            let finishedRingLayer = CALayer()
            finishedRingLayer.addSublayer(ringTicksShape)
            
            var i = 0
            let points = textRoundedRect.arcPoints(lambdas: changePhase(phase: startingAngle, angles: tickPositions))
            for point in points {
                let (textLayer, _) = drawText(str: texts[i], at: point.position, angle: point.direction, color: color, size: fontSize)
                finishedRingLayer.addSublayer(textLayer)
                i += 1
            }
            return finishedRingLayer
        }
        
        func calSubhourGradient() -> WatchLayout.Gradient {
            let startOfDay = chineseCalendar.startOfDay
            let lengthOfDay = startOfDay.distance(to: chineseCalendar.startOfNextDay)
            let fourthRingColor = WatchLayout.Gradient(locations: [0, 1], colors: [
                watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.startHour) / lengthOfDay) % 1.0),
                watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.endHour) / lengthOfDay) % 1.0)
            ], loop: false)
            return fourthRingColor
        }
        
        func pairMarkPositionColor(rawPositions: [CGFloat?], rawColors: [NSColor]) -> ([CGFloat], [NSColor]) {
            var newPositions = [CGFloat]()
            var newColors = [NSColor]()
            for i in 0..<rawPositions.count {
                if let pos = rawPositions[i] {
                    newPositions.append(pos)
                    newColors.append(rawColors[i%rawColors.count])
                }
            }
            return (pos: newPositions, color: newColors)
        }
        
        func drawCenterTextGradient(innerBound: RoundedRect, dateString: String, timeString: String) -> CALayer {
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
            gradientLayer.frame = self.bounds
            gradientLayer.mask = centerText
            
            return gradientLayer as CALayer
        }
        
        func getVagueShapes(shortEdge: CGFloat, longEdge: CGFloat) {
            // Basic paths
            graphicArtifects.outerBound = RoundedRect(rect: dirtyRect, nodePos: cornerSize, ankorPos: cornerSize*0.2).shrink(by: 0.02 * shortEdge)
            graphicArtifects.firstRingOuter = graphicArtifects.outerBound!.shrink(by: 0.047 * shortEdge)
            graphicArtifects.firstRingInner = graphicArtifects.firstRingOuter!.shrink(by: 0.075 * shortEdge)
            
            graphicArtifects.secondRingOuter = graphicArtifects.firstRingOuter!.shrink(by: 0.07546 * shortEdge)
            graphicArtifects.secondRingInner = graphicArtifects.secondRingOuter!.shrink(by: 0.075 * shortEdge)
            
            graphicArtifects.thirdRingOuter = graphicArtifects.secondRingOuter!.shrink(by: 0.07546 * shortEdge)
            graphicArtifects.thirdRingInner = graphicArtifects.thirdRingOuter!.shrink(by: 0.075 * shortEdge)
            
            graphicArtifects.fourthRingOuter = graphicArtifects.thirdRingOuter!.shrink(by: 0.07546 * shortEdge)
            graphicArtifects.fourthRingInner = graphicArtifects.fourthRingOuter!.shrink(by: 0.075 * shortEdge)
            
            graphicArtifects.innerBound = graphicArtifects.fourthRingOuter!.shrink(by: 0.07546 * shortEdge)
            
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
            let shortEdge = min(dirtyRect.width, dirtyRect.height)
            shape.path = RoundedRect(rect: dirtyRect, nodePos: shortEdge * 0.08, ankorPos: shortEdge*0.08*0.2).path
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
            
            graphicArtifects.outerOddLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.zeroRingOuter!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: chineseCalendar.oddSolarTerms, texts: ChineseCalendar.oddSolarTermChinese, startingAngle: phase.zeroRing, fontSize: fontSize, lineWidth: majorLineWidth, color: oddSolarTermTickColor)
            graphicArtifects.outerEvenLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.zeroRingOuter!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: chineseCalendar.evenSolarTerms, texts: ChineseCalendar.evenSolarTermChinese, startingAngle: phase.zeroRing, fontSize: fontSize, lineWidth: majorLineWidth, color: evenSolarTermTickColor)
        }
        self.layer?.addSublayer(graphicArtifects.outerOddLayer!)
        self.layer?.addSublayer(graphicArtifects.outerEvenLayer!)

        chineseCalendar.updateDate()
        // First Ring
        if (graphicArtifects.firstRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.yearUpdatedTime)) >= Self.majorUpdateInterval) || (chineseCalendar.preciseMonth != keyStates.month) {
            let monthTicks = chineseCalendar.monthTicks
            if (graphicArtifects.firstRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) {
                graphicArtifects.firstRingLayer = drawRing(ringPath: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.firstRingOuter!, gradient: watchLayout.firstRing, ticks: monthTicks, startingAngle: phase.firstRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
                keyStates.year = chineseCalendar.year
            }
            graphicArtifects.firstRingMarks = drawMark(at: chineseCalendar.planetPosition, on: graphicArtifects.firstRingOuter!, startingAngle: phase.firstRing, maskPath: graphicArtifects.firstRingOuterPath!, colors: watchLayout.planetIndicator, radius: 0.012 * shortEdge)
            activeRingAngle(to: graphicArtifects.firstRingLayer!, ringPath: graphicArtifects.firstRingOuterPath!, gradient: watchLayout.firstRing, angle: chineseCalendar.currentDayInYear, startingAngle: phase.firstRing, outerRing: graphicArtifects.firstRingOuter!, ticks: monthTicks)
            keyStates.yearUpdatedTime = chineseCalendar.time
        }
        self.layer?.addSublayer(graphicArtifects.firstRingLayer!)
        self.layer?.addSublayer(graphicArtifects.firstRingMarks!)
        
        // Second Ring
        if (graphicArtifects.secondRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.preciseMonth != keyStates.month) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.monthUpdatedTime)) >= Self.minorUpdateInterval) || (chineseCalendar.day != keyStates.day) {
            let dayTicks = chineseCalendar.dayTicks
            if (graphicArtifects.secondRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.preciseMonth != keyStates.month) || (chineseCalendar.timezone != keyStates.timezone) || (ChineseCalendar.globalMonth != keyStates.globalMonth) {
                graphicArtifects.secondRingLayer = drawRing(ringPath: graphicArtifects.secondRingOuterPath!, roundedRect: graphicArtifects.secondRingOuter!, gradient: watchLayout.secondRing, ticks: dayTicks, startingAngle: phase.secondRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
                graphicArtifects.secondRingMarks = addMarks(position: chineseCalendar.eventInMonth, on: graphicArtifects.secondRingOuter!, startingAngle: phase.secondRing, maskPath: graphicArtifects.secondRingOuterPath!, radius: 0.012 * shortEdge)
                keyStates.month = chineseCalendar.preciseMonth
                keyStates.globalMonth = ChineseCalendar.globalMonth
            }
            activeRingAngle(to: graphicArtifects.secondRingLayer!, ringPath: graphicArtifects.secondRingOuterPath!, gradient: watchLayout.secondRing, angle: chineseCalendar.currentDayInMonth, startingAngle: phase.secondRing, outerRing: graphicArtifects.secondRingOuter!, ticks: dayTicks)
            keyStates.monthUpdatedTime = chineseCalendar.time
        }
        self.layer?.addSublayer(graphicArtifects.secondRingLayer!)
        self.layer?.addSublayer(graphicArtifects.secondRingMarks!)
        
        // Third Ring
        let hourTicks = chineseCalendar.hourTicks
        if (graphicArtifects.thirdRingLayer == nil) || (chineseCalendar.dateString != keyStates.dateString) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.timezone != keyStates.timezone) {
            graphicArtifects.thirdRingLayer = drawRing(ringPath: graphicArtifects.thirdRingOuterPath!, roundedRect: graphicArtifects.thirdRingOuter!, gradient: watchLayout.thirdRing, ticks: hourTicks, startingAngle: phase.thirdRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
            graphicArtifects.thirdRingMarks = addMarks(position: chineseCalendar.eventInDay, on: graphicArtifects.thirdRingOuter!, startingAngle: phase.thirdRing, maskPath: graphicArtifects.thirdRingOuterPath!, radius: 0.012 * shortEdge)
            graphicArtifects.thirdRingMarks?.addSublayer(addIntradayMarks(positions: chineseCalendar.sunMoonPositions, on: graphicArtifects.thirdRingInner!, startingAngle: phase.thirdRing, maskPath: graphicArtifects.thirdRingOuterPath!, radius: 0.012 * shortEdge))
            keyStates.day = chineseCalendar.day
            keyStates.dateString = chineseCalendar.dateString
        }
        activeRingAngle(to: graphicArtifects.thirdRingLayer!, ringPath: graphicArtifects.thirdRingOuterPath!, gradient: watchLayout.thirdRing, angle: chineseCalendar.currentHourInDay, startingAngle: phase.thirdRing, outerRing: graphicArtifects.thirdRingOuter!, ticks: hourTicks)
        self.layer?.addSublayer(graphicArtifects.thirdRingLayer!)
        self.layer?.addSublayer(graphicArtifects.thirdRingMarks!)
        
        // Fourth Ring
        let fourthRingColor = calSubhourGradient()
        let subhourTicks = chineseCalendar.subhourTicks
        if (graphicArtifects.fourthRingLayer == nil) || (chineseCalendar.startHour != keyStates.priorHour) || (chineseCalendar.timezone != keyStates.timezone) {
            if (graphicArtifects.fourthRingLayer == nil) || (chineseCalendar.startHour != keyStates.priorHour) {
                graphicArtifects.fourthRingLayer = drawRing(ringPath: graphicArtifects.fourthRingOuterPath!, roundedRect: graphicArtifects.fourthRingOuter!, gradient: fourthRingColor, ticks: subhourTicks, startingAngle: phase.fourthRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
                keyStates.priorHour = chineseCalendar.startHour
            }
            graphicArtifects.fourthRingMarks = addMarks(position: chineseCalendar.eventInHour, on: graphicArtifects.fourthRingOuter!, startingAngle: phase.fourthRing, maskPath: graphicArtifects.fourthRingOuterPath!, radius: 0.012 * shortEdge)
            graphicArtifects.fourthRingMarks?.addSublayer(addIntradayMarks(positions: chineseCalendar.sunMoonSubhourPositions, on: graphicArtifects.fourthRingInner!, startingAngle: phase.fourthRing, maskPath: graphicArtifects.fourthRingOuterPath!, radius: 0.012 * shortEdge))
            keyStates.timezone = chineseCalendar.timezone
        }
        activeRingAngle(to: graphicArtifects.fourthRingLayer!, ringPath: graphicArtifects.fourthRingOuterPath!, gradient: fourthRingColor, angle: chineseCalendar.subhourInHour, startingAngle: phase.fourthRing, outerRing: graphicArtifects.fourthRingOuter!, ticks: subhourTicks)
        self.layer?.addSublayer(graphicArtifects.fourthRingLayer!)
        self.layer?.addSublayer(graphicArtifects.fourthRingMarks!)
        
        // Inner Ring
        if (graphicArtifects.innerBox == nil) {
            graphicArtifects.innerBox = shapeFrom(path: graphicArtifects.innerBoundPath!)
            graphicArtifects.innerBox!.fillColor = isDark ? watchLayout.innerColorDark.cgColor : watchLayout.innerColor.cgColor
            let shadowLayer = CALayer()
            shadowLayer.shadowPath = graphicArtifects.innerBoundPath!
            shadowLayer.shadowOffset = NSMakeSize(0.01 * shortEdge, -0.01 * shortEdge)
            shadowLayer.shadowRadius = 0.03 * shortEdge
            shadowLayer.shadowOpacity = 0.2
            let shadowMaskPath = CGMutablePath()
            shadowMaskPath.addPath(graphicArtifects.innerBoundPath!)
            shadowMaskPath.addPath(CGPath(rect: self.bounds, transform: nil))
            let shadowMask = shapeFrom(path: shadowMaskPath)
            shadowLayer.mask = shadowMask
            graphicArtifects.innerBox?.addSublayer(shadowLayer)
        }
        self.layer?.addSublayer(graphicArtifects.innerBox!)
        
        // Center text
        let timeString = chineseCalendar.timeString
        let dateString = chineseCalendar.dateString
        if (graphicArtifects.centerText == nil) || (dateString != keyStates.dateString) || (timeString != keyStates.timeString) {
            graphicArtifects.centerText = drawCenterTextGradient(innerBound: graphicArtifects.innerBound!, dateString: dateString, timeString: timeString)
            keyStates.timeString = timeString
            updateStatusBar()
        }
        self.layer?.addSublayer(graphicArtifects.centerText!)
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
    let _closingButton: OptionView
    private var _timer: Timer?
    static var currentInstance: WatchFace? = nil
    private static let updateInterval: CGFloat = 14.4
    var buttonSize: NSSize {
        let ratio = 80 * 2.3 / (self._view.watchLayout.watchSize.width / 2)
        return NSMakeSize(80 / ratio, 30 / ratio)
    }
    
    init(position: NSRect) {
        _view = WatchFaceView(frame: position)
        let blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .popover
        blurView.state = .active
        blurView.wantsLayer = true
        _backView = blurView
        _settingButton = OptionView(frame: NSZeroRect)
        _closingButton = OptionView(frame: NSZeroRect)
        super.init(contentRect: position, styleMask: .borderless, backing: .buffered, defer: true)
        
        _settingButton.image = NSImage(systemSymbolName: "square.and.pencil", accessibilityDescription: "Setting")
        _settingButton.button.contentTintColor = .systemGray
        _settingButton.target = self
        _settingButton.action = #selector(self.openSetting(_:))
        _closingButton.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")
        _closingButton.button.contentTintColor = .systemRed
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
        contentView.addSubview(_closingButton)
        self.isMovableByWindowBackground = false
    }
    
    @objc func openSetting(_ sender: Any) {
        if ConfigurationViewController.currentInstance == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let windowController = storyboard.instantiateController(withIdentifier: "WindowController") as! NSWindowController
            if let window = windowController.window {
                let viewController = window.contentViewController as! ConfigurationViewController
                ConfigurationViewController.currentInstance = viewController
                windowController.showWindow(nil)
            }
        }
    }
    @objc func closeApp(_ sender: Any) {
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
        _settingButton.frame = NSMakeRect(bounds.width / 2 - buttonSize.width * 1.15, buttonSize.height / 2, buttonSize.width, buttonSize.height)
        _settingButton.button.font = _settingButton.button.font?.withSize(buttonSize.height / 2)
        _closingButton.frame = NSMakeRect(bounds.width / 2 + buttonSize.width * 0.15, buttonSize.height / 2, buttonSize.width, buttonSize.height)
        _closingButton.button.font = _closingButton.button.font?.withSize(buttonSize.height / 2)
        _view.cornerSize = _view.watchLayout.cornerRadiusRatio * min(watchDimension.width, watchDimension.height)
        _view.graphicArtifects = WatchFaceView.GraphicArtifects()
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
