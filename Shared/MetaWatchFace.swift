//
//  MetaWatchFace.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/27/23.
//

import CoreGraphics
import Foundation
import QuartzCore.CoreAnimation

let helpString: String = NSLocalizedString("介紹全文", comment: "Markdown formatted Wiki")

final class GraphicArtifects {
    static let width: CGFloat = 0.075
    static let paddedWidth: CGFloat = 0.075
    static let zeroRingWidth: CGFloat = 0.04
    static let markRadius: CGFloat = 0.012
    
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

final class KeyStates {
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
    let zeroRing: CGFloat
    let firstRing: CGFloat
    let secondRing: CGFloat
    let thirdRing: CGFloat
    let fourthRing: CGFloat
}

struct EntityNote {
    let name: String
    let position: CGPoint
    let color: CGColor
}

extension CALayer {
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval/12
    
    func update(dirtyRect: CGRect, isDark: Bool, watchLayout: WatchLayout, chineseCalendar: ChineseCalendar, graphicArtifects: GraphicArtifects, keyStates: KeyStates, phase: StartingPhase) -> [EntityNote] {
        func angleMask(angle: CGFloat, startingAngle: CGFloat, in circle: RoundedRect) -> CAShapeLayer {
            return shapeFrom(path: anglePath(angle: angle, startingAngle: startingAngle, in: circle))
        }
        
        func applyGradient(to path: CGPath, gradient: WatchLayout.Gradient, alpha: CGFloat = 1.0, angle: CGFloat? = nil, startingAngle: CGFloat, outerRing: RoundedRect? = nil) -> CAGradientLayer {
            let gradientLayer = CAGradientLayer()
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint = gradientLayer.startPoint + CGPoint(x: sin(startingAngle * CGFloat.pi * 2), y: cos(startingAngle * CGFloat.pi * 2))
            gradientLayer.type = .conic
            if startingAngle >= 0 {
                gradientLayer.colors = gradient.colors.reversed()
                gradientLayer.locations = gradient.locations.map { NSNumber(value: Double(1 - $0)) }.reversed()
            } else {
                gradientLayer.colors = gradient.colors
                gradientLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
            }
            gradientLayer.frame = self.bounds
            
            let trackMask = shapeFrom(path: path)
            let mask: CALayer
            if let angle = angle, let outerRing = outerRing {
                let angleMask = angleMask(angle: angle, startingAngle: startingAngle, in: outerRing)
                angleMask.fillColor = CGColor(gray: 1.0, alpha: alpha)
                angleMask.mask = trackMask
                mask = CALayer()
                mask.addSublayer(angleMask)
            } else {
                trackMask.fillColor = CGColor(gray: 1.0, alpha: alpha)
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
        
        func drawMark(at locations: [ChineseCalendar.NamedPosition], on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, colors: [CGColor], radius: CGFloat, positions: inout [EntityNote]) -> CALayer {
            let marks = CALayer()
            let validLocations = locations.filter { $0.pos >= 0 && $0.pos < 1 }
            let points = ring.arcPoints(lambdas: changePhase(phase: startingAngle, angles: validLocations.map { CGFloat($0.pos) }))
            for i in 0..<validLocations.count {
                let point = points[i]
                let pos = point.position
                let angle = point.direction
                var transform = CGAffineTransform(translationX: -pos.x, y: -pos.y)
                transform = transform.concatenating(CGAffineTransform(rotationAngle: -angle))
                transform = transform.concatenating(CGAffineTransform(translationX: pos.x, y: pos.y))
                let markPath: CGPath = RoundedRect(rect: CGRect(x: pos.x - radius, y: pos.y - radius, width: 2 * radius, height: 2 * radius), nodePos: 0.7 * radius, ankorPos: 0.3 * radius).path
                let mark = shapeFrom(path: markPath)
                mark.setAffineTransform(transform)
                mark.fillColor = colors[i % colors.count]
                mark.shadowPath = mark.path
                mark.shadowOffset = CGSizeZero
                mark.shadowRadius = radius/2
                mark.shadowOpacity = Float(0.3 * mark.fillColor!.alpha)
                positions.append(EntityNote(name: validLocations[i].name, position: pos, color: mark.fillColor!))
                marks.addSublayer(mark)
            }
            let mask = shapeFrom(path: maskPath)
            marks.mask = mask
            return marks
        }
        
        func addMarks(position: ChineseCalendar.CelestialEvent, on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, radius: CGFloat, positions: inout [EntityNote]) -> CALayer {
            let marks = CALayer()
            marks.addSublayer(drawMark(at: position.eclipse, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.eclipseIndicator], radius: radius, positions: &positions))
            marks.addSublayer(drawMark(at: position.fullMoon, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.fullmoonIndicator], radius: radius, positions: &positions))
            marks.addSublayer(drawMark(at: position.oddSolarTerm, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.oddStermIndicator], radius: radius, positions: &positions))
            marks.addSublayer(drawMark(at: position.evenSolarTerm, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: [watchLayout.evenStermIndicator], radius: radius, positions: &positions))
            return marks
        }
        
        func addIntradayMarks(locations: ChineseCalendar.DailyEvent, on ring: RoundedRect, startingAngle: CGFloat, maskPath: CGPath, radius: CGFloat, positions: inout [EntityNote]) -> CALayer {
            let (sunPositionsInDay, sunPositionsInDayColors) = pairMarkPositionColor(rawPositions: locations.solar, rawColors: watchLayout.sunPositionIndicator)
            let (moonPositionsInDay, moonPositionsInDayColors) = pairMarkPositionColor(rawPositions: locations.lunar, rawColors: watchLayout.moonPositionIndicator)
            let marks = CALayer()
            marks.addSublayer(drawMark(at: sunPositionsInDay, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: sunPositionsInDayColors, radius: radius, positions: &positions))
            marks.addSublayer(drawMark(at: moonPositionsInDay, on: ring, startingAngle: startingAngle, maskPath: maskPath, colors: moonPositionsInDayColors, radius: radius, positions: &positions))
            return marks
        }
        
        func drawText(str: String, at: CGPoint, angle: CGFloat, color: CGColor, size: CGFloat) -> (CALayer, CGPath) {
            let font = watchLayout.textFont.withSize(size)
            let textLayer = CATextLayer()
            var attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttributes([.font: font, .foregroundColor: color], range: NSMakeRange(0, str.utf16.count))
            var box = attrStr.boundingRect(with: CGSizeZero, options: .usesLineFragmentOrigin, context: .none)
            box.origin = CGPoint(x: at.x - box.width/2, y: at.y - box.height/2)
            if (angle > CGFloat.pi/4 && angle < CGFloat.pi * 3/4) || (angle > CGFloat.pi * 5/4 && angle < CGFloat.pi * 7/4) {
                let shift = pow(size, 0.9) * watchLayout.verticalTextOffset
                textLayer.frame = CGRect(x: at.x - box.width/2 - shift, y: at.y - box.height * 1.8/2, width: box.width, height: box.height * 1.8)
                attrStr.addAttributes([.verticalGlyphForm: 1], range: NSMakeRange(0, str.utf16.count))
            } else {
                let shift = pow(size, 0.9) * watchLayout.horizontalTextOffset
                textLayer.frame = CGRect(x: at.x - box.width/2, y: at.y - box.height/2 + shift, width: box.width, height: box.height)
                attrStr = NSMutableAttributedString(string: String(str.reversed()), attributes: attrStr.attributes(at: 0, effectiveRange: nil))
            }
            textLayer.string = attrStr
            textLayer.contentsScale = 3
            textLayer.alignmentMode = .center
            var boxTransform = CGAffineTransform(translationX: -at.x, y: -at.y)
            let transform: CGAffineTransform
            if angle <= CGFloat.pi/4 {
                transform = CGAffineTransform(rotationAngle: -angle)
            } else if angle < CGFloat.pi * 3/4 {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi - angle)
            } else if angle < CGFloat.pi * 5/4 {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi - angle)
            } else if angle < CGFloat.pi * 7/4 {
                transform = CGAffineTransform(rotationAngle: -angle)
            } else {
                transform = CGAffineTransform(rotationAngle: -angle)
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
            let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            let font = watchLayout.centerFont.withSize(size)
            let textLayer = CATextLayer()
            var attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttributes([.font: font, .foregroundColor: CGColor(gray: 1, alpha: 1)], range: NSMakeRange(0, str.utf16.count))
            let box = attrStr.boundingRect(with: CGSizeZero, options: .usesLineFragmentOrigin, context: .none)
            if rotate {
                textLayer.frame = CGRect(x: center.x - box.width/2 - offset, y: center.y - box.height * 2.3/2, width: box.width, height: box.height * 2.3)
                textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.pi/2))
                attrStr.addAttributes([.verticalGlyphForm: 1], range: NSMakeRange(0, str.utf16.count))
            } else {
                textLayer.frame = CGRect(x: center.x - box.width/2, y: center.y - box.height/2 + offset, width: box.width, height: box.height)
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
            
            let ringMinorTicksPath = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.minorTicks.map { CGFloat($0) }), width: 0.1 * shortEdge)
            let ringMinorTicks = CAShapeLayer()
            ringMinorTicks.path = ringMinorTicksPath
            
            let ringMinorTrackOuter = roundedRect.shrink(by: 0.01 * shortEdge)
            let ringMinorTrackInner = roundedRect.shrink(by: (GraphicArtifects.paddedWidth - 0.015) * shortEdge)
            let ringMinorTrackPath = ringMinorTrackOuter.path
            ringMinorTrackPath.addPath(ringMinorTrackInner.path)

            ringMinorTicks.strokeColor = isDark ? watchLayout.minorTickColorDark : watchLayout.minorTickColor
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
            ringBase.fillColor = CGColor(gray: 1.0, alpha: watchLayout.minorTickAlpha)
            ringMinorTicksMask.addSublayer(ringCrust)
            ringMinorTicksMask.addSublayer(ringBase)
            
            let ringMajorTicksPath = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTicks.map { CGFloat($0) }), width: 0.15 * shortEdge)
            let ringMajorTicks = CAShapeLayer()
            ringMajorTicks.path = ringMajorTicksPath
            
            ringMajorTicks.strokeColor = isDark ? watchLayout.majorTickColorDark : watchLayout.majorTickColor
            ringMajorTicks.lineWidth = majorLineWidth
        
            ringLayer.mask = ringMinorTicksMask
            
            let ringLayerAfterMinor = CALayer()
            ringLayerAfterMinor.addSublayer(ringLayer)
            
            let ringMajorTicksMaskPath = CGMutablePath()
            ringMajorTicksMaskPath.addPath(ringPath)
            ringMajorTicksMaskPath.addPath(ringMajorTicksPath.copy(strokingWithWidth: majorLineWidth, lineCap: .square, lineJoin: .bevel, miterLimit: .leastNonzeroMagnitude))
            let ringMajorTicksMask = shapeFrom(path: ringMajorTicksMaskPath)
            let ringBase2 = shapeFrom(path: ringPath)
            ringBase2.fillColor = CGColor(gray: 1.0, alpha: watchLayout.majorTickAlpha)
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
            
            let textRing = roundedRect.shrink(by: (GraphicArtifects.paddedWidth - 0.005)/2 * shortEdge)
            let textPoints = textRing.arcPoints(lambdas: changePhase(phase: startingAngle, angles: ticks.majorTickNames.map { CGFloat($0.position) }))
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
                shadowLayer.shadowOffset = CGSize(width: -0.014 * sin(CGFloat.pi * 2 * shadowDirection) * shortEdge, height: -0.014 * cos(CGFloat.pi * 2 * shadowDirection) * shortEdge)
                shadowLayer.shadowRadius = 0.03 * shortEdge
                shadowLayer.shadowOpacity = isDark ? 0.5 : 0.3
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
                   let textLayer = sublayers[sublayers.count - 1].sublayers?[i] as? CALayer
                {
                    textLayer.opacity = ticks.majorTickNames[i].active ? 1.0 : Float(watchLayout.shadeAlpha)
                }
            }
        }
        
        func drawOuterRing(path: CGPath, roundedRect: RoundedRect, textRoundedRect: RoundedRect, tickPositions: [CGFloat], texts: [String], startingAngle: CGFloat, fontSize: CGFloat, lineWidth: CGFloat, color: CGColor) -> CALayer {
            let ringPath = roundedRect.path
            ringPath.addPath(path)
            
            let ringShape = shapeFrom(path: ringPath)
            let ringTicks = roundedRect.arcPosition(lambdas: changePhase(phase: startingAngle, angles: tickPositions), width: 0.1 * shortEdge)
            let ringTicksShape = shapeFrom(path: ringTicks)
            ringTicksShape.mask = ringShape
            ringTicksShape.strokeColor = color
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
                watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.startHour)/lengthOfDay) % 1.0),
                watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.endHour)/lengthOfDay) % 1.0)
            ], loop: false)
            return fourthRingColor
        }
        
        func pairMarkPositionColor(rawPositions: [ChineseCalendar.NamedPosition?], rawColors: [CGColor]) -> ([ChineseCalendar.NamedPosition], [CGColor]) {
            var newPositions = [ChineseCalendar.NamedPosition]()
            var newColors = [CGColor]()
            for i in 0..<rawPositions.count {
                if let pos = rawPositions[i] {
                    newPositions.append(pos)
                    newColors.append(rawColors[i % rawColors.count])
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
            let centerOffset = isVertical ? watchLayout.centerTextOffset : 0
            let dateTextLayer = drawCenterText(str: timeString, offset: centerTextSize * (0.7 + centerOffset), size: centerTextSize, rotate: isVertical)
            centerText.addSublayer(dateTextLayer)
            let timeTextLayer = drawCenterText(str: dateString, offset: centerTextSize * (-0.7 + centerOffset), size: centerTextSize, rotate: isVertical)
            centerText.addSublayer(timeTextLayer)
            
            let gradientLayer = CAGradientLayer()
            gradientLayer.startPoint = CGPoint(x: -0.3, y: 0.3)
            gradientLayer.endPoint = CGPoint(x: 0.3, y: -0.3)
            gradientLayer.type = .axial
            gradientLayer.colors = watchLayout.centerFontColor.colors
            gradientLayer.locations = watchLayout.centerFontColor.locations.map { NSNumber(value: Double($0)) }
            gradientLayer.frame = self.bounds
            gradientLayer.mask = centerText
            
            return gradientLayer as CALayer
        }
        
        func getVagueShapes(shortEdge: CGFloat, longEdge: CGFloat) {
            let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
            // Basic paths
            graphicArtifects.outerBound = RoundedRect(rect: dirtyRect, nodePos: cornerSize, ankorPos: cornerSize * 0.2).shrink(by: 0.02 * shortEdge)
            graphicArtifects.solarTermsRing = graphicArtifects.outerBound!.shrink(by: (GraphicArtifects.zeroRingWidth + 0.003)/2 * shortEdge)
            
            graphicArtifects.firstRingOuter = graphicArtifects.outerBound!.shrink(by: GraphicArtifects.zeroRingWidth * shortEdge)
            graphicArtifects.firstRingInner = graphicArtifects.firstRingOuter!.shrink(by: GraphicArtifects.width * shortEdge)
            
            graphicArtifects.secondRingOuter = graphicArtifects.firstRingOuter!.shrink(by: GraphicArtifects.paddedWidth * shortEdge)
            graphicArtifects.secondRingInner = graphicArtifects.secondRingOuter!.shrink(by: GraphicArtifects.width * shortEdge)
            
            graphicArtifects.thirdRingOuter = graphicArtifects.secondRingOuter!.shrink(by: GraphicArtifects.paddedWidth * shortEdge)
            graphicArtifects.thirdRingInner = graphicArtifects.thirdRingOuter!.shrink(by: GraphicArtifects.width * shortEdge)
            
            graphicArtifects.fourthRingOuter = graphicArtifects.thirdRingOuter!.shrink(by: GraphicArtifects.paddedWidth * shortEdge)
            graphicArtifects.fourthRingInner = graphicArtifects.fourthRingOuter!.shrink(by: GraphicArtifects.width * shortEdge)
            
            graphicArtifects.innerBound = graphicArtifects.fourthRingOuter!.shrink(by: GraphicArtifects.paddedWidth * shortEdge)
            
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
        
        let shortEdge = min(dirtyRect.width, dirtyRect.height)
        let longEdge = max(dirtyRect.width, dirtyRect.height)
        let fontSize: CGFloat = min(shortEdge * 0.03, longEdge * 0.025)
        let minorLineWidth = shortEdge/500
        let majorLineWidth = shortEdge/300
        let shadowDirection = chineseCalendar.currentHourInDay
        
        if graphicArtifects.outerBound == nil {
            getVagueShapes(shortEdge: shortEdge, longEdge: longEdge)
        }
        
        var markPositions = [EntityNote]()
        
        // Zero ring
        if (graphicArtifects.outerOddLayer == nil) || (chineseCalendar.year != keyStates.year) {
            let oddSolarTermTickColor = isDark ? watchLayout.oddSolarTermTickColorDark : watchLayout.oddSolarTermTickColor
            let evenSolarTermTickColor = isDark ? watchLayout.evenSolarTermTickColorDark : watchLayout.evenSolarTermTickColor
            
            graphicArtifects.outerOddLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.outerBound!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: chineseCalendar.oddSolarTerms.map { CGFloat($0) }, texts: ChineseCalendar.oddSolarTermChinese, startingAngle: phase.zeroRing, fontSize: fontSize, lineWidth: majorLineWidth, color: oddSolarTermTickColor)
            graphicArtifects.outerEvenLayer = drawOuterRing(path: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.outerBound!, textRoundedRect: graphicArtifects.solarTermsRing!, tickPositions: chineseCalendar.evenSolarTerms.map { CGFloat($0) }, texts: ChineseCalendar.evenSolarTermChinese, startingAngle: phase.zeroRing, fontSize: fontSize, lineWidth: majorLineWidth, color: evenSolarTermTickColor)
        }
        self.addSublayer(graphicArtifects.outerOddLayer!)
        self.addSublayer(graphicArtifects.outerEvenLayer!)

        // First Ring
        if (graphicArtifects.firstRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.yearUpdatedTime)) >= Self.majorUpdateInterval) || (chineseCalendar.preciseMonth != keyStates.month) {
            let monthTicks = chineseCalendar.monthTicks
            if (graphicArtifects.firstRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) {
                graphicArtifects.firstRingLayer = drawRing(ringPath: graphicArtifects.firstRingOuterPath!, roundedRect: graphicArtifects.firstRingOuter!, gradient: watchLayout.firstRing, ticks: monthTicks, startingAngle: phase.firstRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
                keyStates.year = chineseCalendar.year
            }
            activeRingAngle(to: graphicArtifects.firstRingLayer!, ringPath: graphicArtifects.firstRingOuterPath!, gradient: watchLayout.firstRing, angle: chineseCalendar.currentDayInYear, startingAngle: phase.firstRing, outerRing: graphicArtifects.firstRingOuter!, ticks: monthTicks)
            keyStates.yearUpdatedTime = chineseCalendar.time
        }
        graphicArtifects.firstRingMarks = drawMark(at: chineseCalendar.planetPosition, on: graphicArtifects.firstRingOuter!, startingAngle: phase.firstRing, maskPath: graphicArtifects.firstRingOuterPath!, colors: watchLayout.planetIndicator, radius: GraphicArtifects.markRadius * shortEdge, positions: &markPositions)
        self.addSublayer(graphicArtifects.firstRingLayer!)
        self.addSublayer(graphicArtifects.firstRingMarks!)
        
        // Second Ring
        if (graphicArtifects.secondRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.preciseMonth != keyStates.month) || (ChineseCalendar.globalMonth != keyStates.globalMonth) || (chineseCalendar.timezone != keyStates.timezone) || (abs(chineseCalendar.time.distance(to: keyStates.monthUpdatedTime)) >= Self.minorUpdateInterval) || (chineseCalendar.day != keyStates.day) {
            let dayTicks = chineseCalendar.dayTicks
            if (graphicArtifects.secondRingLayer == nil) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.preciseMonth != keyStates.month) || (chineseCalendar.timezone != keyStates.timezone) || (ChineseCalendar.globalMonth != keyStates.globalMonth) {
                graphicArtifects.secondRingLayer = drawRing(ringPath: graphicArtifects.secondRingOuterPath!, roundedRect: graphicArtifects.secondRingOuter!, gradient: watchLayout.secondRing, ticks: dayTicks, startingAngle: phase.secondRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
                keyStates.month = chineseCalendar.preciseMonth
                keyStates.globalMonth = ChineseCalendar.globalMonth
            }
            activeRingAngle(to: graphicArtifects.secondRingLayer!, ringPath: graphicArtifects.secondRingOuterPath!, gradient: watchLayout.secondRing, angle: chineseCalendar.currentDayInMonth, startingAngle: phase.secondRing, outerRing: graphicArtifects.secondRingOuter!, ticks: dayTicks)
            keyStates.monthUpdatedTime = chineseCalendar.time
        }
        graphicArtifects.secondRingMarks = addMarks(position: chineseCalendar.eventInMonth, on: graphicArtifects.secondRingOuter!, startingAngle: phase.secondRing, maskPath: graphicArtifects.secondRingOuterPath!, radius: GraphicArtifects.markRadius * shortEdge, positions: &markPositions)
        self.addSublayer(graphicArtifects.secondRingLayer!)
        self.addSublayer(graphicArtifects.secondRingMarks!)
        
        // Third Ring
        let hourTicks = chineseCalendar.hourTicks
        if (graphicArtifects.thirdRingLayer == nil) || (chineseCalendar.dateString != keyStates.dateString) || (chineseCalendar.year != keyStates.year) || (chineseCalendar.timezone != keyStates.timezone) {
            graphicArtifects.thirdRingLayer = drawRing(ringPath: graphicArtifects.thirdRingOuterPath!, roundedRect: graphicArtifects.thirdRingOuter!, gradient: watchLayout.thirdRing, ticks: hourTicks, startingAngle: phase.thirdRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
            keyStates.day = chineseCalendar.day
            keyStates.dateString = chineseCalendar.dateString
        }
        graphicArtifects.thirdRingMarks = addMarks(position: chineseCalendar.eventInDay, on: graphicArtifects.thirdRingOuter!, startingAngle: phase.thirdRing, maskPath: graphicArtifects.thirdRingOuterPath!, radius: GraphicArtifects.markRadius * shortEdge, positions: &markPositions)
        graphicArtifects.thirdRingMarks?.addSublayer(addIntradayMarks(locations: chineseCalendar.sunMoonPositions, on: graphicArtifects.thirdRingInner!, startingAngle: phase.thirdRing, maskPath: graphicArtifects.thirdRingOuterPath!, radius: GraphicArtifects.markRadius * shortEdge, positions: &markPositions))
        activeRingAngle(to: graphicArtifects.thirdRingLayer!, ringPath: graphicArtifects.thirdRingOuterPath!, gradient: watchLayout.thirdRing, angle: chineseCalendar.currentHourInDay, startingAngle: phase.thirdRing, outerRing: graphicArtifects.thirdRingOuter!, ticks: hourTicks)
        self.addSublayer(graphicArtifects.thirdRingLayer!)
        self.addSublayer(graphicArtifects.thirdRingMarks!)
        
        // Fourth Ring
        let fourthRingColor = calSubhourGradient()
        let subhourTicks = chineseCalendar.subhourTicks
        if (graphicArtifects.fourthRingLayer == nil) || (chineseCalendar.startHour != keyStates.priorHour) || (chineseCalendar.timezone != keyStates.timezone) {
            if (graphicArtifects.fourthRingLayer == nil) || (chineseCalendar.startHour != keyStates.priorHour) {
                graphicArtifects.fourthRingLayer = drawRing(ringPath: graphicArtifects.fourthRingOuterPath!, roundedRect: graphicArtifects.fourthRingOuter!, gradient: fourthRingColor, ticks: subhourTicks, startingAngle: phase.fourthRing, fontSize: fontSize, minorLineWidth: minorLineWidth, majorLineWidth: majorLineWidth, drawShadow: true)
                keyStates.priorHour = chineseCalendar.startHour
            }
            keyStates.timezone = chineseCalendar.timezone
        }
        graphicArtifects.fourthRingMarks = addMarks(position: chineseCalendar.eventInHour, on: graphicArtifects.fourthRingOuter!, startingAngle: phase.fourthRing, maskPath: graphicArtifects.fourthRingOuterPath!, radius: GraphicArtifects.markRadius * shortEdge, positions: &markPositions)
        graphicArtifects.fourthRingMarks?.addSublayer(addIntradayMarks(locations: chineseCalendar.sunMoonSubhourPositions, on: graphicArtifects.fourthRingInner!, startingAngle: phase.fourthRing, maskPath: graphicArtifects.fourthRingOuterPath!, radius: GraphicArtifects.markRadius * shortEdge, positions: &markPositions))
        activeRingAngle(to: graphicArtifects.fourthRingLayer!, ringPath: graphicArtifects.fourthRingOuterPath!, gradient: fourthRingColor, angle: chineseCalendar.subhourInHour, startingAngle: phase.fourthRing, outerRing: graphicArtifects.fourthRingOuter!, ticks: subhourTicks)
        self.addSublayer(graphicArtifects.fourthRingLayer!)
        self.addSublayer(graphicArtifects.fourthRingMarks!)
        
        // Inner Ring
        if graphicArtifects.innerBox == nil {
            graphicArtifects.innerBox = shapeFrom(path: graphicArtifects.innerBoundPath!)
            graphicArtifects.innerBox!.fillColor = isDark ? watchLayout.innerColorDark : watchLayout.innerColor
            let shadowLayer = CALayer()
            shadowLayer.shadowPath = graphicArtifects.innerBoundPath!
            shadowLayer.shadowOffset = CGSize(width: -0.014 * sin(CGFloat.pi * 2 * shadowDirection) * shortEdge, height: -0.014 * cos(CGFloat.pi * 2 * shadowDirection) * shortEdge)
            shadowLayer.shadowRadius = 0.03 * shortEdge
            shadowLayer.shadowOpacity = isDark ? 0.5 : 0.3
            let shadowMaskPath = CGMutablePath()
            shadowMaskPath.addPath(graphicArtifects.innerBoundPath!)
            shadowMaskPath.addPath(CGPath(rect: self.bounds, transform: nil))
            let shadowMask = shapeFrom(path: shadowMaskPath)
            shadowLayer.mask = shadowMask
            graphicArtifects.innerBox?.addSublayer(shadowLayer)
        }
        self.addSublayer(graphicArtifects.innerBox!)
        
        // Center text
        let timeString = chineseCalendar.timeString
        let dateString = chineseCalendar.dateString
        if (graphicArtifects.centerText == nil) || (dateString != keyStates.dateString) || (timeString != keyStates.timeString) {
            graphicArtifects.centerText = drawCenterTextGradient(innerBound: graphicArtifects.innerBound!, dateString: dateString, timeString: timeString)
            keyStates.timeString = timeString
        }
        self.addSublayer(graphicArtifects.centerText!)
        return markPositions
    }
}
