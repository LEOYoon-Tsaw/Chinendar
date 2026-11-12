//
//  IconViews.swift
//  WatchWidgetExtension
//
//  Created by Leo Liu on 5/12/23.
//

import SwiftUI
import WidgetKit

enum IconType {
    case globalEvent(view: GlobalEventIcon)
    case localEvent(view: LocalEventIcon)
}

struct EventIconResource {
    private static func resourcePrefix(type: NextEventType) -> String {
        switch type {
        case .solarTerms: "ST"
        case .lunarPhases: "MF"
        case .chineseHoliday: "Fes"
        case .sunriseSet, .moonriseSet: "Ast"
        }
    }

    let name: String
    let category: NextEventType

    private var assetName: String {
        Self.resourcePrefix(type: category) + name.filter { !$0.isWhitespace }
    }

    var colorImage: Image {
        Image(assetName)
    }

    var grayImage: Image {
        Image("\(assetName)GS")
    }

    var backgroundColor: Color {
        switch category {
        case .solarTerms, .lunarPhases, .chineseHoliday:
            return Color("\(assetName)Background")
        case .sunriseSet, .moonriseSet:
            let name = switch self.name {
            case ChineseCalendar.dayTimeName.sunrise, ChineseCalendar.dayTimeName.sunset, ChineseCalendar.dayTimeName.polarDay, ChineseCalendar.dayTimeName.unknown:
                "AstDayBackground"
            default:
                "AstNightBackground"
            }
            return Color(name)
        }
    }
}

struct GlobalEventIcon: View {
    let name: String
    let category: NextEventType

    var body: some View {
        EventIcon { grayscale, side in
            let resource = EventIconResource(name: name, category: category)
            let image = grayscale ? resource.grayImage : resource.colorImage
            guard let side else { return image }

            let size = CGSize(width: side, height: side)
            return Image(size: size) { context in
                context.draw(image, in: CGRect(origin: .zero, size: size))
            }
        }
    }
}

struct LocalEventIcon: View {
    let name: String
    let color: Color
    let phase: CGFloat?

    init(name: String, color: Color, phase: CGFloat? = nil) {
        self.name = name
        self.color = color
        self.phase = phase
    }

    var body: some View {
        EventIcon(image: image(grayscale:side:))
    }
}

private extension LocalEventIcon {
    var resource: EventIconResource {
        let name = switch self.name {
        case ChineseCalendar.dayTimeName.sunrise, ChineseCalendar.moonTimeName.moonrise, ChineseCalendar.dayTimeName.unknown, ChineseCalendar.moonTimeName.unknown: "Valley"
        case ChineseCalendar.dayTimeName.sunset, ChineseCalendar.dayTimeName.polarDay: "Mounts"
        case ChineseCalendar.moonTimeName.moonset, ChineseCalendar.dayTimeName.polarNight, ChineseCalendar.moonTimeName.evermoon, ChineseCalendar.moonTimeName.moonless: "NightMounts"
        default: fatalError("Unrecognized event name: \(self.name)")
        }
        return EventIconResource(name: name, category: .sunriseSet)
    }

    func image(grayscale: Bool, side: CGFloat?) -> Image {
        let foreground = if grayscale {
            resource.grayImage
        } else {
            resource.colorImage
        }

        let designSide: CGFloat = 128
        let side = side ?? designSide
        let size = CGSize(width: side, height: side)
        let frame = CGRect(x: 0, y: 0, width: designSide, height: designSide)
        return Image(size: size, opaque: grayscale) { context in
            let scale = side / designSide
            context.scaleBy(x: scale, y: scale)
            context.draw(foreground, in: frame)

            var bodyContext = context
            bodyContext.clipToLayer(options: .inverse) { mask in
                mask.draw(resource.colorImage, in: frame)
            }
            drawBody(context: bodyContext, grayscale: grayscale)
            drawArrow(context: context, grayscale: grayscale)
        }
    }

    func drawBody(context: GraphicsContext, grayscale: Bool) {
        switch name {
        case ChineseCalendar.dayTimeName.sunrise, ChineseCalendar.dayTimeName.sunset:
            drawSun(context: context, center: CGPoint(x: 64, y: name == ChineseCalendar.dayTimeName.sunrise ? 70 : 90),
                    radius: 25, polar: false, grayscale: grayscale)
        case ChineseCalendar.moonTimeName.moonrise, ChineseCalendar.moonTimeName.moonset:
            drawMoon(context: context, center: CGPoint(x: 64, y: name == ChineseCalendar.moonTimeName.moonrise ? 70 : 90),
                     angle: phase ?? 0.5, grayscale: grayscale)
        case ChineseCalendar.dayTimeName.polarDay:
            drawSun(context: context, center: CGPoint(x: 64, y: 42), radius: 19, polar: true, grayscale: grayscale)
        case ChineseCalendar.moonTimeName.evermoon:
            drawMoon(context: context, center: CGPoint(x: 42, y: 20), angle: phase ?? 0.5, grayscale: grayscale)
        case ChineseCalendar.dayTimeName.polarNight, ChineseCalendar.moonTimeName.moonless:
            drawStars(context: context, grayscale: grayscale)
        case ChineseCalendar.dayTimeName.unknown, ChineseCalendar.moonTimeName.unknown:
            drawQuestionMark(context: context, grayscale: grayscale)
        default:
            break
        }
    }

    func drawArrow(context: GraphicsContext, grayscale: Bool) {
        let rising: Bool
        switch name {
        case ChineseCalendar.dayTimeName.sunrise, ChineseCalendar.moonTimeName.moonrise: rising = true
        case ChineseCalendar.dayTimeName.sunset, ChineseCalendar.moonTimeName.moonset: rising = false
        default: return
        }
        let symbolName = rising ? "arrowshape.left.fill" : "arrowshape.right.fill"
        var symbol = context.resolve(Image(systemName: symbolName))
        symbol.shading = .color(grayscale ? .white : color)
        var arrowContext = context
        arrowContext.translateBy(x: 64, y: rising ? 23 : 35)
        arrowContext.rotate(by: .degrees(90))
        arrowContext.draw(symbol, in: CGRect(x: -13, y: -13, width: 26, height: 26))
    }

    func drawSun(context: GraphicsContext, center: CGPoint, radius: CGFloat, polar: Bool, grayscale: Bool) {
        let rays = grayscale ? Color(white: 208.0 / 255) : Color(red: 213.0 / 255, green: 157.0 / 255, blue: 60.0 / 255)
        for index in 0..<12 {
            let angle = CGFloat(index) * .pi / 6
            var ray = Path()
            let startingPoint = CGPoint(x: center.x + (radius + 5) * cos(angle), y: center.y + (radius + 5) * sin(angle))
            ray.move(to: startingPoint)
            ray.addCurve(to: startingPoint,
                         control1: CGPoint(x: center.x + (radius + 12) * cos(angle + 0.5 / 6 * .pi), y: center.y + (radius + 12) * sin(angle + 0.5 / 6 * .pi)),
                         control2: CGPoint(x: center.x + (radius + 12) * cos(angle - 0.1 / 6 * .pi), y: center.y + (radius + 12) * sin(angle - 0.1 / 6 * .pi))
                         )
            ray.closeSubpath()
            context.fill(ray, with: .color(rays))
        }
        let sunlight = polar ? Color(red: 241.0 / 255, green: 155.0 / 255, blue: 62.0 / 255)
                             : Color(red: 223.0 / 255, green: 89.0 / 255, blue: 70.0 / 255)
        let circle = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.fill(circle, with: .color(grayscale ? .white : sunlight))
    }

    func drawStars(context: GraphicsContext, grayscale: Bool) {
        let starlight = grayscale ? Color.white : Color(red: 1, green: 240.0 / 255, blue: 214.0 / 255)
        var star = context.resolve(Image(systemName: "star.fill"))
        star.shading = .color(starlight)
        let positions: [(CGFloat, CGFloat, CGFloat)] = [(34, 31, 4), (91, 25, 4.5), (65, 52, 3.8)]
        for (x, y, radius) in positions {
            context.draw(star, in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
        for center in [CGPoint(x: 20, y: 55), CGPoint(x: 111, y: 49)] {
            context.fill(Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)), with: .color(starlight))
        }
    }

    func drawQuestionMark(context: GraphicsContext, grayscale: Bool) {
        var symbol = context.resolve(Image(systemName: "questionmark"))
        symbol.shading = .color(grayscale ? .white : Color(red: 1, green: 240.0 / 255, blue: 214.0 / 255))
        context.draw(symbol, in: CGRect(x: 48, y: 16, width: 35, height: 58))
    }

    func drawMoon(context: GraphicsContext, center: CGPoint, angle: CGFloat, grayscale: Bool) {
        let centerRadius: CGFloat = 25
        let light = grayscale ? Color.white : Color(red: 1, green: 207.0 / 255, blue: 98.0 / 255)
        let shadow = grayscale ? Color(white: 0.2) : Color(red: 0.06, green: 0.3, blue: 1, opacity: 0.25)
        let circle = Path(ellipseIn: CGRect(x: center.x - centerRadius, y: center.y - centerRadius,
                                          width: centerRadius * 2, height: centerRadius * 2))
        context.fill(circle, with: .color(shadow))
        var moonContext = context

        let width = centerRadius * (1.0 + cos(4.0 * CGFloat.pi * angle)) / 2.0
        let ellipse = CGMutablePath()
        ellipse.addEllipse(in: CGRect(x: center.x - width, y: center.y - centerRadius, width: width * 2, height: centerRadius * 2))
        if cos(2.0 * CGFloat.pi * angle) >= 0 {
            moonContext.clip(to: Path(ellipse), options: .inverse)
        } else {
            moonContext.fill(Path(ellipse), with: .color(light))
        }

        let halfMoon = CGMutablePath()
        if sin(2.0 * CGFloat.pi * angle) >= 0 {
            halfMoon.addArc(center: center, radius: centerRadius, startAngle: -0.5 * CGFloat.pi, endAngle: 0.5 * CGFloat.pi, clockwise: true)
        } else {
            halfMoon.addArc(center: center, radius: centerRadius, startAngle: 0.5 * CGFloat.pi, endAngle: -0.5 * CGFloat.pi, clockwise: true)
        }
        halfMoon.closeSubpath()
        moonContext.fill(Path(halfMoon), with: .color(light))
    }
}

private struct EventIcon: View {
    let image: (_ grayscale: Bool, _ side: CGFloat?) -> Image
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
#if os(watchOS)
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.displayScale) private var displayScale
#endif

    var body: some View {
#if os(watchOS)
        if widgetFamily == .accessoryCorner {
            GeometryReader { proxy in
                // WidgetKit limits the bitmap itself, so round down to a whole pixel.
                let side = min(proxy.size.width, proxy.size.height)
                let pixels = (side * displayScale).rounded(.down)
                if pixels.isFinite, pixels >= 1 {
                    content(side: pixels / displayScale)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        } else {
            content(side: nil)
        }
#else
        content(side: nil)
#endif
    }

    @ViewBuilder private func content(side: CGFloat?) -> some View {
        switch widgetRenderingMode {
        case .fullColor:
            image(false, side)
                .resizable()
                .scaledToFit()
                .aspectRatio(1, contentMode: .fit)
        case .accented:
            image(true, side)
                .resizable()
                .widgetAccentedRenderingMode(.accentedDesaturated)
                .scaledToFit()
                .aspectRatio(1, contentMode: .fit)
        default:
            Color.white
                .aspectRatio(1, contentMode: .fit)
                .mask {
                    image(true, side)
                        .resizable()
                        .scaledToFit()
                        .luminanceToAlpha()
                }
        }
    }
}
