//
//  WatchFace.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/4/23.
//

import Foundation
import SwiftUI

class WatchLayout: MetaWatchLayout {
    var textFont: UIFont
    var centerFont: UIFont
    
    override init() {
        textFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        centerFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .black)
        super.init()
    }
}

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
    
    var outerOddLayer: AnyView?
    var outerEvenLayer: AnyView?
    var firstRingLayer = WatchRing()
    var secondRingLayer = WatchRing()
    var thirdRingLayer = WatchRing()
    var fourthRingLayer = WatchRing()
    var innerBox = WatchRing()
    
    var compositeView: some View {
        let outerLayer = ZStack {
            outerOddLayer
            outerEvenLayer
        }
        return ZStack {
            outerLayer
            firstRingLayer.body
            secondRingLayer.body
            thirdRingLayer.body
            fourthRingLayer.body
            innerBox.body
        }
    }
}

class DynamicStack {
    var views = [(Int, AnyView)]()
    var body: some View {
        ZStack {
            ForEach(views, id: \.0) { item in
                item.1
            }
        }
    }
    func append(view: some View) {
        views.append((views.count, AnyView(view)))
    }
}

class KeyStates {
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
    var location: CGPoint? = nil
}

struct StartingPhase {
    var zeroRing: CGFloat = 0.0
    var firstRing: CGFloat = 0.0
    var secondRing: CGFloat = 0.0
    var thirdRing: CGFloat = 0.0
    var fourthRing: CGFloat = 0.0
}

class WatchRing {
    var baseRing: AnyView?
    var activeRing: AnyView?
    var masks:[AnyView] = []
    var addons: AnyView?
    var marks: AnyView?
    var shortEdge: CGFloat = 0
    
    var body: some View {
        var base = AnyView(ZStack {
            self.baseRing
            self.activeRing
        })
        for mask in self.masks {
            base = AnyView(base.mask { mask })
        }
        return ZStack {
            base
                .shadow(color: Color(white: 0, opacity: 0.5),radius: 0.03 * shortEdge, x: 0.01 * shortEdge, y: -0.01 * shortEdge)
            addons
            marks
        }
    }
}

class WatchFace : ObservableObject {
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval / 12
    static let updateInterval: CGFloat = 14.4
    static let frameOffset: CGFloat = 0
    static var currentInstance: WatchFace?
    static var layoutTemplate: String?

    let watchLayout: WatchLayout
    var displayTime: Date? = nil
    @Published var time = Date()
    var timezone: TimeZone = Calendar.current.timeZone
    var realLocation: CGPoint? = nil
    var phase: StartingPhase = StartingPhase(zeroRing: 0, firstRing: 0, secondRing: 0, thirdRing: 0, fourthRing: 0)
    var screenFrame: CGRect
    var compact: Bool
    
    var location: CGPoint? {
        realLocation ?? watchLayout.location
    }

    lazy private var chineseCalendar = ChineseCalendar(time: displayTime ?? Date(), timezone: timezone, location: location, compact: compact)
    var graphicArtifects = GraphicArtifects()
    private var keyStates = KeyStates()
    
    init(frame: CGRect, compact: Bool = false) {
        self.screenFrame = frame
        if let template = Self.layoutTemplate {
            self.watchLayout = WatchLayout(from: template)
        } else {
            self.watchLayout = WatchLayout()
        }
        self.compact = compact
        WatchFace.currentInstance = self
    }
    
    deinit {
        WatchFace.currentInstance = nil
    }
    
    func update(forceRefresh: Bool) {
        if forceRefresh {
            graphicArtifects = GraphicArtifects()
        }
        DispatchQueue.main.async {
            let newTime = self.displayTime ?? Date()
            if forceRefresh || !self.chineseCalendar.update(time: newTime, timezone: self.timezone, location: self.location) {
                self.chineseCalendar = ChineseCalendar(time: newTime, timezone: self.timezone, location: self.location, compact: self.compact)
            }
            self.time = newTime
        }
    }
    
    func update() {
        
        func applyGradient(to path: CGPath, gradient: WatchLayout.Gradient, alpha: CGFloat = 1.0, angle: CGFloat? = nil, startingAngle: CGFloat, outerRing: RoundedRect? = nil) -> AnyView {

            let colors: [CGColor]
            let locations: [CGFloat]
            if startingAngle >= 0 {
                colors = gradient.colors.reversed()
                locations = gradient.locations.map { 1-$0 }.reversed()
            } else {
                colors = gradient.colors
                locations = gradient.locations
            }
            let gradientLayer = AngularGradient(gradient: Gradient(stops: zip(colors, locations).map { Gradient.Stop(color: Color(cgColor: $0.0), location: $0.1) }), center: .center, angle: Angle(degrees: 90))
            let track = Path(path)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            
            let angleMask: any View
            if let angle = angle, let outerRing = outerRing {
                let anglePath = anglePath(angle: angle, startingAngle: startingAngle, in: outerRing)
                angleMask = Path(anglePath)
                    .fill()
                    .foregroundColor(Color(white: 1, opacity: alpha))
            } else {
                angleMask = Path(path)
                    .fill()
                    .foregroundColor(Color(white: 1, opacity: alpha))
            }
            return AnyView(gradientLayer.mask { track }.mask { AnyView(angleMask) })
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
        
        func drawMark(at locations: [CGFloat], on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, colors: [CGColor], radius: CGFloat) -> AnyView {
            let points = ring.arcPoints(lambdas: changePhase(phase: startingAngle, angles: locations.filter { 0 <= $0 && 1 > $0} ))
            let marks = DynamicStack()
            for i in 0..<locations.count {
                let point = points[i]
                let pos = point.position
                let angle = point.direction
                var transform = CGAffineTransform(translationX: -pos.x, y: -pos.y)
                transform = transform.concatenating(CGAffineTransform(rotationAngle: -angle))
                transform = transform.concatenating(CGAffineTransform(translationX: pos.x, y: pos.y))
                let markPath: CGPath = RoundedRect(rect: CGRect(x: pos.x - radius, y: pos.y - radius, width: 2 * radius, height: 2 * radius), nodePos: 0.7 * radius, ankorPos: 0.3 * radius).path
                let mark = Path(markPath)
                    .fill()
                    .foregroundColor(Color(cgColor: colors[i % colors.count]))
                    .shadow(color: Color(white: 0, opacity: 0.5 * colors[i % colors.count].alpha),radius: radius / 2, x: 0, y: 0)
                    .transformEffect(transform)
                marks.append(view: mark)
            }

            let mask = Path(maskPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            return AnyView(marks.body.mask { mask })
        }
        
        func addMarks(position: ChineseCalendar.CelestialEvent, on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, radius: CGFloat) -> AnyView {
            let marks = ZStack {
                drawMark(at: position.eclipse, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.eclipseIndicator], radius: radius)
                drawMark(at: position.fullMoon, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.fullmoonIndicator], radius: radius)
                drawMark(at: position.oddSolarTerm, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.oddStermIndicator], radius: radius)
                drawMark(at: position.evenSolarTerm, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.evenStermIndicator], radius: radius)
            }
            return AnyView(marks)
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
        
        func pairMarkPositionColor(rawPositions: [CGFloat?], rawColors: [CGColor]) -> ([CGFloat], [CGColor]) {
            var newPositions = [CGFloat]()
            var newColors = [CGColor]()
            for i in 0..<rawPositions.count {
                if let pos = rawPositions[i] {
                    newPositions.append(pos)
                    newColors.append(rawColors[i%rawColors.count])
                }
            }
            return (pos: newPositions, color: newColors)
        }
        
        func addIntradayMarks(positions: ChineseCalendar.DailyEvent, on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, radius: CGFloat) -> AnyView {
            let (sunPositionsInDay, sunPositionsInDayColors) = pairMarkPositionColor(rawPositions: positions.solar, rawColors: watchLayout.sunPositionIndicator)
            let (moonPositionsInDay, moonPositionsInDayColors) = pairMarkPositionColor(rawPositions: positions.lunar, rawColors: watchLayout.moonPositionIndicator)
            let marks = ZStack {
                drawMark(at: sunPositionsInDay, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: sunPositionsInDayColors, radius: radius)
                drawMark(at: moonPositionsInDay, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: moonPositionsInDayColors, radius: radius)
            }
            return AnyView(marks)
        }
        
        func drawText(str: String, at: CGPoint, angle: CGFloat, color: CGColor, size: CGFloat) -> (some View, CGPath) {
            let string: String
            var hasSpace = false
            if compact {
                hasSpace = str.firstIndex(of: "　") != nil
                string = String(str.replacingOccurrences(of: "　", with: ""))
            } else {
                string = str
            }
            let font = watchLayout.textFont.withSize(size)
            let attrStr = NSMutableAttributedString(string: string)
            attrStr.addAttributes([.font: font,.foregroundColor: color], range: NSMakeRange(0, string.utf16.count))
            
            let characters = string.map{NSMutableAttributedString(string: String($0), attributes: attrStr.attributes(at: 0, effectiveRange: nil))}
            let textLayers = DynamicStack()
            let mean = CGFloat(characters.count - 1) / 2
            
            if (angle > CGFloat.pi / 4 && angle < CGFloat.pi * 3/4) || (angle > CGFloat.pi * 5/4 && angle < CGFloat.pi * 7/4) {
                for i in 0..<characters.count {
                    let yPosition = (CGFloat(i) - mean) * size * (hasSpace ? 1.5 : 0.95)
                    textLayers.append(view: Text(AttributedString(characters[i]))
                        .foregroundColor(Color(cgColor: color))
                        .position(x: at.x, y: at.y + yPosition))
                }
            } else {
                for i in 0..<characters.count {
                    let xPosition = (CGFloat(i) - mean) * size * (hasSpace ? 1.5 : 0.95)
                    textLayers.append(view: Text(AttributedString(characters[i]))
                        .foregroundColor(Color(cgColor: color))
                        .position(x: at.x - xPosition, y: at.y))
                }
            }
            let textLayer = AnyView(textLayers.body)
            var box = attrStr.boundingRect(with: CGSizeZero, options: .usesLineFragmentOrigin, context: .none)
            box.origin = CGPoint(x: at.x - box.width/2, y: at.y - box.height/2)
            var boxTransform = CGAffineTransform(translationX: -at.x, y: -at.y)
            let transform: CGAffineTransform
            if angle <= CGFloat.pi / 4 {
                transform = CGAffineTransform(rotationAngle: -angle)
            } else if angle < CGFloat.pi * 3/4 {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi/2-angle)
            } else if angle < CGFloat.pi * 5/4 {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi-angle)
            } else if angle < CGFloat.pi * 7/4 {
                transform = CGAffineTransform(rotationAngle: -angle-CGFloat.pi/2)
            } else {
                transform = CGAffineTransform(rotationAngle: -angle)
            }
            boxTransform = boxTransform.concatenating(transform)
            boxTransform = boxTransform.concatenating(CGAffineTransform(translationX: at.x, y: at.y))
            let transformedText = textLayer.transformEffect(boxTransform)
            let cornerSize = 0.2 * min(box.height, box.width)
            let path = CGPath(roundedRect: box, cornerWidth: cornerSize, cornerHeight: cornerSize, transform: &boxTransform)
            return (transformedText, path)
        }
        
        func drawRing(ring: WatchRing, ringPath: CGPath, roundedRect: RoundedRect, gradient: WatchLayout.Gradient, ticks: ChineseCalendar.Ticks, startingAngle: CGFloat, fontSize: CGFloat, minorLineWidth: CGFloat, majorLineWidth: CGFloat) {

            ring.baseRing = applyGradient(to: ringPath, gradient: gradient, alpha: watchLayout.shadeAlpha, startingAngle: startingAngle)
            
            let ringMinorTicksPath = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.minorTicks), width: 0.1 * shortEdge)
            let ringMinorTicks = Path(ringMinorTicksPath)
                .stroke(style: StrokeStyle(lineWidth: minorLineWidth))
                .foregroundColor(Color(cgColor: self.watchLayout.minorTickColorDark))
            
            let ringMinorTrackOuter = roundedRect.shrink(by: 0.01 * shortEdge)
            let ringMinorTrackInner = roundedRect.shrink(by: 0.06 * shortEdge)
            let ringMinorTrackPath = ringMinorTrackOuter.path
            ringMinorTrackPath.addPath(ringMinorTrackInner.path)
            
            let ringMinorTicksMaskPath = CGMutablePath()
            ringMinorTicksMaskPath.addPath(ringPath)
            ringMinorTicksMaskPath.addPath(ringMinorTicksPath.copy(strokingWithWidth: minorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            let ringMinorTicksMask = Path(ringMinorTicksMaskPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            
            let ringCrustPath = CGMutablePath()
            ringCrustPath.addPath(ringMinorTrackPath)
            ringCrustPath.addPath(ringPath)
            let ringCrust = Path(ringCrustPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            let ringBase = Path(ringPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color(cgColor: CGColor(gray: 1.0, alpha: self.watchLayout.minorTickAlpha)))
            
            let ringMajorTicksPath = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTicks), width: 0.15 * shortEdge)
            let ringMajorTicks = Path(ringMajorTicksPath)
                .stroke(style: StrokeStyle(lineWidth: majorLineWidth))
                .foregroundColor(Color(cgColor: self.watchLayout.majorTickColorDark))
            
            let ringMajorTicksMaskPath = CGMutablePath()
            ringMajorTicksMaskPath.addPath(ringPath)
            ringMajorTicksMaskPath.addPath(ringMajorTicksPath.copy(strokingWithWidth: majorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            let ringMajorTicksMask = Path(ringMajorTicksMaskPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            let ringBase2 = Path(ringPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color(cgColor: CGColor(gray: 1.0, alpha: self.watchLayout.majorTickAlpha)))
            
            let textRing = roundedRect.shrink(by: 0.035 * shortEdge)
            let textPoints = textRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTickNames.map { $0.position }))
            let textMaskPath = CGMutablePath()
            let fontColor = watchLayout.fontColorDark
            
            for i in 0..<textPoints.count {
                let point = textPoints[i]
                if !ticks.majorTickNames[i].name.isEmpty {
                    let (_, textBoxPath) = drawText(str: ticks.majorTickNames[i].name, at: point.position, angle: point.direction, color: fontColor, size: fontSize)
                    textMaskPath.addPath(textBoxPath)
                }
            }
            
            ringMinorTrackPath.addPath(textMaskPath)
            let ringMinorTrackMask = Path(ringMinorTrackPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            let maskedRingMinorTicks = ringMinorTicks.mask { ringMinorTrackMask }
            
            let ringPathCopy = CGMutablePath()
            ringPathCopy.addPath(ringPath)
            ringPathCopy.addPath(textMaskPath)
            let ringMajorTrackMask = Path(ringPathCopy)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            let maskedRingMajorTicks = ringMajorTicks.mask { ringMajorTrackMask }
            
            let textMask = Path(textMaskPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            
            let ringMinorTicksMaskComposite = AnyView(ZStack {
                ringMinorTicksMask
                ringCrust
                ringBase
                textMask
            })
            
            let ringMajorTicksMaskComposite = AnyView(ZStack {
                ringMajorTicksMask
                ringBase2
                textMask
            })
            
            ring.addons = AnyView(ZStack {
                maskedRingMinorTicks
                maskedRingMajorTicks
            })

            ring.masks = [ringMinorTicksMaskComposite, ringMajorTicksMaskComposite]
            ring.shortEdge = shortEdge
            
        }
        
        func activeRing(ring: WatchRing, ringPath: CGPath, roundedRect: RoundedRect, gradient: WatchLayout.Gradient, ticks: ChineseCalendar.Ticks, startingAngle: CGFloat, angle: CGFloat, fontSize: CGFloat) {
            
            let textRing = roundedRect.shrink(by: 0.035 * shortEdge)
            let textPoints = textRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTickNames.map { $0.position }))
            let textMaskPath = CGMutablePath()
            let fontColor = watchLayout.fontColorDark
            
            let textLayers = DynamicStack()
            for i in 0..<textPoints.count {
                let point = textPoints[i]
                if !ticks.majorTickNames[i].name.isEmpty {
                    let (textLayer, textBoxPath) = drawText(str: ticks.majorTickNames[i].name, at: point.position, angle: point.direction, color: fontColor, size: fontSize)
                    textMaskPath.addPath(textBoxPath)
                    let opacity: CGFloat = ticks.majorTickNames[i].active ? 1.0 : watchLayout.shadeAlpha
                    textLayers.append(view: textLayer.opacity(opacity))
                }
            }
            
            ring.activeRing = AnyView(ZStack {
                applyGradient(to: ringPath, gradient: gradient, angle: angle, startingAngle: startingAngle, outerRing: roundedRect)
                textLayers.body
            })
        }
        
        func drawOuterRing(path: CGPath, roundedRect: RoundedRect, textRoundedRect: RoundedRect, tickPositions: [CGFloat], texts: [String], startingAngle: CGFloat, fontSize: CGFloat, lineWidth: CGFloat, color: CGColor) -> AnyView {
            let ringPath = roundedRect.path
            ringPath.addPath(path)
            let ringShape = Path(ringPath)
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.white)
            
            let ringTicks = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: tickPositions), width: 0.05 * shortEdge)
            let ringTicksShape = Path(ringTicks)
                .stroke(style: StrokeStyle(lineWidth: lineWidth))
                .foregroundColor(Color(cgColor: color))
                .mask { ringShape }
            
            let textLayers = DynamicStack()
            
            var i = 0
            let points = textRoundedRect.arcPoints(lambdas: changePhase(phase: startingAngle, angles: tickPositions))
            for point in points {
                let (textLayer, _) = drawText(str: texts[i], at: point.position, angle: point.direction, color: color, size: fontSize)
                textLayers.append(view: textLayer)
                i += 1
            }
            
            let finishedRingLayer = ZStack {
                ringTicksShape
                textLayers.body
            }
            
            return AnyView(finishedRingLayer)
        }
        
        func drawCenterText(str: String, bound: CGRect, offset: CGFloat, size: CGFloat, rotate: Bool) -> AnyView {
            var center = CGPoint(x: bound.midX, y: bound.midY)
            let font = watchLayout.centerFont.withSize(size)

            var attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttributes([.font: font, .foregroundColor: CGColor(gray: 1, alpha: 1)], range: NSMakeRange(0, str.utf16.count))
            let view: AnyView
            if rotate {
                center.x += offset
                let verticalString = str.map{NSMutableAttributedString(string: String($0), attributes: attrStr.attributes(at: 0, effectiveRange: nil))}
                let verticalText = DynamicStack()
                for i in 0..<verticalString.count {
                    let mean = CGFloat(verticalString.count - 1) / 2
                    let yPosition = center.y + (CGFloat(i) - mean) * size * 0.95
                    verticalText.append(view: Text(AttributedString(verticalString[i]))
                        .position(x: center.x, y: yPosition))
                }
                view = AnyView(verticalText.body)
            } else {
                attrStr = NSMutableAttributedString(string: String(str.reversed()), attributes: attrStr.attributes(at: 0, effectiveRange: nil))
                center.y += offset
                view = AnyView(Text(AttributedString(attrStr))
                    .lineSpacing(-10)
                    .position(center))
            }
            
            return view
        }
        
        func drawCenterTextGradient(innerBound: RoundedRect, dateString: String, timeString: String) -> AnyView {

            let centerTextShortSize = min(innerBound._boundBox.width, innerBound._boundBox.height) * 0.31
            let centerTextLongSize = max(innerBound._boundBox.width, innerBound._boundBox.height) * 0.17
            let centerTextSize = min(centerTextShortSize, centerTextLongSize) * (compact ? 1.1 : 1.0)
            let isVertical = innerBound._boundBox.height >= innerBound._boundBox.width
            
            let centerText = ZStack {
                drawCenterText(str: timeString, bound: innerBound._boundBox, offset: centerTextSize * (-0.7 + watchLayout.centerTextOffset), size: centerTextSize, rotate: isVertical)
                drawCenterText(str: dateString, bound: innerBound._boundBox, offset: centerTextSize * (0.7 + watchLayout.centerTextOffset), size: centerTextSize, rotate: isVertical)
            }
            
            
            let colors = watchLayout.centerFontColor.colors
            let locations = watchLayout.centerFontColor.locations
            let gradientLayer = LinearGradient(stops: zip(colors, locations).map { Gradient.Stop(color: Color(cgColor: $0.0), location: $0.1) }, startPoint: .init(x: -0.3, y: 0.3), endPoint: .init(x: 0.3, y: -0.3))
            
            return AnyView(gradientLayer.mask { centerText })
        }
        
        func getVagueShapes(shortEdge: CGFloat, longEdge: CGFloat) {
            let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
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
        }

        let dirtyRect = screenFrame
        let shortEdge = min(dirtyRect.width, dirtyRect.height)
        let longEdge = max(dirtyRect.width, dirtyRect.height)
        let fontSize: CGFloat = min(shortEdge * 0.03, longEdge * 0.025) * (compact ? 1.5 : 1.0)
        let minorLineWidth = shortEdge / 500
        let majorLineWidth = shortEdge / 300
        
        if graphicArtifects.outerBound == nil {
            getVagueShapes(shortEdge: shortEdge, longEdge: longEdge)
        }
        
        // Zero ring
        if (graphicArtifects.zeroRingOuter == nil) || (chineseCalendar.year != keyStates.year) {
            graphicArtifects.zeroRingOuter = graphicArtifects.outerBound!.shrink(by: 0.01 * shortEdge)
            graphicArtifects.solarTermsRing = graphicArtifects.zeroRingOuter!.shrink(by: 0.02 * shortEdge)
            let oddSolarTermTickColor = watchLayout.oddSolarTermTickColorDark
            let evenSolarTermTickColor = watchLayout.evenSolarTermTickColorDark
            
            graphicArtifects.outerOddLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.zeroRingOuter!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: chineseCalendar.oddSolarTerms, texts: ChineseCalendar.oddSolarTermChinese, startingAngle: phase.zeroRing, fontSize: fontSize, lineWidth: majorLineWidth, color: oddSolarTermTickColor)
            graphicArtifects.outerEvenLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.zeroRingOuter!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: chineseCalendar.evenSolarTerms, texts: ChineseCalendar.evenSolarTermChinese, startingAngle: phase.zeroRing, fontSize: fontSize, lineWidth: majorLineWidth, color: evenSolarTermTickColor)
        }
        
        chineseCalendar.updateDate()
        // First Ring
        if (graphicArtifects.firstRingLayer.baseRing == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.yearUpdatedTime)) >= Self.majorUpdateInterval) || (chineseCalendar.preciseMonth != keyStates.month) {
            let monthTicks = chineseCalendar.monthTicks
            if (graphicArtifects.firstRingLayer.baseRing == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) {
                drawRing(ring: graphicArtifects.firstRingLayer, ringPath: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.firstRingOuter!, gradient: watchLayout.firstRing, ticks: monthTicks, startingAngle: phase.firstRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
                keyStates.year = chineseCalendar.year
            }
            activeRing(ring: graphicArtifects.firstRingLayer, ringPath: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.firstRingOuter!, gradient: watchLayout.firstRing, ticks: monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, fontSize: fontSize)
            graphicArtifects.firstRingLayer.marks = drawMark(at: chineseCalendar.planetPosition, on: graphicArtifects.firstRingOuter!, startingAngle: phase.firstRing, maskPath: graphicArtifects.firstRingOuterPath!, colors: watchLayout.planetIndicator, radius: 0.012 * shortEdge)
            keyStates.yearUpdatedTime = chineseCalendar.time
        }
        
        // Second Ring
        if (graphicArtifects.secondRingLayer.baseRing == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.preciseMonth != keyStates.month) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.monthUpdatedTime)) >= Self.minorUpdateInterval) || (chineseCalendar.day != keyStates.day) {
            let dayTicks = chineseCalendar.dayTicks
            if (graphicArtifects.secondRingLayer.baseRing == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.preciseMonth != keyStates.month) || (chineseCalendar.timezone != keyStates.timezone) || (ChineseCalendar.globalMonth != keyStates.globalMonth) {
                drawRing(ring: graphicArtifects.secondRingLayer, ringPath: graphicArtifects.secondRingOuterPath!, roundedRect: graphicArtifects.secondRingOuter!, gradient: watchLayout.secondRing, ticks: dayTicks, startingAngle: phase.secondRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
                graphicArtifects.secondRingLayer.marks = addMarks(position: chineseCalendar.eventInMonth, on: graphicArtifects.secondRingOuter!, startingAngle: phase.secondRing, maskPath: graphicArtifects.secondRingOuterPath!, radius: 0.012 * shortEdge)
                keyStates.month = chineseCalendar.preciseMonth
                keyStates.globalMonth = ChineseCalendar.globalMonth
            }
            activeRing(ring: graphicArtifects.secondRingLayer, ringPath: graphicArtifects.secondRingOuterPath!, roundedRect: graphicArtifects.secondRingOuter!, gradient: watchLayout.secondRing, ticks: dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, fontSize: fontSize)
            keyStates.monthUpdatedTime = chineseCalendar.time
        }
        
        // Third Ring
        let hourTicks = chineseCalendar.hourTicks
        if (graphicArtifects.thirdRingLayer.baseRing == nil) || (chineseCalendar.dateString != keyStates.dateString) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.timezone != keyStates.timezone || chineseCalendar.location != keyStates.location) {
            drawRing(ring: graphicArtifects.thirdRingLayer, ringPath: graphicArtifects.thirdRingOuterPath!, roundedRect: graphicArtifects.thirdRingOuter!, gradient: watchLayout.thirdRing, ticks: hourTicks, startingAngle: phase.thirdRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
            graphicArtifects.thirdRingLayer.marks  = AnyView(ZStack {
                addMarks(position: chineseCalendar.eventInDay, on: graphicArtifects.thirdRingOuter!, startingAngle: phase.thirdRing, maskPath: graphicArtifects.thirdRingOuterPath!, radius: 0.012 * shortEdge)
                addIntradayMarks(positions: chineseCalendar.sunMoonPositions, on: graphicArtifects.thirdRingInner!, startingAngle: phase.thirdRing, maskPath: graphicArtifects.thirdRingOuterPath!, radius: 0.012 * shortEdge)
            })
            keyStates.day = chineseCalendar.day
            keyStates.dateString = chineseCalendar.dateString
        }
        activeRing(ring: graphicArtifects.thirdRingLayer, ringPath: graphicArtifects.thirdRingOuterPath!, roundedRect: graphicArtifects.thirdRingOuter!, gradient: watchLayout.thirdRing, ticks: hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, fontSize: fontSize)
        
        // Fourth Ring
        let fourthRingColor = calSubhourGradient()
        let subhourTicks = chineseCalendar.subhourTicks
        if (graphicArtifects.fourthRingLayer.baseRing == nil) || (chineseCalendar.startHour != keyStates.priorHour) || (chineseCalendar.timezone != keyStates.timezone || chineseCalendar.location != keyStates.location) {
            if (graphicArtifects.fourthRingLayer.baseRing == nil) || (chineseCalendar.startHour != keyStates.priorHour) {
                drawRing(ring: graphicArtifects.fourthRingLayer, ringPath: graphicArtifects.fourthRingOuterPath!, roundedRect: graphicArtifects.fourthRingOuter!, gradient: fourthRingColor, ticks: subhourTicks, startingAngle: phase.fourthRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth)
                keyStates.priorHour = chineseCalendar.startHour
            }
            graphicArtifects.fourthRingLayer.marks = AnyView(ZStack {
                addMarks(position: chineseCalendar.eventInHour, on: graphicArtifects.fourthRingOuter!, startingAngle: phase.fourthRing, maskPath: graphicArtifects.fourthRingOuterPath!, radius: 0.012 * shortEdge)
                addIntradayMarks(positions: chineseCalendar.sunMoonSubhourPositions, on: graphicArtifects.fourthRingInner!, startingAngle: phase.fourthRing, maskPath: graphicArtifects.fourthRingOuterPath!, radius: 0.012 * shortEdge)
            })
            keyStates.timezone = chineseCalendar.timezone
            keyStates.location = chineseCalendar.location
        }
        activeRing(ring: graphicArtifects.fourthRingLayer, ringPath: graphicArtifects.fourthRingOuterPath!, roundedRect: graphicArtifects.fourthRingOuter!, gradient: fourthRingColor, ticks: subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, fontSize: fontSize)
        
        // Inner Ring
        if (graphicArtifects.innerBox.baseRing == nil) {
            let innerBox = Path(self.graphicArtifects.innerBoundPath!)
                .fill()
                .foregroundColor(Color(cgColor: self.watchLayout.innerColorDark))
            graphicArtifects.innerBox.baseRing = AnyView(innerBox)
            graphicArtifects.innerBox.shortEdge = shortEdge
        }
        
        // Center text
        let timeString = chineseCalendar.timeString
        let dateString = chineseCalendar.dateString
        if (graphicArtifects.innerBox.addons == nil) || (dateString != keyStates.dateString) || (timeString != keyStates.timeString) {
            graphicArtifects.innerBox.addons = drawCenterTextGradient(innerBound: graphicArtifects.innerBound!, dateString: dateString, timeString: timeString)
            keyStates.timeString = timeString
        }
    }
    
    var body: some View {
        graphicArtifects.compositeView
    }
}
