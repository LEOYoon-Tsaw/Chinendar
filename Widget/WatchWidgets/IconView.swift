//
//  IconViews.swift
//  WatchWidgetExtension
//
//  Created by Leo Liu on 5/12/23.
//

import SwiftUI

enum IconType {
    case solarTerm(view: SolarTerm)
    case moon(view: MoonPhase)
    case sunrise(view: Sun)
}

struct SolarTerm: View {
    var angle: CGFloat
    var color: CGColor
    
    func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(x: sin(angle) * radius + center.x, y: cos(angle) * radius + center.y)
    }
    
    var body: some View {
        Canvas { context, size in
            let minEdge = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let centerRadius = minEdge * 0.3
            let ringRadius = minEdge * 0.42
            let starRadius = minEdge * 0.08
            let smallStarRadius = minEdge * 0.06
            
            let connectionPath = CGMutablePath()
            connectionPath.move(to: pointOnCircle(center: center, radius: centerRadius, angle: 0.4 * CGFloat.pi))
            connectionPath.addLine(to: pointOnCircle(center: center, radius: centerRadius, angle: 0.6 * CGFloat.pi))
            connectionPath.addCurve(to: pointOnCircle(center: CGPoint(x: ringRadius, y: 0) + center, radius: starRadius, angle: 1.3 * CGFloat.pi),
                                    control1: CGPoint(x: centerRadius, y: 0) + center,
                                    control2: CGPoint(x: ringRadius - starRadius * 1.2, y: 0) + center)
            connectionPath.addLine(to: pointOnCircle(center: CGPoint(x: ringRadius, y: 0) + center, radius: starRadius, angle: 1.7 * CGFloat.pi))
            connectionPath.addCurve(to: pointOnCircle(center: center, radius: centerRadius, angle: 0.4 * CGFloat.pi),
                                    control1: CGPoint(x: ringRadius - starRadius * 1.2, y: 0) + center,
                                    control2: CGPoint(x: centerRadius, y: 0) + center)
            connectionPath.closeSubpath()
            
            let circlesPath = CGMutablePath()
            circlesPath.addEllipse(in: CGRect(origin: center - CGPoint(x: centerRadius, y: centerRadius), size: CGSize(width: centerRadius * 2, height: centerRadius * 2)))
            circlesPath.addEllipse(in: CGRect(origin: center - CGPoint(x: starRadius - ringRadius, y: starRadius), size: CGSize(width: starRadius * 2, height: starRadius * 2)))
            
            let dotsPath = CGMutablePath()
            for i in 1...11 {
                dotsPath.addEllipse(in: CGRect(origin: pointOnCircle(center: center, radius: ringRadius, angle: CGFloat(i) * CGFloat.pi * 2 / 12 + 0.5 * CGFloat.pi) - CGPoint(x: smallStarRadius, y: smallStarRadius), size: CGSize(width: smallStarRadius * 2, height: smallStarRadius * 2)))
            }

            context.fill(Path(connectionPath), with: .color(Color(cgColor: color)))
            context.fill(Path(circlesPath), with: .color(Color(cgColor: color)))
            context.fill(Path(dotsPath), with: .color(.yellow.opacity(0.5)))
        }
        .rotationEffect(.radians(-(angle - 0.25) * CGFloat.pi * 2.0))
    }
}

private func starPath(x: CGFloat, y: CGFloat, radius: CGFloat, sides: Int, pointyness: CGFloat) -> CGPath {
    func polygonPointArray(sides: Int, x: CGFloat, y: CGFloat, radius: CGFloat, adjustment: CGFloat = 0) -> [CGPoint] {
        let angle = 2 * CGFloat.pi / CGFloat(sides)
        let cx = x // x origin
        let cy = y // y origin
        let r = radius // radius of circle
        var i = sides
        var points = [CGPoint]()
        while points.count <= sides {
            let xpo = cx - r * cos(angle * CGFloat(i) + adjustment * 2 * CGFloat.pi)
            let ypo = cy - r * sin(angle * CGFloat(i) + adjustment * 2 * CGFloat.pi)
            points.append(CGPoint(x: xpo, y: ypo))
            i -= 1
        }
        return points
    }
    
    let adjustment = 0.5 / CGFloat(sides)
    let path = CGMutablePath()
    let points = polygonPointArray(sides: sides, x: x, y: y, radius: radius)
    let points2 = polygonPointArray(sides: sides, x: x, y: y, radius: radius * pointyness, adjustment: adjustment)
    path.move(to: points[0])
    for i in 0 ..< points.count {
        path.addLine(to: points2[i])
        path.addLine(to: points[i])
    }
    path.closeSubpath()
    return path
}

struct MoonPhase: View {
    var angle: CGFloat
    var color: CGColor
    var rise: Bool?
    
    func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(x: sin(angle) * radius + center.x, y: cos(angle) * radius + center.y)
    }
    
    var body: some View {
        Canvas { context, size in
            let minEdge = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let centerRadius = minEdge * 0.3
            let ringRadius = minEdge * 0.42
            let starRadius = minEdge * 0.1
            
            context.clip(to: Path(ellipseIn: CGRect(x: center.x - minEdge * 0.5, y: center.y - minEdge * 0.5, width: minEdge, height: minEdge)))
            var moonContext = context
            
            if rise != nil {
                let groundMaskPath = CGMutablePath()
                groundMaskPath.addArc(center: center, radius: minEdge * 0.5, startAngle: 0.2 * CGFloat.pi, endAngle: 0.80 * CGFloat.pi, clockwise: false)
                groundMaskPath.closeSubpath()
                
                let groundPath = CGMutablePath()
                groundPath.addArc(center: center, radius: minEdge * 0.5, startAngle: 0.23 * CGFloat.pi, endAngle: 0.77 * CGFloat.pi, clockwise: false)
                groundPath.closeSubpath()
                
                let groundContext = context
                groundContext.fill(Path(groundPath), with: .color(.brown))
                moonContext.clip(to: Path(groundMaskPath), options: .inverse)
                moonContext.translateBy(x: 0, y: minEdge * 0.10)
            }
            let backContext = moonContext

            let width = centerRadius * (1.0 + cos(4.0 * CGFloat.pi * angle)) / 2.0
            let ellipse = CGMutablePath(ellipseIn: CGRect(x: center.x - width, y: center.y - centerRadius, width: width * 2, height: centerRadius * 2), transform: nil)
            if cos(2.0 * CGFloat.pi * angle) >= 0 {
                moonContext.clip(to: Path(ellipse), options: .inverse)
            } else {
                moonContext.fill(Path(ellipse), with: .color(Color(cgColor: color)))
            }
            
            let halfMoon = CGMutablePath()
            if sin(2.0 * CGFloat.pi * angle) >= 0 {
                halfMoon.addArc(center: center, radius: centerRadius, startAngle: -0.5 * CGFloat.pi, endAngle: 0.5 * CGFloat.pi, clockwise: true)
            } else {
                halfMoon.addArc(center: center, radius: centerRadius, startAngle: 0.5 * CGFloat.pi, endAngle: -0.5 * CGFloat.pi, clockwise: true)
            }
            halfMoon.closeSubpath()
            moonContext.fill(Path(halfMoon), with: .color(Color(cgColor: color)))
            
            let circle = CGMutablePath(ellipseIn: CGRect(x: center.x - centerRadius, y: center.y - centerRadius, width: centerRadius * 2, height: centerRadius * 2), transform: nil)
            backContext.fill(Path(circle), with: .color(Color(cgColor: color).opacity(0.2 * color.alpha)))
            
            for position in [0.2, 0.4, 0.76] {
                let direction = pointOnCircle(center: center, radius: ringRadius, angle: (position + angle * 0.02) * CGFloat.pi * 2.0)
                let star = starPath(x: direction.x, y: direction.y, radius: starRadius * (0.75 + 0.25 * cos(angle * CGFloat.pi * 2.0)), sides: 5, pointyness: 0.5)
                moonContext.fill(Path(star), with: .color(.yellow.opacity(0.75 + 0.25 * cos(angle * CGFloat.pi * 2.0))))
            }
            
            if let rise = rise {
                var arrow = context
                arrow.clipToLayer { ctx in
                    var abc = ctx
                    abc.translateBy(x: center.x, y: center.y)
                    abc.rotate(by: .degrees(90))
                    abc.translateBy(x: -center.x, y: -center.y)
                    let arrowName = rise ? "arrowshape.left.fill" : "arrowshape.right.fill"
                    abc.draw(Image(systemName: arrowName), in: CGRect(x: minEdge * 0.0, y: center.y - minEdge * 0.12, width: minEdge * 0.24, height: minEdge * 0.24))
                }
                arrow.fill(Path(ellipseIn: CGRect(origin: .zero, size: CGSize(width: minEdge, height: minEdge))), with: .color(rise ? .orange : .teal))
            }
        }
    }
}

struct Sun: View {
    var color: CGColor
    var rise: Bool?
    
    func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(x: sin(angle) * radius + center.x, y: cos(angle) * radius + center.y)
    }
    
    var body: some View {
        Canvas { context, size in
            let minEdge = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let centerRadius = minEdge * 0.3
            let ringRadius = minEdge * 0.42
            let smallStarRadius = minEdge * 0.08
            
            context.clip(to: Path(ellipseIn: CGRect(x: center.x - minEdge * 0.5, y: center.y - minEdge * 0.5, width: minEdge, height: minEdge)))
            var sunContext = context
            
            if rise != nil {
                let groundMaskPath = CGMutablePath()
                groundMaskPath.addArc(center: center, radius: minEdge * 0.5, startAngle: 0.20 * CGFloat.pi, endAngle: 0.80 * CGFloat.pi, clockwise: false)
                groundMaskPath.closeSubpath()
                
                let groundPath = CGMutablePath()
                groundPath.addArc(center: center, radius: minEdge * 0.5, startAngle: 0.23 * CGFloat.pi, endAngle: 0.77 * CGFloat.pi, clockwise: false)
                groundPath.closeSubpath()
                
                let groundContext = context
                groundContext.fill(Path(groundPath), with: .color(.brown))
                sunContext.clip(to: Path(groundMaskPath), options: .inverse)
                sunContext.translateBy(x: 0, y: minEdge * 0.1)
            }
            
            let mainCircle = CGMutablePath(ellipseIn: CGRect(x: center.x - centerRadius, y: center.y - centerRadius, width: centerRadius * 2, height: centerRadius * 2), transform: nil)
            
            let radiationPath = CGMutablePath()
            for i in 0...11 {
                radiationPath.move(to: pointOnCircle(center: center, radius: ringRadius - smallStarRadius, angle: CGFloat(i) / 12.0 * CGFloat.pi * 2.0))
                radiationPath.addCurve(to: pointOnCircle(center: center, radius: ringRadius - smallStarRadius, angle: CGFloat(i) / 12.0 * CGFloat.pi * 2.0),
                                       control1: pointOnCircle(center: center, radius: ringRadius + smallStarRadius, angle: (CGFloat(i) + 0.5) / 12.0 * CGFloat.pi * 2.0),
                                       control2: pointOnCircle(center: center, radius: ringRadius + smallStarRadius, angle: (CGFloat(i) - 0.1) / 12.0 * CGFloat.pi * 2.0))
                radiationPath.closeSubpath()
            }

            sunContext.fill(Path(mainCircle), with: .color(Color(cgColor: color)))
            sunContext.fill(Path(radiationPath), with: .color(.yellow))
            
            if let rise = rise {
                var arrow = context
                arrow.clipToLayer { ctx in
                    var abc = ctx
                    abc.translateBy(x: center.x, y: center.y)
                    abc.rotate(by: .degrees(90))
                    abc.translateBy(x: -center.x, y: -center.y)
                    let arrowName = rise ? "arrowshape.left.fill" : "arrowshape.right.fill"
                    abc.draw(Image(systemName: arrowName), in: CGRect(x: minEdge * 0.0, y: center.y - minEdge * 0.12, width: minEdge * 0.24, height: minEdge * 0.24))
                }
                arrow.fill(Path(ellipseIn: CGRect(origin: .zero, size: CGSize(width: minEdge, height: minEdge))), with: .color(rise ? .orange : .teal))
            }
        }
    }
}

#Preview("SolarTerm") {
    SolarTerm(angle: 0.4, color: Color.white.cgColor!)
}

#Preview("MoonPhase") {
    MoonPhase(angle: 0.4, color: CGColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1))
}

#Preview("Moonrise") {
    MoonPhase(angle: 0.4, color: CGColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1), rise: true)
}

#Preview("Sunrise") {
    Sun(color: CGColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1), rise: true)
}
