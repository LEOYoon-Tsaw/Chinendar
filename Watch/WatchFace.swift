//
//  WatchFace.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/4/23.
//

import Foundation
import SwiftUI

class WatchLayout: MetaWatchLayout, ObservableObject {
    static var shared: WatchLayout = WatchLayout()
    
    var textFont: UIFont
    var centerFont: UIFont
    @Published var refresh = false
    
    override init() {
        textFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        centerFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .black)
        super.init()
    }
    
    override func update(from str: String) {
        super.update(from: str)
        refresh.toggle()
    }
    
}

struct StartingPhase {
    var zeroRing: CGFloat = 0.0
    var firstRing: CGFloat = 0.0
    var secondRing: CGFloat = 0.0
    var thirdRing: CGFloat = 0.0
    var fourthRing: CGFloat = 0.0
}

struct ZeroRing: View {
    static let width: CGFloat = 0.037
    let viewSize: CGSize
    let compact: Bool
    let textFont: UIFont
    let outerRing: RoundedRect
    let startingAngle: CGFloat
    let oddTicks: [CGFloat]
    let evenTicks: [CGFloat]
    let oddColor: CGColor
    let evenColor: CGColor
    let oddTexts: [String]
    let evenTexts: [String]
    
    var body: some View {
        let shortEdge = min(self.viewSize.width, self.viewSize.height)
        let longEdge = max(self.viewSize.width, self.viewSize.height)
        let fontSize: CGFloat = min(shortEdge * 0.03, longEdge * 0.025) * (compact ? 1.5 : 1.0)
        let majorLineWidth = shortEdge / 300
        
        Canvas { context, size in
            
            let textRing = outerRing.shrink(by: (ZeroRing.width + 0.003) / 2 * shortEdge)
            let innerBound = outerRing.shrink(by: ZeroRing.width * shortEdge)
            let ringBoundPath = outerRing.path
            ringBoundPath.addPath(innerBound.path)
            
            context.clip(to: Path(ringBoundPath), style: FillStyle(eoFill: true))
            let oddTicksPath = outerRing.arcPosition(lambdas: changePhase(phase: startingAngle, angles: oddTicks), width: 0.05 * shortEdge)
            context.stroke(Path(oddTicksPath), with: .color(Color(cgColor: oddColor)), style: StrokeStyle(lineWidth: majorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            let evenTicksPath = outerRing.arcPosition(lambdas: changePhase(phase: startingAngle, angles: evenTicks), width: 0.05 * shortEdge)
            context.stroke(Path(evenTicksPath), with: .color(Color(cgColor: evenColor)), style: StrokeStyle(lineWidth: majorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            
            let font = textFont.withSize(fontSize)
            var drawableTexts = [DrawableText]()
            
            let oddPoints = textRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: oddTicks))
            for i in 0..<oddTexts.count {
                let tickName = oddTexts[i]
                let position = oddPoints[i]
                let texts = prepareText(tickName: tickName, at: position, font: font, compact: compact, color: oddColor)
                drawableTexts += texts
            }
            let evenPoints = textRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: evenTicks))
            for i in 0..<evenTexts.count {
                let tickName = evenTexts[i]
                let position = evenPoints[i]
                let texts = prepareText(tickName: tickName, at: position, font: font, compact: compact, color: evenColor)
                drawableTexts += texts
            }
            
            var transform = CGAffineTransform()
            var textContext = context
            for drawabeText in drawableTexts {
                if drawabeText.transform != transform {
                    textContext = context
                    textContext.concatenate(drawabeText.transform)
                }
                textContext.draw(Text(drawabeText.string).foregroundColor(Color(cgColor: drawabeText.color)), in: drawabeText.position)
                transform = drawabeText.transform
            }
        }
    }
}

struct Ring: View {
    static let width: CGFloat = 0.075
    static let paddedWidth: CGFloat = 0.07546
    let viewSize: CGSize
    let compact: Bool
    let cornerSize: CGFloat
    let ticks: ChineseCalendar.Ticks
    let startingAngle: CGFloat
    let angle: CGFloat
    let textFont: UIFont
    let textColor: CGColor
    let alpha: CGFloat
    let majorTickAlpha: CGFloat
    let minorTickAlpha: CGFloat
    let gradientColor: WatchLayout.Gradient
    let outerRing: RoundedRect
    let marks: [Marks]
    let shadowDirection: CGFloat
    
    var body: some View {
        let shortEdge = min(self.viewSize.width, self.viewSize.height)
        let longEdge = max(self.viewSize.width, self.viewSize.height)
        let fontSize: CGFloat = min(shortEdge * 0.03, longEdge * 0.025) * (compact ? 1.5 : 1.0)
        let minorLineWidth = shortEdge / 500
        let majorLineWidth = shortEdge / 300

        Canvas { graphicsContext, size in
            
            let innerRing = outerRing.shrink(by: Ring.width * shortEdge)
            let outerRingPath = outerRing.path
            outerRingPath.addPath(innerRing.path)
            
            var context = graphicsContext
            context.clip(to: Path(outerRingPath), style: FillStyle(eoFill: true))

            let majorTicksPath = outerRing.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTicks.map{CGFloat($0)}), width: 0.15 * shortEdge)
            let minorTicksPath = outerRing.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.minorTicks.map{CGFloat($0)}), width: 0.15 * shortEdge)
            
            let minorTrackOuter = outerRing.shrink(by: 0.01 * shortEdge)
            let minorTrackInner = outerRing.shrink(by: (Ring.width - 0.015) * shortEdge)
            let minorTrackPath = minorTrackOuter.path
            minorTrackPath.addPath(minorTrackInner.path)
            
            let font = textFont.withSize(fontSize)
            let textRing = outerRing.shrink(by: (Ring.width - 0.005) / 2 * shortEdge)
            let tickPositions = textRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTickNames.map { CGFloat($0.position) }))
            var drawableTexts = [DrawableText]()
            let textMaskPath = CGMutablePath()
            for i in 0..<ticks.majorTickNames.count {
                let tickName = ticks.majorTickNames[i]
                let position = tickPositions[i]
                let textAlpha = textColor.alpha
                let color = textColor.copy(alpha: tickName.active ? textAlpha : (textAlpha * alpha))!
                let texts = prepareText(tickName: tickName.name, at: position, font: font, compact: compact, color: color)
                drawableTexts += texts
                for text in drawableTexts {
                    textMaskPath.addPath(text.boundingBox)
                }
            }
            
            var gradientContext = context
            gradientContext.clipToLayer(options: .inverse) { ctx in
                ctx.addFilter(.luminanceToAlpha)
                ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerSize: .zero), with: .color(white: 0))
                ctx.clip(to: Path(textMaskPath), options: .inverse)
                ctx.stroke(Path(majorTicksPath), with: .color(white: 1-majorTickAlpha), style: StrokeStyle(lineWidth: majorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
                ctx.clip(to: Path(minorTrackPath), style: FillStyle(eoFill: true))
                ctx.stroke(Path(minorTicksPath), with: .color(white: 1-minorTickAlpha), style: StrokeStyle(lineWidth: minorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            }
            
            var inactiveRingContext = gradientContext
            inactiveRingContext.clipToLayer(opacity: alpha) { cont in
                cont.fill(Path(CGRect(origin: .zero, size: size)), with: .color(white: 1))
            }
            let gradient = applyGradient(gradient: gradientColor, startingAngle: startingAngle)
            inactiveRingContext.fill(Path(outerRingPath), with: .conicGradient(gradient, center: CGPoint(x: size.width/2, y: size.height/2), angle: Angle(degrees: 90)))
            gradientContext.clip(to: Path(anglePath(angle: angle, startingAngle: startingAngle, in: outerRing)))
            gradientContext.fill(Path(outerRingPath), with: .conicGradient(gradient, center: CGPoint(x: size.width/2, y: size.height/2), angle: Angle(degrees: 90)))
            
            var transform = CGAffineTransform()
            var textContext = context
            for drawabeText in drawableTexts {
                if drawabeText.transform != transform {
                    textContext = context
                    textContext.concatenate(drawabeText.transform)
                }
                textContext.draw(Text(drawabeText.string).foregroundColor(Color(cgColor: drawabeText.color)), in: drawabeText.position)
                transform = drawabeText.transform
            }
            
            for mark in marks {
                let points: [RoundedRect.OrientedPoint]
                if mark.outer {
                    points = outerRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: mark.locations.filter { 0 <= $0 && 1 > $0} ))
                } else {
                    points = innerRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: mark.locations.filter { 0 <= $0 && 1 > $0} ))
                }
                var markContext = context
                markContext.addFilter(.shadow(color: Color(white: 0, opacity: 0.5), radius: mark.radius / 2, x: 0, y: 0))
                for i in 0..<points.count {
                    let point = points[i]
                    let color = mark.colors[i]
                    var transform = CGAffineTransform(translationX: -point.position.x, y: -point.position.y)
                    transform = transform.concatenating(CGAffineTransform(rotationAngle: -point.direction))
                    transform = transform.concatenating(CGAffineTransform(translationX: point.position.x, y: point.position.y))
                    let markPath: CGPath = RoundedRect(rect: CGRect(x: point.position.x - mark.radius, y: point.position.y - mark.radius, width: 2 * mark.radius, height: 2 * mark.radius), nodePos: 0.7 * mark.radius, ankorPos: 0.3 * mark.radius).path.copy(using: &transform)!
                    markContext.fill(Path(markPath), with: .color(Color(cgColor: color)))
                }
            }
            var shadowContext = graphicsContext
            shadowContext.clip(to: Path(outerRing.path), options: .inverse)
            shadowContext.drawLayer() { ctx in
                ctx.addFilter(.shadow(color: Color(white: 0, opacity: 0.5), radius: 0.03 * shortEdge,
                                                x: -0.014 * sin(CGFloat.pi * 2 * shadowDirection) * shortEdge,
                                                y: -0.014 * cos(CGFloat.pi * 2 * shadowDirection) * shortEdge, options: .shadowOnly))
                ctx.fill(Path(outerRing.path), with: .color(white: 1))
            }
        }
    }
}

struct Core: View {
    let viewSize: CGSize
    let compact: Bool
    let dateString: String
    let timeString: String
    let font: UIFont
    let textColor: WatchLayout.Gradient
    let outerBound: RoundedRect
    let backColor: CGColor
    let centerOffset: CGFloat
    let shadowDirection: CGFloat
    
    private func prepareText(text: String, offsetRatio: CGFloat) -> [DrawableText] {
        let centerTextShortSize = min(outerBound._boundBox.width, outerBound._boundBox.height) * 0.31
        let centerTextLongSize = max(outerBound._boundBox.width, outerBound._boundBox.height) * 0.17
        let centerTextSize = min(centerTextShortSize, centerTextLongSize) * (compact ? 1.1 : 1.0)
        let isVertical = viewSize.height >= viewSize.width
        let offset = centerTextSize * offsetRatio
        
        var drawableTexts = [DrawableText]()
        let centerFont = font.withSize(centerTextSize)
        
        let attrStr = NSMutableAttributedString(string: text)
        attrStr.addAttributes([.font: centerFont, .foregroundColor: CGColor(gray: 1, alpha: 1)], range: NSMakeRange(0, attrStr.length))

        let characters = attrStr.string.map{NSMutableAttributedString(string: String($0), attributes: attrStr.attributes(at: 0, effectiveRange: nil))}
        
        for i in 0..<characters.count {
            let mean = CGFloat(characters.count - 1) / 2
            let shift = (CGFloat(i) - mean) * centerTextSize * 0.95
            var box = characters[i].boundingRect(with: .zero, options: .usesLineFragmentOrigin, context: .none)
            if isVertical {
                box.origin = CGPoint(x: viewSize.width / 2 + offset - box.width/2, y: viewSize.height / 2 + shift - box.height/2)
            } else {
                box.origin = CGPoint(x: viewSize.width / 2 - shift - box.width/2, y: viewSize.height / 2 + offset - box.height/2)
            }
            drawableTexts.append(DrawableText(string: AttributedString(characters[i]), position: box, boundingBox: CGMutablePath(), transform: CGAffineTransform(), color: CGColor(gray: 1, alpha: 1)))
        }
        return drawableTexts
    }
    
    var body: some View {
        let shortEdge = min(self.viewSize.width, self.viewSize.height)
        
        Canvas { context, size in
            
            let outerBoundPath = outerBound.path
            context.fill(Path(outerBoundPath), with: .color(Color(cgColor: backColor)))
            
            let gradient = applyGradient(gradient: textColor, startingAngle: -1)
            
            var drawableTexts = prepareText(text: dateString, offsetRatio: 0.7 + centerOffset)
            drawableTexts += prepareText(text: timeString, offsetRatio: -0.7 + centerOffset)
            
            var startPoint = CGPoint(x: viewSize.width/2, y: viewSize.height/2)
            var endPoint = startPoint

            var textContext = context
            textContext.clipToLayer() { ctx in
                for text in drawableTexts {
                    let resolved = ctx.resolve(Text(text.string))
                    ctx.draw(resolved, at: CGPoint(x: text.position.midX, y: text.position.midY))
                    startPoint.x = min(startPoint.x, text.position.minX)
                    startPoint.y = max(startPoint.y, text.position.maxY)
                    endPoint.x = max(endPoint.x, text.position.maxX)
                    endPoint.y = min(endPoint.y, text.position.minY)
                }
            }
            
            textContext.fill(Path(outerBoundPath), with: .linearGradient(gradient, startPoint: startPoint, endPoint: endPoint))
            
            var shadowContext = context
            shadowContext.clip(to: Path(outerBoundPath), options: .inverse)
            shadowContext.drawLayer() { ctx in
                ctx.addFilter(.shadow(color: Color(white: 0, opacity: 0.5), radius: 0.03 * shortEdge,
                                                x: -0.014 * sin(CGFloat.pi * 2 * shadowDirection) * shortEdge,
                                                y: -0.014 * cos(CGFloat.pi * 2 * shadowDirection) * shortEdge, options: .shadowOnly))
                ctx.fill(Path(outerBoundPath), with: .color(white: 1))
            }
        }
    }
}

struct Marks {
    static let markSize: CGFloat = 0.012
    let outer: Bool
    let locations: [CGFloat]
    let colors: [CGColor]
    let radius: CGFloat
    
    static func pairMarkPositionColor(rawPositions: [Double?], rawColors: [CGColor]) -> ([CGFloat], [CGColor]) {
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
    
    init(outer: Bool, locations: [Double?], colors: [CGColor], radius: CGFloat) {
        self.outer = outer
        let (pos, col) = Marks.pairMarkPositionColor(rawPositions: locations, rawColors: colors)
        self.locations = pos
        self.colors = col
        self.radius = radius
    }
}

private struct DrawableText {
    let string: AttributedString
    let position: CGRect
    let boundingBox: CGPath
    let transform: CGAffineTransform
    let color: CGColor
}

private func prepareText(tickName: String, at point: RoundedRect.OrientedPoint, font: UIFont, compact: Bool, color: CGColor) -> [DrawableText] {
    
    let string: String
    var hasSpace = false
    let fontSize = font.pointSize
    if compact {
        hasSpace = tickName.firstIndex(of: "　") != nil
        string = String(tickName.replacingOccurrences(of: "　", with: ""))
    } else {
        string = tickName
    }
    let attrStr = NSMutableAttributedString(string: string)
    attrStr.addAttributes([.font: font,.foregroundColor: color], range: NSMakeRange(0, attrStr.length))

    var boxTransform = CGAffineTransform(translationX: -point.position.x, y: -point.position.y)
    let transform: CGAffineTransform
    if point.direction <= CGFloat.pi / 4 {
        transform = CGAffineTransform(rotationAngle: -point.direction)
    } else if point.direction < CGFloat.pi * 3/4 {
        transform = CGAffineTransform(rotationAngle: CGFloat.pi/2-point.direction)
    } else if point.direction < CGFloat.pi * 5/4 {
        transform = CGAffineTransform(rotationAngle: CGFloat.pi-point.direction)
    } else if point.direction < CGFloat.pi * 7/4 {
        transform = CGAffineTransform(rotationAngle: -point.direction-CGFloat.pi/2)
    } else {
        transform = CGAffineTransform(rotationAngle: -point.direction)
    }
    boxTransform = boxTransform.concatenating(transform)
    boxTransform = boxTransform.concatenating(CGAffineTransform(translationX: point.position.x, y: point.position.y))
    
    let characters = string.map{NSMutableAttributedString(string: String($0), attributes: attrStr.attributes(at: 0, effectiveRange: nil))}
    let mean = CGFloat(characters.count - 1) / 2

    var text = [DrawableText]()
    for i in 0..<characters.count {
        let shift = (CGFloat(i) - mean) * fontSize * (hasSpace ? 1.5 : 0.95)
        var box = characters[i].boundingRect(with: CGSizeZero, options: .usesLineFragmentOrigin, context: .none)
        box.origin = CGPoint(x: point.position.x - box.width/2, y: point.position.y - box.height/2)
        let cornerSize = 0.2 * min(box.height, box.width)
        if (point.direction > CGFloat.pi / 4 && point.direction < CGFloat.pi * 3/4) || (point.direction > CGFloat.pi * 5/4 && point.direction < CGFloat.pi * 7/4) {
            box.origin.y += shift
        } else {
            box.origin.x -= shift
        }
        let boxPath = CGPath(roundedRect: box, cornerWidth: cornerSize, cornerHeight: cornerSize, transform: &boxTransform)
        text.append(DrawableText(string: AttributedString(characters[i]), position: box, boundingBox: boxPath, transform: boxTransform, color: color))
    }
    return text
}

private func changePhase(phase: CGFloat, angles: [CGFloat]) -> [CGFloat] {
    return angles.map { angle in
        if phase >= 0 {
            return (angle + phase) % 1.0
        } else {
            return (-angle + phase) % 1.0
        }
    }
}

private func applyGradient(gradient: WatchLayout.Gradient, startingAngle: CGFloat) -> Gradient {

    let colors: [CGColor]
    let locations: [CGFloat]
    if startingAngle >= 0 {
        colors = gradient.colors.reversed()
        locations = gradient.locations.map { 1-$0 }.reversed()
    } else {
        colors = gradient.colors
        locations = gradient.locations
    }
    return Gradient(stops: zip(colors, locations).map { Gradient.Stop(color: Color(cgColor: $0.0), location: $0.1) })
}
